// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";


import "../libraries/transferHelper.sol";
import "../interfaces/IAirdrop.sol";
import "../ArcPartner.sol";
import "../ArcTokenGuarder.sol";
import "../ArcInit.sol";

contract Airdrop1155Template is
    IAirdrop, 
    ArcTokenGuarder,
    ArcPartner,
    ArcInit
{

    // activityId => Activity info
    mapping(uint256 => Activity_) public activities;

    //activityId => targetId => partnar info
    mapping(uint => mapping(uint => TotalData)) public targetIdAmounts;

    // activityId => ( userAddress => ( targetId => reward ) )user info
    mapping(uint256 => mapping(address => mapping(uint256 => uint256)))
        public rewards;

    // index of activity 
    // The activity that creates the activity is to be used
    uint256 public currentId;

    struct TotalData{
        uint256 totalAmounts;//总数量
        uint256 totalRewardeds;//已领取的数量
    }

    struct Activity_ {
        address target;
        bool status;
        bool isDestroy;
        bool unlocked;
        uint[] targetIds;
        uint[] amounts;
    }

    /**
     * @dev Modifier to allow actions only when the activity is not paused
     */
    modifier noPaused(uint256 id) {
        require(id > 0, "ARC:ERRID");
        require(activities[id].status, "ARC:ACTIV_PAUSED");
        _;
    }

    /**
     * @dev Modifier to allow actions only when the activity is not destroy
     */
    modifier noDestroy(uint256 id) {
        if (id > 0) {
            require(!activities[id].isDestroy, "ARC:DESTROYED");
        }
        _;
    }

    modifier lock(uint256 id) {
        if (id > 0) {
            require(activities[id].unlocked, "ARC:LOCKED");
            activities[id].unlocked = false;
            _;
            activities[id].unlocked = true;
        } else {
            _;
        }
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
    ) public lock(id) onlyPartner returns (uint256 index) {

         _addUserRewards(id, asset,user,targetId,amount);

        IERC1155(asset).safeTransferFrom(msg.sender,address(this),targetId,amount,'0x');

        id>0? index = id : index = currentId;

        emit AddUserRewards(index, user, amount);
 
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
    ) public lock(id) onlyPartner returns (uint256 index) {
        require(
            users.length > 0 && targetIds.length == users.length && amounts.length == users.length,
            "ARC:Array length is error"
        );

        for (uint256 i = 0; i < users.length; i++) {
            require(amounts[i] > 0, "ARC: Amounts[i] must be greater than 0 ");
            _addUserRewards(id,asset,users[i],targetIds[i],amounts[i]);
        }

        IERC1155(asset).safeBatchTransferFrom(msg.sender,address(this),targetIds,amounts,'0x');

        id>0? index = id : index = currentId;
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
    ) public lock(id) onlyPartner {

         _removeUserRewards(id, user, targetId, amount);

        IERC1155(activities[id].target).safeTransferFrom(address(this),msg.sender,targetId,amount,'0x');
    }

    /**
     * @dev do the same thing as 'removeUserRewards' function. but it is a batch operation.
     */
    function removeUsersRewards(
        uint256 id,
        address[] memory users,
        uint256[] memory targetIds,
        uint256[] memory amounts
    ) public lock(id) onlyPartner {
        require( targetIds.length == users.length && amounts.length == users.length,
            "ARC:ERR_PARAMS"
        );

        for (uint256 i = 0; i < users.length; i++) {
            _removeUserRewards(id,users[i],targetIds[i],amounts[i]);
        }

        IERC1155(activities[id].target).safeBatchTransferFrom(address(this),msg.sender,targetIds,amounts,'0x');
            
    }

    /**
     * @dev destroy an activity.
     * @param id activity id
     * 1. stop activity
     * 2. transfer remain amount of this activity to partner
     */
    function destroyActivity(uint256 id)
        public
        onlyPartner
        lock(id)
        whenNotPaused
        noDestroy(id)
    {
        require(id > 0 && id <= currentId, "ARC:ERRID");

        address _target = activities[id].target;

        IERC1155(_target).safeBatchTransferFrom(msg.sender,address(this),activities[id].targetIds,activities[id].amounts,'0x');

        for(uint i;i<activities[id].targetIds.length;i++){
            delete targetIdAmounts[id][activities[id].targetIds[i]];
        }

        delete activities[id];
        
        activities[id].status = false; // stop activity
        activities[id].isDestroy = true;

    }

    /**
     * @dev withdraw the rewards by users.
     * @param id activity id
     * @param targetId it should be 0 in this contract.
     */
    function withdrawRewards(uint256 id, uint256 targetId)
        public
        lock(id)
        noPaused(id)
        whenNotPaused
    {
        require(id > 0 && id <= currentId, "ARC:ERRID");
        require(activities[id].status, "ARC:STOPED");

        uint256 _reward = rewards[id][msg.sender][targetId];

        require(_reward > 0, "ARC:NO_REWARD");

        IERC1155(activities[id].target).safeTransferFrom(address(this),msg.sender,targetId,_reward,'0x');

        rewards[id][msg.sender][targetId] = 0;

        targetIdAmounts[id][targetId].totalRewardeds += _reward;

        emit WithdrawRewards(id, msg.sender, targetId, _reward);
    }

    function openActivity(uint256 id) public onlyPartner noDestroy(id) {
        require(id > 0 && id <= currentId, "ARC:ERRID");
        activities[id].status = true;

        emit SetStatus(id, true);
    }

    function closeActivity(uint256 id)
        public
        onlyPartner
        lock(id)
        noDestroy(id)
    {
        require(id > 0 && id <= currentId, "ARC:ERRID");
        activities[id].status = false;

        emit SetStatus(id, false);
    }

    /*
     * @dev private function for adding user's reward rule. Cumulative reward! if the user reward is 0.
     * @param id activity Id. it should be 0 when it is first created
     * @param asset target token address
     */
    function _addUserRewards(uint256 id, address asset,address user,
        uint256 targetId,
        uint256 amount)
        private
        whenNotPaused
        noDestroy(id)
    {
        uint _id = id;

        if (id > 0) {
            require(activities[id].target == asset, "ARC: Asset address is error");
        } else {
            currentId += 1;
            _id = currentId;
            activities[currentId].target = asset;
            activities[currentId].unlocked = true;
            emit AddActivity(currentId,asset);
        }

        rewards[_id][user][targetId] += amount;
        targetIdAmounts[_id][targetId].totalAmounts += amount;

        activities[_id].targetIds.push(targetId);
        activities[_id].amounts.push(amount);

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
    ) private whenNotPaused noDestroy(id) {
        require(
            id > 0 && id <= currentId && user != address(0) && amount > 0,
            "ARC:ERR_PARAMS"
        );

        require(rewards[id][user][targetId] >= amount,"ARC: AMOUNT_ERROR");

        rewards[id][user][targetId] -= amount;
        targetIdAmounts[id][targetId].totalAmounts -= amount;

        emit RemoveUserRewards(id, user,targetId,amount);
    }
}
