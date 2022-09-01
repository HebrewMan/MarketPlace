// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAirdropFactory.sol";
import "../libraries/Clones.sol";
import "../templates/Airdrop20Template.sol";
import "../ArcGuarder.sol";

contract Airdrop20Factory is IAirdropFactory, ArcGuarder {
    address[] public airdrops;

    uint public length;

    function createAirdropContract()
        public
        whenNotPaused
        returns (address)
    {
        bytes memory codeBytes = type(Airdrop20Template).creationCode;
        address instance = Clones.cloneByBytes(codeBytes);
        Airdrop20Template(instance).init(msg.sender);

        airdrops.push(instance);
        length++;

        emit CreateAirdropContract(instance);

        return instance;
    }
}
