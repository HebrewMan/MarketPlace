// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./libraries/transferHelper.sol";
import "./interfaces/IAirdrop.sol";
import "./interfaces/IBEP20.sol";
import "./ArcPartner.sol";
import "./ArcTokenGuarder.sol";
import "./ArcInit.sol";

contract TokenAirdropTemplate is
    IAirdrop,
    ArcTokenGuarder,
    ArcPartner,
    ArcInit
{
    // extending uint256 by SafeMath
    using SafeMath for uint256;

    // activity => Activity
    mapping(uint256 => Activity) public activities;

    // activityId => ( userAddress => ( targetId => reward ) )
    mapping(uint256 => mapping(address => mapping(uint256 => uint256)))
        public rewards;

    // index of activity
    uint256 private _index;

    /**
     * @dev Modifier to allow actions only when the activity is not destroy
     */
    modifier noDestroy(uint256 id) {
        if (id > 0) {
            require(!activities[id].isDestroy, "ARC:DESTROYED");
        }
        _;
    }

    /**
     * @dev Initialize
     * @param partner address of partner, like owner
     */
    function init(address partner) public isInit {
        _setPartner(partner);
    }

    /**
     * @dev public function for adding a user's reward rule.
     */
    function addUserRewards(
        uint256 id,
        address asset,
        address user,
        uint256 targetId,
        uint256 amount
    ) public override onlyPartner {
        _addUserRewards(id, asset, user, targetId, amount);
        TransferHelper.safeTransferFrom(asset, msg.sender, address, amount);
    }

    /**
     * @dev do the same thing as 'addUserRewards' function. but it is a batch operation.
     */
    function addUsersRewards(
        uint256 id,
        address asset,
        address[] memory users,
        uint256[] memory targetIds,
        uint256[] memory amounts
    ) public override onlyPartner {
        require(
            users.length > 0 &&
                targetIds.length == users.length &&
                amounts.length == users.length,
            "ARC:ERR_PARAMS"
        );

        uint256 _totalAmount;
        for (uint256 i = 0; i < users.length; i++) {
            _addUserRewards(id, asset, users[i], targetIds[i], amounts[i]);

            _totalAmount = _totalAmount + amounts[i];
        }

        TransferHelper.safeTransferFrom(
            asset,
            msg.sender,
            address,
            _totalAmount
        );
    }

    /**
     * @dev public function to reduce user reward amount.
     * @param id activity id
     * @param user user address
     * @param targetId it should be 0 in this contract
     * @param amount reduce amount
     */
    function removeUserRewards(
        uint256 id,
        address user,
        uint256 targetId,
        uint256 amount
    ) public override onlyPartner {
        uint256 refundAmount = _removeUserRewards(id, user, targetId, amount);

        if (refundAmount > 0) {
            TransferHelper.safeTransfer(
                activities[id].target,
                msg.sender,
                refundAmount
            );
        }
    }

    /**
     * @dev do the same thing as 'removeUserRewards' function. but it is a batch operation.
     */
    function removeUsersRewards(
        uint256 id,
        address[] memory users,
        uint256[] memory targetIds,
        uint256[] memory amounts
    ) public override onlyPartner {
        require(
            users.length > 0 &&
                targetIds.length == users.length &&
                amounts.length == users.length,
            "ARC:ERR_PARAMS"
        );

        uint256 _totalRefund;
        for (uint256 i = 0; i < users.length; i++) {
            uint256 refundAmount = _removeUserRewards(
                id,
                users[i],
                targetIds[i],
                amounts[i]
            );

            _totalRefund = _totalRefund + refundAmount;
        }

        if (_totalRefund > 0) {
            TransferHelper.safeTransfer(
                activities[id].target,
                msg.sender,
                _totalRefund
            );
        }
    }

    /**
     * @dev destroy an activity.
     * @param id activity id
     * 1. stop activity
     * 2. transfer remain amount of this activity to partner
     */
    function destroyActivity(uint256 id)
        public
        override
        onlyPartner
        whenNotPaused
        noDestroy(id)
    {
        require(id > 0 && id <= _index, "ARC:ERRID");

        // stop activity
        activities[id].status = false;
        activities[id].isDestroy = true;

        address _target = activities[id].target;
        uint256 remain = activities[id].totalAmounts - activities[id].totalRewardeds;

        if (remain > 0) {
            require(remain <= IBEP20(_target).balanceOf(address(this)), "ARC:OUT_OF_BALANCE");

             TransferHelper.safeTransfer(_target, msg.sender, remain);
        }

        emit DestroyActivity(id, remain);
    }

    /**
     * @dev withdraw the rewards.
     * @param id activity id
     * @param targetId it should be 0 in this contract.
     */
    function withdrawRewards(uint256 id, uint256 targetId)
        public
        override
        whenNotPaused
    {
        require(id > 0 && id <= _index, "ARC:ERRID");
        require(activities[id].status, "ARC:STOPED");

        address _target = activities[id].target;
        uint256 _reward = rewards[id][msg.sender][targetId];

        require(_reward > 0, "ARC:NO_REWARD");

        TransferHelper.safeTransfer(_target, msg.sender, _reward);

        activities[id].totalRewardeds = activities[id].totalRewardeds + _reward;

        rewards[id][msg.sender][targetId] = 0;

        emit WithdrawRewards(id, msg.sender, targetId, _reward);
    }

    function openActivity(uint256 id) public override onlyPartner noDestroy(id) {
        require(id > 0 && id <= _index, "ARC:ERRID");
        activities[id].status = true;

        emit SetStatus(id, true);
    }

    function closeActivity(uint256 id) public override onlyPartner noDestroy(id) {
        require(id > 0 && id <= _index, "ARC:ERRID");
        activities[id].status = false;

        emit SetStatus(id, false);
    }

    /**
     * @dev private function for adding user's reward rule. Cumulative reward! if the user reward is 0.
     * @param id activity Id. it should be 0 when it is first created
     * @param asset it should be token address in contract address.it should be none when it is not first created
     * @param user user address
     * @param targetId it should be 0 in this contract.
     * @param amount reward amount set this time
     * @notice `id` and `asset` can not be empty or non empty at the same time
     */
    function _addUserRewards(
        uint256 id,
        address asset,
        address user,
        uint256 targetId,
        uint256 amount
    ) private whenNotPaused noDestroy(id) {
        require(
            user != address(0) && amount > 0 && asset != address(0),
            "ARC:ERR_PARAMS"
        );
        require(
            (id > 0 && asset == address(0)) || (id == 0 && asset != address(0)),
            "ARC:ERR_PARAMS"
        );

        if (id > 0) {
            require(activities[id].target != address(0), "ARC:NO_DATA");
        } else {
            // if it is no activitiy, then create it.
            _index = _index + 1;
            activities[_index] = Activity(asset, 0, 0, false, false);

            emit AddActivity(_index, asset);
        }

        Activity storage _activity = activities[id];

        uint256 _reward = rewards[id][user][targetId];

        rewards[id][user][targetId] = _reward + amount;
        _activity.totalAmounts = _activity.totalAmounts + amount;

        emit AddUserRewards(id, user, amount);
    }

    /**
     * @dev private function to reduce user reward amount. when the reward amount of a user is 0.

     * @param id activity id
     * @param user user address
     * @param targetId it should be 0 in this contract.
     * @param amount reduce amount
     */
    function _removeUserRewards(
        uint256 id,
        address user,
        uint256 targetId,
        uint256 amount
    ) private whenNotPaused noDestroy(id) returns (uint256 refundAmount) {
        require(
            id > 0 && id <= _index && user != address(0) && amount > 0,
            "ARC:ERR_PARAMS"
        );

        Activity storage _activity = activities[id];
        uint256 _reward = rewards[id][user][targetId];
        uint256 remain = _reward - amount;

        rewards[id][user][targetId] = remain;

        if (remain > 0) {
            _activity.totalAmounts = _activity.totalAmounts - amount;
            refundAmount = amount;
        } else {
            _activity.totalAmounts = _activity.totalAmounts - _reward;
            refundAmount = _reward;
        }

        emit RemoveUserRewards(id, user, amount);
    }
}
