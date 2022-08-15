// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./interfaces/IAirdrop.sol";
import "./ArcGuarder.sol";

contract TokenAirdropTemplate is IAirdrop, ArcGuarder {

    // extending uint256 by SafeMath
    using SafeMath for uint256;

    // activity => Activity
    mapping(uint256 => Activity) public activities;

    // activityId => ( userAddress => Reward )
    mapping(uint256 => mapping(address => Reward)) public rewards;

    uint256 private _index;
        address target;
        uint256 totalAmounts;
        uint256 totalUsers;
        bool status;

    function addActivity(address asset) public returns (uint256 activityId) {
        _index = _index + 1;
        require(asset != address(0), "ARC:ADDR0");

        activities[_index] = Activity(asset, 0, 0, false);
        activityId = _index;

        emit AddActivity(activityId);
    }

    function addUserRewards(
        uint256 id,
        address user,
        uint256 targetId,
        uint256 amounts
    ) public {}

    function addUsersRewards(
        address[] memory users,
        uint256[] memory targetIds,
        uint256[] memory amounts
    ) public {}

    function removeUserRewards(
        uint256 id,
        address user,
        uint256 amounts
    ) public {}

    function removeusersRewards(
        address[] memory users,
        uint256[] memory targetIds,
        uint256[] memory amounts
    ) public {}

    function withdrawRemain(uint256 id) public returns (uint256 remains) {}

    function openActivity(uint256 id) public {}

    function closeActivity(uint256 id) public {}
}
