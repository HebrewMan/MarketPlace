// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

import "../libraries/transferHelper.sol";
import "../interfaces/IAirdrop.sol";
import "../ArcPartner.sol";
import "../ArcTokenGuarder.sol";
import "../ArcInit.sol";

import "hardhat/console.sol";

contract Airdrop721Template is
    IAirdrop,
    ArcTokenGuarder,
    ArcPartner,
    ArcInit
{

    // activityId => Activity info
    mapping(uint256 => Activity) public activities;

    mapping( uint => mapping(address => uint)) public rewards;

    uint[] tokenIds;

    // The activity that creates the activity is to be used
    uint256 public currentId;

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
    ) public lock(id) returns (uint256 index) {

         _addUserRewards(id, asset,user,targetId);

        id>0? index = id : index = currentId;

        emit AddUserRewards(index, user, targetId);
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
            require(IERC721(asset).ownerOf(targetIds[i]) == msg.sender , "ARC: CALLER_NOT_OWNER");

            _addUserRewards(id,asset,users[i],targetIds[i]);

            emit AddUserRewards(index, users[i], targetIds[i]);
        }

        id>0? index = id : index = currentId;
    }

    /**
     * @dev public function to reduce user reward amount.
     * @param id activity id
     * @param user user address
     * @param targetId it should be 0 in this contract
     * @param amount reduce amount
     */
    function removeUserRewards(uint256 id, address user, uint256 targetId, uint256 amount) public lock(id) {

         _removeUserRewards(id, user, targetId);

    }

    /**
     * @dev do the same thing as 'removeUserRewards' function. but it is a batch operation.
     */
    function removeUsersRewards(
        uint256 id,
        address[] memory users,
        uint256[] memory targetIds,
        uint256[] memory amounts
    ) public lock(id) {
        require( targetIds.length == users.length && amounts.length == users.length,
            "ARC:ERR_PARAMS"
        );

        for (uint256 i = 0; i < users.length; i++) {
            _removeUserRewards(id,users[i],targetIds[i]);
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
        onlyPartner
        lock(id)
        whenNotPaused
        noDestroy(id)
    {
        require(id > 0 && id <= currentId, "ARC:ERRID");

        activities[id].status = false; // stop activity
        activities[id].isDestroy = true;

        IERC721 NFT = IERC721(activities[id].target);

        emit DestroyActivity(id,tokenIds.length);

        for(uint i; i< tokenIds.length; i++){
            NFT.safeTransferFrom(address(this), msg.sender, tokenIds[i]);
        }

        delete activities[id];
        delete tokenIds;

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

        uint256 _reward = rewards[id][msg.sender];

        require(_reward > 0, "ARC:NO_REWARD");

        IERC721(activities[id].target).safeTransferFrom(address(this),msg.sender,targetId,'0x');

        rewards[id][msg.sender] = 0;

        activities[id].totalRewardeds += 1;

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
    function _addUserRewards(uint256 id, address asset,address user,uint256 targetId)
        private
        whenNotPaused
        onlyPartner
        noDestroy(id)
    {
        require(asset != address(0), "ARC:Asset address(0)");

        uint _id = id;

        if (id > 0) {
            require(activities[id].target == asset, "ARC: Asset address is error");
        } else {
            currentId += 1;
            _id = currentId;
            activities[currentId].target = asset;
            activities[currentId].unlocked = true;
            emit AddActivity(currentId, asset);
        }

        rewards[_id][user] = targetId;
        activities[_id].totalAmounts += 1;

        tokenIds.push(targetId);

        console.log("token id is ",targetId);

        console.log("======== current id is :",_id);

        IERC721(asset).safeTransferFrom(msg.sender,address(this),targetId,'0x');

    }

    /*
     * @dev private function to reduce user reward amount. when the reward amount of a user is 0.

     * @param id activity id
     * @param user user address
     * @param targetId it should be 0 in this contract.
     * @param amount reduce amount
     */
    function _removeUserRewards(
        uint256 id,
        address user,
        uint256 targetId
    ) private whenNotPaused noDestroy(id) onlyPartner{
        require(
            id > 0 && id <= currentId && user != address(0),
            "ARC:ERR_PARAMS"
        );

        require(IERC721(activities[id].target).ownerOf(targetId) == address(this),"ARC: AMOUNT_ERROR");

        IERC721(activities[id].target).safeTransferFrom(address(this),msg.sender,targetId,'0x');

        rewards[id][user] = 0;
        activities[id].totalAmounts -= 1;

        emit RemoveUserRewards(id, user,targetId,1);
    }
}