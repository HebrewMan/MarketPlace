// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/transferHelper.sol";
import "../ArcTokenGuarder.sol";

import "./AirdropBase.sol";
contract Airdrop20Template is ArcTokenGuarder,AirdropBase{
    /**
     * @dev do the same thing as 'addUserRewards' function. but it is a batch operation.
     */
    function addUsersRewards(
        uint256 id,
        address asset,
        address[] memory users,
        uint256[] memory targetIds,
        uint256[] memory amounts
    ) public onlyPartner returns (uint256) {
        require(users.length > 0 && targetIds.length == users.length && amounts.length == users.length,
            "ARC:Array length is error"
        );

        uint _id = _addUserRewards(id,asset);
        uint transferTotalAmount;

        for (uint256 i = 0; i < users.length; i++) {
            require(amounts[i] > 0, "ARC: Amounts[i] must be greater than 0 ");

            transferTotalAmount += amounts[i];

            activities[_id].totalAmounts += amounts[i];
            rewards[_id][users[i]][targetIds[i]] += amounts[i];

            emit AddUserRewards(_id, users[i], amounts[i]);
        }

        TransferHelper.safeTransferFrom(
            asset,
            msg.sender,
            address(this),
            transferTotalAmount
        );

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
    ) public onlyPartner {
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
        onlyPartner
        whenNotPaused
        noDestroy(id)
    {
        require(id > 0 && id <= currentId, "ARC:ERRID");

        activities[id].status = false; // stop activity
        activities[id].isDestroy = true;

        address _target = activities[id].target;
        uint256 remain = activities[id].totalAmounts - activities[id].totalRewardeds;

        if (remain > 0) {
            require(
                remain <= IBEP20(_target).balanceOf(address(this)),
                "ARC:OUT_OF_BALANCE"
            );

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
        noPaused(id)
        whenNotPaused
    {
        require(id > 0 && id <= currentId, "ARC:ERRID");
        require(activities[id].status, "ARC:STOPED");

        address _target = activities[id].target;
        uint256 _reward = rewards[id][msg.sender][targetId];

        require(_reward > 0, "ARC:NO_REWARD");

        TransferHelper.safeTransfer(_target, msg.sender, _reward);

        activities[id].totalRewardeds = activities[id].totalRewardeds + _reward;

        rewards[id][msg.sender][targetId] = 0;

        emit WithdrawRewards(id, msg.sender, targetId, _reward);
    }

    /*
     * @dev private function for adding user's reward rule. Cumulative reward! if the user reward is 0.
     * @param id activity Id. it should be 0 when it is first created
     * @param asset target token address
     */
    function _addUserRewards(uint256 id, address asset)
        private
        whenNotPaused
        noDestroy(id)
        returns (uint256)
    {
        require(asset != address(0), "ARC:Asset Must not be address(0)");

        if (id > 0) {
            require(
                activities[id].target == asset,
                "ARC: Asset address is error"
            );
            return id;
        } else {
            currentId += 1;
            activities[currentId].target = asset;
            activities[currentId].unlocked = true;
            emit AddActivity(currentId, asset);
            return currentId;
        }
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
            id > 0 && id <= currentId && user != address(0) && amount > 0,
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

    function getUserRewards(uint id, address user)external view returns(uint[] memory tokenIds,uint[] memory amounts){

    }


}
