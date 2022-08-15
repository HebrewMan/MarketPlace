// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./interfaces/IAirdrop.sol";
import "./ArcPartner.sol";
import "./ArcGuarder.sol";
import "./ArcInit.sol";

contract TokenAirdropTemplate is IAirdrop, ArcGuarder, ArcPartner, ArcInit {

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

    /**
     * @dev Initialize
     * @param partner address of partner, like owner
     */
    function init(address partner) public isInit {
        _setPartner(partner);
    }

    /**
     * @dev Add a row of rules for airdrop
     * @param asset token address or nft contract address
     */
    function addActivity(address asset) public onlyPartner returns (uint256 activityId) {
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
    ) public onlyPartner {}

    function addUsersRewards(
        address[] memory users,
        uint256[] memory targetIds,
        uint256[] memory amounts
    ) public onlyPartner {}

    function removeUserRewards(
        uint256 id,
        address user,
        uint256 amounts
    ) public onlyPartner {}

    function removeusersRewards(
        address[] memory users,
        uint256[] memory targetIds,
        uint256[] memory amounts
    ) public onlyPartner {}

    function withdrawRemain(uint256 id) public onlyPartner returns (uint256 remains) {}

    function openActivity(uint256 id) public onlyPartner {}

    function closeActivity(uint256 id) public onlyPartner {}
}
