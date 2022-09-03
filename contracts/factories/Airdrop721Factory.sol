// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAirdropFactory.sol";
import "../libraries/Clones.sol";
import "../templates/Airdrop721Template.sol";
import "../ArcGuarder.sol";

contract Airdrop721Factory is IAirdropFactory,ArcGuarder{

    address[] public airdrops;

    uint public length;

    function createAirdropContract() external whenNotPaused returns (address) {
        bytes memory codeBytes = type(Airdrop721Template).creationCode;
        address instance = Clones.cloneByBytes(codeBytes);
        Airdrop721Template(instance).init(msg.sender);

        airdrops.push(instance);
        length++;

        emit CreateAirdropContract(instance);

        return instance;
    }

}
