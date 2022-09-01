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