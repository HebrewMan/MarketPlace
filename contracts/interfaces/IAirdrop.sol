// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Activity {
    address target;
    uint256 totalAmounts;
    uint256 totalRewardeds;
    bool status;
    bool isDestroy;
    bool unlocked;
}

    
interface IAirdrop {

    function addUserRewards(uint256 id, address asset, address user, uint256 targetId, uint256 amount) external returns (uint256 index);
    function addUsersRewards(uint256 id, address asset, address[] memory users, uint256[] memory targetIds, uint256[] memory amounts) external returns (uint256 index);
    function removeUserRewards(uint256 id, address user, uint256 targetId, uint256 amount) external;
    function removeUsersRewards(uint256 id, address[] memory users, uint256[] memory targetIds, uint256[] memory amounts) external;

    function destroyActivity(uint256 id) external;

    function withdrawRewards(uint256 id, uint256 targetId) external;
    function openActivity(uint256 id) external;
    function closeActivity(uint256 id) external;

    event AddActivity(uint256 indexed id, address indexed target);//here need add targetId
    event AddUserRewards(uint256 indexed id, address indexed user, uint256 amount);//here need add targetId
    event RemoveUserRewards(uint256 indexed id, address indexed user, uint256 amount);//here need add targetId

    event AddActivity(uint256 indexed id, address indexed target,uint indexed targetId);//here need add targetId
    event AddUserRewards(uint256 indexed id,address indexed user,uint indexed targetId, uint256 amount);//here need add targetId
    event RemoveUserRewards(uint256 indexed id, address indexed user, uint indexed targetId, uint256 amount);//here need add targetId

    event DestroyActivity(uint256 indexed id, uint256 refundAmount);//here need add targetId
    event WithdrawRewards(uint256 indexed id, address indexed user, uint256 indexed targetId, uint256 reward);
    event SetStatus(uint256 indexed id, bool status);
}