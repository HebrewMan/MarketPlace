// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IArcGovernance {
    function getRoleAddress(uint256 roleId) external view returns (address);
    function swapRouter() external view returns (address);
}