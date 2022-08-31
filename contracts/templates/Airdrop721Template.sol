// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

import "../interfaces/IAirdrop.sol";
import "../ArcPartner.sol";
import "../ArcTokenGuarder.sol";
import "../ArcInit.sol";

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
    uint256 internal currentId;

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
    ) external lock(id) returns (uint256) {

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
    ) external lock(id) onlyPartner returns (uint256) {
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
    function removeUserRewards(uint256 id, address user, uint256 targetId, uint256 amount) external lock(id) {
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
    )  external lock(id) {
        require( targetIds.length == users.length && amounts.length == users.length,
            "ARC:ERR_PARAMS"
        );

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
        external
        onlyPartner
        lock(id)
        whenNotPaused
        noDestroy(id)
    {
        require(id > 0 && id <= currentId, "ARC:ERRID");

        IERC721 NFT = IERC721(activities[id].target);

        for(uint i; i< tokenIds.length; i++){
            NFT.safeTransferFrom(address(this), msg.sender, tokenIds[i]);
        }

        delete activities[id];
        delete tokenIds;

        activities[id].status = false;
        activities[id].isDestroy = true;
    }

    /**
     * @dev withdraw the rewards by users.
     * @param id activity id
     * @param targetId it should be 0 in this contract.
     */
    function withdrawRewards(uint256 id, uint256 targetId)
        external
        lock(id)
        noPaused(id)
        whenNotPaused
    {

        require(id > 0 && id <= currentId, "ARC:ERR_ID");
        require(activities[id].status, "ARC:STOPED");

        uint[] storage _rewards = rewards[id][msg.sender];
        require(_rewards.length > 0, "ARC:NO_REWARD");

        for(uint i; i< _rewards.length;i++){
            IERC721(activities[id].target).safeTransferFrom(address(this),msg.sender,_rewards[i],'0x');
            activities[id].totalRewardeds += 1;

            for(uint k; k< tokenIds.length;k++){
                if(_rewards[i] == tokenIds[k]){
                    tokenIds[k] = tokenIds[tokenIds.length-1];
                    tokenIds.pop();
                }
            }

            emit WithdrawRewards(id, msg.sender, _rewards[i], _rewards.length);
        }
       
        delete rewards[id][msg.sender];

    }

    function openActivity(uint256 id) external onlyPartner noDestroy(id) {
        require(id > 0 && id <= currentId, "ARC:ERRID");
        activities[id].status = true;

        emit SetStatus(id, true);
    }

    function closeActivity(uint256 id) external onlyPartner lock(id) noDestroy(id)
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
        require(_checkUserRewards(id,user,targetId),"ARC: USER_IS_NOT_NFT_OWNER");
        require(id > 0 && id <= currentId,"ARC:ERR_PARAMS");

        require(IERC721(activities[id].target).ownerOf(targetId) == address(this),"ARC: AMOUNT_ERROR");

        activities[id].totalAmounts -= amount;

        for(uint i; i< tokenIds.length; i++){
            if(targetId == tokenIds[i]){
                tokenIds[i] = tokenIds[tokenIds.length-1];
                tokenIds.pop();
            }
        }

        uint[] storage _rewards = rewards[id][user];

        for(uint i; i< _rewards.length; i++){
            if(targetId == _rewards[i]){
                _rewards[i] = _rewards[_rewards.length-1];
                _rewards.pop();
            }
        }

        emit RemoveUserRewards(id, user,targetId,1);
    }

    function _checkUserRewards(uint id,address user,uint targetId) private view returns(bool isExsit){
        uint[] memory _rewards = rewards[id][user];

        for(uint i; i< _rewards.length; i++){
            if(targetId == _rewards[i]){
                isExsit = true;
            }
        }

    }

    function getTokenIdsLength()external view returns(uint){
        return tokenIds.length;
    }

    function getUserRewards(uint id, address user)external view returns(uint[] memory _tokenIds){
        activities[id].isDestroy == true?  _tokenIds = _tokenIds : _tokenIds = rewards[id][user];
    }

}
