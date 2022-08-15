// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IAirdropFactory.sol";
import "./ArcGuarder.sol";

abstract contract TokenAirdropFactory is IAirdropFactory, ArcGuarder {

    function createAirdropContract() virtual public returns (address);
}