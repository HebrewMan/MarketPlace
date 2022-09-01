// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAirdropFactory.sol";
import "../ArcGuarder.sol";
import "../libraries/Clones.sol";
import "../templates/Airdrop721Template.sol";

contract Airdrop721Factory is IAirdropFactory, ArcGuarder {

    address[] public airdrops;

    function createAirdropContract() external whenNotPaused returns (address) {
        bytes memory codeBytes = type(Airdrop721Template).creationCode;

        address instance = Clones.cloneByBytes(codeBytes);

        Airdrop721Template(instance).init(msg.sender);

        airdrops.push(instance);

        emit CreateAirdropContract(instance);

        return instance;
    }

    /**
     * @dev Get the number of airdrop contracts.
     */
    function airdropsLength() external view returns (uint256) {
        return airdrops.length;
    }
}
