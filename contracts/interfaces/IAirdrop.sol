// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAirdrop {

    struct Activity {
        uint256 id;
        address target;
        uint256 totalAmounts;
        uint256 totalUsers;
        bool status;
    }

    struct Reward {
        uint256 targetId;
        uint256 amounts;
    }

    function addActivity() external returns (uint256);
    function activities(uint256 id) external;
    function removeActivity(uint256 id) external;
    function addUserRewards(uint256 id, address user, uint256 targetId, uint256 amounts) external;
    function addUsersRewards(address[] memory users, uint256[] memory targetIds, uint256[] memory amounts) external;
    function removeUserRewards(uint256 id, address user, uint256 amounts) external;
    function removeusersRewards(address[] memory users, uint256[] memory targetIds, uint256[] memory amounts) external;
    function withdrawRemain(uint256 id) external;
    function setStatus(uint256 id, bool status) external;

    event AddActivity(uint id);
    event RemoveActivity(uint id);
    event AddUserRewards(uint256 id, address user, uint256 amounts);
    event RemoveUserRewards(uint256 id, address user, uint256 amounts);
    event WithdrawRemain(uint256 id);
    event SetStatus(uint256 id, bool status);
}