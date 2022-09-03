// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import "./AirdropBase.sol";

contract Airdrop1155Template is AirdropBase, ERC1155Holder{

    mapping(uint =>mapping(address => uint[])) userTargetIds;//by user rewards or address(this) destroy;
    mapping(uint =>mapping(address => uint[])) userAmounts;//by user rewards or address(this) destroy;

    /**
     * @dev do the same thing as 'addUserRewards' function. but it is a batch operation.
     */

     //delete lock
    function addUsersRewards(
        uint256 id,
        address asset,
        address[] memory users,
        uint256[] memory targetIds,
        uint256[] memory amounts
    ) external onlyPartner returns (uint256) {
        require(
            users.length > 0 && targetIds.length == users.length && amounts.length == users.length,
            "ARC:LENGTH_ERROR"
        );

        uint _id = _addUserRewards(id,asset);

        uint[] storage _valutTargetIds = userTargetIds[_id][address(this)];

        for (uint256 i = 0; i < users.length; i++) {

            uint[] storage _userTargetIds = userTargetIds[_id][users[i]];
            uint[] storage _userAmounts = userAmounts[_id][users[i]];

            //add user assets data
            if(_checkUserRewards(targetIds[i],_userTargetIds)){
                for(uint j;j<_userTargetIds.length;j++){
                    if(targetIds[i] == _userTargetIds[j]){
                        _userAmounts[j] += amounts[i];
                    }
                }
            }else{
                userTargetIds[_id][users[i]].push(targetIds[i]);
                userAmounts[_id][users[i]].push(amounts[i]);
            }

            //add valut assets data
            if(!_checkUserRewards(targetIds[i],_valutTargetIds)){
                _valutTargetIds.push(targetIds[i]);
            }

        }

        IERC1155(asset).safeBatchTransferFrom(msg.sender,address(this),targetIds,amounts,'0x');
        return _id;
    }

    /**
     * @dev do the same thing as 'removeUserRewards' function. but it is a batch operation.
     */
    function removeUsersRewards(
        uint256 id,
        address[] memory users,
        uint256[] memory targetIds,
        uint256[] memory amounts
    ) external onlyPartner noDestroy(id) whenNotPaused{
        require( targetIds.length == users.length && amounts.length == users.length,
            "ARC:ERR_PARAMS"
        );
        require(id > 0 && id <= currentId,"ARC:ERR_PARAMS");

        for (uint i; i < users.length; i++) {
            uint[] memory _userTargetIds = userTargetIds[id][users[i]];

            //delte users assets data;
            for(uint k; k < targetIds.length;k++){
                if(!_checkUserRewards(targetIds[i], _userTargetIds)){
                    revert("ARC: NOT_EXSITED");
                }

                if(targetIds[i] == _userTargetIds[k]){
                    require(amounts[i]>0 && amounts[i]<=userAmounts[id][users[i]][k],"ARC:AMOUNT_ERROR");
                    userAmounts[id][users[i]][k] -= amounts[i];
                }
            }

            // activities[id].totalAmounts -= amounts[i];
            emit RemoveUserRewards(id, users[i],targetIds[i],amounts[i]);
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
        external
        onlyPartner
        whenNotPaused
        noDestroy(id)
    {
        require(id > 0 && id <= currentId, "ARC:ERRID");

        address _target = activities[id].target;
        uint[] memory _valutTargetIds = userTargetIds[id][address(this)];

        for(uint i;i<_valutTargetIds.length;i++){
            uint _balanceOf = IERC1155(_target).balanceOf(address(this),_valutTargetIds[i]);
            IERC1155(_target).safeTransferFrom(address(this), msg.sender,_valutTargetIds[i], _balanceOf, "0x");
        }
        
        activities[id].isDestroy = true;
    }

    /**
     * @dev withdraw the rewards by users.
     * @param id activity id
     * @param targetId it should be 0 in this contract.
     */
    function withdrawRewards(uint256 id, uint256 targetId)
        external 
        noPaused(id)
        whenNotPaused
    {

        uint[] memory _userTargetIds = userTargetIds[id][msg.sender];
        uint[] memory _userAmounts = userAmounts[id][msg.sender];

        IERC1155(activities[id].target).safeBatchTransferFrom(address(this),msg.sender,_userTargetIds,_userAmounts,'0x');

        delete userTargetIds[id][msg.sender];
        delete userAmounts[id][msg.sender];

        // emit WithdrawRewards(id, msg.sender, targetId, _reward);
    }


    /*
     * @dev private function for adding user's reward rule. Cumulative reward! if the user reward is 0.
     * @param id activity Id. it should be 0 when it is first created
     * @param asset target token address
     */
    function _addUserRewards(uint256 id, address asset) private noDestroy(id) whenNotPaused returns(uint){
        if (id > 0) {
            require(activities[id].target == asset, "ARC: ASSET_ERROR");
        } else {
            currentId += 1;
            activities[currentId].target = asset;
            activities[currentId].unlocked = true;
            emit AddActivity(currentId,asset);
        }
        return currentId;
    }

     function _checkUserRewards(uint element,uint[] memory arr) private pure returns(bool isExsit){
        uint[] memory _arr = new uint[](arr.length);
        for(uint i; i< _arr.length; i++){
            if(element == _arr[i]){
                isExsit = true;
            }
        }
    }

    function getUserRewards(uint id, address user)external view returns(uint[] memory _targetIds,uint[] memory _amounts){
        activities[id].isDestroy == true?  _targetIds = _targetIds : _targetIds = userTargetIds[id][user];
        activities[id].isDestroy == true?  _amounts = _amounts : _amounts = userAmounts[id][user];
    }
}
