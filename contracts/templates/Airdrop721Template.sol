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
    ArcInit,
    ERC721Holder
{

    // activityId => Activity info
    mapping(uint => Activity) public activities;

    mapping(uint => mapping(address => uint[])) internal rewards;

    uint[] public tokenIds;

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
    ) public lock(id) returns (uint256) {

        require(IERC721(asset).ownerOf(targetId) == msg.sender , "ARC: CALLER_NOT_OWNER");
        require(amount == 1,"ARC: AMOUNT_SHOULD_BE_1");

        uint _id = _addUserRewards(id, asset);

        activities[_id].totalAmounts += amount;
        rewards[_id][user].push(targetId);
        tokenIds.push(targetId);

        IERC721(asset).safeTransferFrom(msg.sender,address(this),targetId,'0x');

        emit AddUserRewards(_id, user, targetId);

        return _id;
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
    ) public lock(id) onlyPartner returns (uint256) {
        require(
            users.length > 0 && targetIds.length == users.length && amounts.length == users.length,
            "ARC:Array length is error"
        );

        uint _id = _addUserRewards(id,asset);

        for (uint256 i = 0; i < users.length; i++) {
            require(IERC721(asset).ownerOf(targetIds[i]) == msg.sender , "ARC: CALLER_NOT_OWNER");
            require(amounts[i] == 1,"ARC: AMOUNT_SHOULD_BE_1");
            rewards[_id][users[i]].push(targetIds[i]);
            activities[_id].totalAmounts += 1;
            tokenIds.push(targetIds[i]);

            IERC721(asset).safeTransferFrom(msg.sender,address(this),targetIds[i],'0x');

            emit AddUserRewards(_id, users[i], targetIds[i]);
        }

        return _id;
    }

    /**
     * @dev public function to reduce user reward amount.
     * @param id activity id
     * @param user user address
     * @param targetId it should be 0 in this contract
     * @param amount reduce amount
     */
    function removeUserRewards(uint256 id, address user, uint256 targetId, uint256 amount) public lock(id) {
        _removeUserRewards(id, user, targetId,amount);
        IERC721(activities[id].target).safeTransferFrom(address(this),msg.sender,targetId,'0x');
    }

    /**
     * @dev do the same thing as 'removeUserRewards' function. but it is a batch operation.
     */
    function removeUsersRewards(
        uint256 id,
        address[] memory users,
        uint256[] memory targetIds,
        uint256[] memory amounts
    )  public lock(id) {
        require( targetIds.length == users.length && amounts.length == users.length,
            "ARC:ERR_PARAMS"
        );

        //users 数量 跟 rewards 数量不一定相等

        for (uint256 i = 0; i < users.length; i++) {
            _removeUserRewards(id,users[i],targetIds[i],amounts[i]);
             IERC721(activities[id].target).safeTransferFrom(address(this),msg.sender,targetIds[i],'0x');
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

        require(id > 0 && id <= currentId, "ARC:ERR_ID");
        require(activities[id].status, "ARC:STOPED");

        uint[] storage rewardsTokenids = rewards[id][msg.sender];
        require(rewardsTokenids.length > 0, "ARC:NO_REWARD");

        for(uint i; i< rewardsTokenids.length;i++){
            IERC721(activities[id].target).safeTransferFrom(address(this),msg.sender,rewardsTokenids[i],'0x');
            activities[id].totalRewardeds += 1;
            emit WithdrawRewards(id, msg.sender, rewardsTokenids[i], rewardsTokenids.length);
        }

        delete rewards[id][msg.sender];

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
    function _addUserRewards(uint256 id, address asset)
        private
        whenNotPaused
        onlyPartner
        noDestroy(id)
        returns(uint)
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

        console.log("======== current id is :",_id);
        return _id;

    }

    /*
     * @dev private function to reduce user reward amount. when the reward amount of a user is 0.

     * @param id activity id
     * @param user user address
     * @param targetId it should be nft tokenId in this contract.
     * @param amount reduce amount
     */
    function _removeUserRewards(
        uint256 id,
        address user,
        uint256 targetId,
        uint amount
    ) private whenNotPaused noDestroy(id) onlyPartner{
        require(amount == 1,"ARC: AMOUNT_SHOULD_BE_1");
        require(
            id > 0 && id <= currentId && user != address(0),
            "ARC:ERR_PARAMS"
        );

        require(IERC721(activities[id].target).ownerOf(targetId) == address(this),"ARC: AMOUNT_ERROR");

        activities[id].totalAmounts -= amount;

        for(uint i; i< tokenIds.length; i++){
            if(targetId == tokenIds[i]){
                tokenIds[i] = tokenIds[i + 1];
                tokenIds.pop();
            }
        }

        for(uint i; i< rewards[id][user].length; i++){
            if(targetId == rewards[id][user][i]){
                rewards[id][user][i] = rewards[id][user][i + 1];
                rewards[id][user].pop();
            }
        }


        emit RemoveUserRewards(id, user,targetId,1);
    }

    function getUserRewards(uint id, address user)external view returns(uint[] memory){
        return rewards[id][user];
    }
}
