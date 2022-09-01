// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IArcGovernance {
    function master() external view returns (address);
    function cashier() external view returns (address);
    function system() external view returns (address);
    function swapRouter() external view returns (address);
}