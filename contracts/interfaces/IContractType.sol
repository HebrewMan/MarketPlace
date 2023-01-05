// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IContractType {
    function verifyByAddress(address _address) external view returns (string memory);
}