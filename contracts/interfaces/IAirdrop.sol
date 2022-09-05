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

    function addUsersRewards(uint256 id, address asset, address[] memory users, uint256[] memory targetIds, uint256[] memory amounts) external returns (uint256 index);
    function removeUsersRewards(uint256 id, address[] memory users, uint256[] memory targetIds, uint256[] memory amounts) external;
    function destroyActivity(uint256 id) external;
    function withdrawRewards(uint256 id,uint targetId) external;
    function openActivity(uint256 id) external;
    function closeActivity(uint256 id) external;
    function getUserRewards(uint id, address user)external returns(uint[] memory targetIds,uint[] memory amounts);

    event AddActivity(uint256 indexed id, address indexed target);
    event AddUserRewards(uint256 indexed id, address indexed user, uint256 amount);
    event RemoveUserRewards(uint256 indexed id, address indexed user, uint256 amount);

    event AddUserRewards(uint256 indexed id,address indexed user,uint indexed targetId, uint256 amount);
    event RemoveUserRewards(uint256 indexed id, address indexed user, uint indexed targetId, uint256 amount);

    event DestroyActivity(uint256 indexed id, uint256 refundAmount);
    event WithdrawRewards(uint256 indexed id, address indexed user, uint256 indexed targetId, uint256 reward);
    event SetStatus(uint256 indexed id, bool status);
}