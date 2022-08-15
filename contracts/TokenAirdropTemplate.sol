// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./libraries/transferHelper.sol";
import "./interfaces/IAirdrop.sol";
import "./interfaces/IBEP20.sol";
import "./ArcPartner.sol";
import "./ArcGuarder.sol";
import "./ArcInit.sol";

contract TokenAirdropTemplate is IAirdrop, ArcGuarder, ArcPartner, ArcInit {
    // extending uint256 by SafeMath
    using SafeMath for uint256;

    // activity => Activity
    mapping(uint256 => Activity) public activities;

    // activityId => ( userAddress => Reward )
    mapping(uint256 => mapping(address => Reward)) public rewards;

    // index of activity
    uint256 private _index;

    // total rewards received by users
    uint256 public totalRewardeds;

    /**
     * @dev Initialize
     * @param partner address of partner, like owner
     */
    function init(address partner) public isInit {
        _setPartner(partner);
    }

    /**
     * @dev Add a row of rules for airdrop
     * @param asset token address or nft contract address
     */
    function addActivity(address asset)
        public
        onlyPartner
        returns (uint256 activityId)
    {
        _index = _index + 1;
        require(asset != address(0), "ARC:ADDR0");

        activities[_index] = Activity(asset, 0, 0, false);
        activityId = _index;

        emit AddActivity(activityId);
    }

    /**
     * @dev public function for adding a user's reward rule. Cumulative reward!
     * @param id activity Id
     * @param user user address
     * @param targetId If it is NFT, it is the targetid value of NFT. it can be 0.
     * @param amounts reward amounts set this time
     */
    function addUserRewards(
        uint256 id,
        address user,
        uint256 targetId,
        uint256 amounts
    ) public onlyPartner {
        _addUserRewards(id, user, targetId, amounts);
    }

    /**
     * @dev do the same thing as 'addUserRewards' function. but it is a batch operation.
     */
    function addUsersRewards(
        uint256 id,
        address[] memory users,
        uint256[] memory targetIds,
        uint256[] memory amounts
    ) public onlyPartner {
        require(
            users.length > 0 &&
                targetIds.length == users.length &&
                amounts.length == users.length,
            "ARC:ERR_PARAMS"
        );

        for (uint256 i = 0; i < users.length; i++) {
           _addUserRewards(id, users[i], targetIds[i], amounts[i]);
        }
    }

    /**
     * @dev public function to reduce user reward amount.
     * @param id activity id
     * @param user user address
     * @param amounts reduce amount
     */
    function removeUserRewards(
        uint256 id,
        address user,
        uint256 amounts
    ) public onlyPartner {
        _removeUserRewards(id, user, amounts);
    }

    /**
     * @dev do the same thing as 'removeUserRewards' function. but it is a batch operation.
     */
    function removeusersRewards(
        uint256 id,
        address[] memory users,
        uint256[] memory amounts
    ) public onlyPartner {
        require(users.length > 0 && amounts.length == users.length, "ARC:ERR_PARAMS");

        for (uint256 i = 0; i < users.length; i++) {
            _removeUserRewards(id, users[i], amounts[i]);
        }
    }

    /**
     * @dev withdraw the remaining amount. only withdraw the excess amount!
     * @param id activity id
     */
    function withdrawRemain(uint256 id)
        public
        onlyPartner
        returns (uint256 remains)
    {
        require(id > 0 && id <= _index, "ARC:ERRID");
        require(activities[id].target != address(0), "ARC:ZERO_TARGET");
        address _target = activities[id].target;
        remains =
            IBEP20(_target).balanceOf(this) -
            activities[id].totalAmounts -
            totalRewardeds;

        require(remains > 0, "ARC:NO_REMAIN");

        _target.transfer(recipient, amount);
        TransferHelper.safeTransfer(_target, msg.sender, remains);

        emit WithdrawRemain(id, _target, remains);
    }

    function openActivity(uint256 id) public onlyPartner {
        require(id > 0 && id <= _index, "ARC:ERRID");
        activities[id].status = true;
    }

    function closeActivity(uint256 id) public onlyPartner {
        require(id > 0 && id <= _index, "ARC:ERRID");
        activities[id].status = false;
    }
    
     /**
     * @dev private function for adding user's reward rule. Cumulative reward!
     * @param id activity Id
     * @param user user address
     * @param targetId If it is NFT, it is the targetid value of NFT. it can be 0.
     * @param amounts reward amounts set this time
     */
    function _addUserRewards(
        uint256 id,
        address user,
        uint256 targetId,
        uint256 amounts
    ) private {
        require(
            id > 0 && id <= _index && user != address(0) && amounts > 0,
            "ARC:ERR_PARAMS"
        );

        Activity storage _activity = activities[id];
        Reward storage _reward = rewards[id][user];

        // set only the first time
        if (_reward.amounts == 0) {
            _reward.targetId = targetId;
            _activity.totalUsers = _activity.totalUsers + 1;
        } else {
            require(_reward.targetId == targetId, "ARC:ERR_TID");
        }

        _reward.amounts = _reward.amounts + amounts;
        _activity.totalAmounts = _activity.totalAmounts + amounts;

        uint256 needRewards = _activity.totalAmounts - totalRewardeds;

        require(
            needRewards <= IBEP20(_activity.target).balanceOf(this),
            "ARC:NO_BALANCE"
        );

        emit AddUserRewards(id, user, amounts);
    }

     /**
     * @dev private function to reduce user reward amount. when the reward amount of a user is 0, `totalUsers` - 1.
     * @param id activity id
     * @param user user address
     * @param amounts reduce amount
     */
    function _removeUserRewards(
        uint256 id,
        address user,
        uint256 amounts
    ) private {
        require(
            id > 0 && id <= _index && user != address(0) && amounts > 0,
            "ARC:ERR_PARAMS"
        );

        Activity storage _activity = activities[id];
        Reward storage _reward = rewards[id][user];

        require(_reward.amounts >= amounts, "ARC:ERR_AMOUNT");

        _reward.amounts = _reward.amounts - amounts;
        _activity.totalAmounts = _activity.totalAmounts - _reward.amounts;

        if (_reward.amounts == 0) {
            _activity.totalUsers = _activity.totalUsers - 1;
        }

        emit RemoveUserRewards(id, user, amounts);
    }
}
