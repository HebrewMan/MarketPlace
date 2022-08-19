// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAirdropFactory {

    function createAirdropContract() external returns (address);

    event CreateAirdropContract(address indexed contractAddress);
}