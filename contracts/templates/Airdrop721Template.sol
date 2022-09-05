// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

import "./AirdropBase.sol";

contract Airdrop721Template is ERC721Holder, AirdropBase {
    mapping(uint => mapping(address => uint[])) userTokenIds;

    mapping(uint => uint[]) tokenIds;

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
        require(
            users.length > 0 &&
                targetIds.length == users.length &&
                amounts.length == users.length,
            "ARC: LENGTH_ERROR"
        );

        uint _id = _addUserRewards(id, asset);

        for (uint256 i = 0; i < users.length; i++) {
            require(
                IERC721(asset).ownerOf(targetIds[i]) == msg.sender,
                "ARC: NOT_OWNER"
            );
            require(amounts[i] == 1, "ARC: NOT_1");
            userTokenIds[_id][users[i]].push(targetIds[i]);
            activities[_id].totalAmounts += 1;
            tokenIds[_id].push(targetIds[i]);

            IERC721(asset).safeTransferFrom(
                msg.sender,
                address(this),
                targetIds[i],
                "0x"
            );

            emit AddUserRewards(_id, users[i], targetIds[i]);
        }

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
    ) public {
        require(
            targetIds.length == users.length && amounts.length == users.length,
            "ARC:ERR_PARAMS"
        );

        for (uint256 i = 0; i < users.length; i++) {
            _removeUserRewards(id, users[i], targetIds[i], amounts[i]);
            IERC721(activities[id].target).safeTransferFrom(
                address(this),
                msg.sender,
                targetIds[i],
                "0x"
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
        noDestroy(id)
        whenNotPaused
    {
        require(id > 0 && id <= currentId, "ARC:ERRID");
        require(!activities[id].status, "ARC:STATUS_ERROR");

        IERC721 NFT = IERC721(activities[id].target);

        for (uint i; i < tokenIds[id].length; i++) {
            NFT.safeTransferFrom(address(this), msg.sender, tokenIds[id][i]);
        }

        activities[id].isDestroy = true;

        delete tokenIds[id];

    }

    /*
     * @dev withdraw the rewards by users.
     * @param id activity id
     * @param targetId it should be 0 in this contract.
     */
    function withdrawRewards(uint256 id, uint targetId)
        external
        noPaused(id)
        whenNotPaused
    {
        require(id > 0 && id <= currentId, "ARC:ERR_ID");

        uint[] storage _rewards = userTokenIds[id][msg.sender];
        require(_rewards.length > 0, "ARC:NO_REWARD");

        for (uint i; i < _rewards.length; i++) {
            IERC721(activities[id].target).safeTransferFrom(
                address(this),
                msg.sender,
                _rewards[i],
                "0x"
            );
            activities[id].totalRewardeds += 1;

            for (uint k; k < tokenIds[id].length; k++) {
                if (_rewards[i] == tokenIds[id][k]) {
                    tokenIds[id][k] = tokenIds[id][tokenIds[id].length - 1];
                    tokenIds[id].pop();
                }
            }

            emit WithdrawRewards(id, msg.sender, _rewards[i], _rewards.length);
        }

        delete userTokenIds[id][msg.sender];
    }

    /*
     * @dev private function for adding user's reward rule. Cumulative reward! if the user reward is 0.
     * @param id activity Id. it should be 0 when it is first created
     * @param asset target token address
     */
    function _addUserRewards(uint256 id, address asset)
        private
        onlyPartner
        noDestroy(id)
        whenNotPaused
        returns (uint)
    {
        uint _id = id;

        if (id > 0) {
            require(activities[id].target == asset, "ARC: ASSET_ERROR");
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
    ) private noDestroy(id) whenNotPaused onlyPartner {
        require(amount == 1, "ARC: NOT_1");
        require(_checkUserRewards(id, user, targetId), "ARC: USER_ERROR");
        require(id > 0 && id <= currentId, "ARC:ERR_PARAMS");

        require(
            IERC721(activities[id].target).ownerOf(targetId) == address(this),
            "ARC: AMOUNT_ERROR"
        );

        activities[id].totalAmounts -= amount;

        for (uint i; i < tokenIds[id].length; i++) {
            if (targetId == tokenIds[id][i]) {
                tokenIds[id][i] = tokenIds[id][tokenIds[id].length - 1];
                tokenIds[id].pop();
            }
        }

        uint[] storage _rewards = userTokenIds[id][user];

        for (uint i; i < _rewards.length; i++) {
            if (targetId == _rewards[i]) {
                _rewards[i] = _rewards[_rewards.length - 1];
                _rewards.pop();
            }
        }

        emit RemoveUserRewards(id, user, targetId, 1);
    }

    function _checkUserRewards(
        uint id,
        address user,
        uint targetId
    ) private view returns (bool isExsit) {
        uint[] memory _rewards = userTokenIds[id][user];

        for (uint i; i < _rewards.length; i++) {
            if (targetId == _rewards[i]) {
                isExsit = true;
            }
        }
    }

    function getUserRewards(uint id, address user)
        external
        view
        returns (uint[] memory _targetIds, uint[] memory _amounts)
    {
        activities[id].isDestroy == true
            ? _targetIds = _targetIds
            : _targetIds = userTokenIds[id][user];
        _amounts = _amounts;
    }
}
