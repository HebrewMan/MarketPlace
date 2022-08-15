// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAirdrop {

    struct Activity {
        address target;
        uint256 totalAmounts;
        uint256 totalUsers;
        bool status;
    }

    struct Reward {
        uint256 targetId;
        uint256 amounts;
    }

    function addActivity(address asset) external returns (uint256);
    function addUserRewards(uint256 id, address user, uint256 targetId, uint256 amounts) external;
    function addUsersRewards(address[] memory users, uint256[] memory targetIds, uint256[] memory amounts) external;
    function removeUserRewards(uint256 id, address user, uint256 amounts) external;
    function removeusersRewards(address[] memory users, uint256[] memory targetIds, uint256[] memory amounts) external;
    function withdrawRemain(uint256 id) external returns (uint256);
    function openActivity(uint256 id) external;
    function closeActivity(uint256 id) external;

    event AddActivity(uint256 indexed id);
    event AddUserRewards(uint256 indexed id, address indexed user, uint256 amounts);
    event RemoveUserRewards(uint256 indexed id, address indexed user, uint256 amounts);
    event WithdrawRemain(uint256 indexed id, address indexed target, uint256 remain);
    event SetStatus(uint256 indexed id, bool status);
}