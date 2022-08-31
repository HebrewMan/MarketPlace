// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAirdropFactory.sol";
import "../ArcGuarder.sol";
import "../libraries/Clones.sol";
import "../templates/Airdrop1155Template.sol";

contract Airdrop1155Factory is IAirdropFactory, ArcGuarder {
    address[] public airdrops;

    function createAirdropContract()
        public
        whenNotPaused
        returns (address)
    {
        bytes memory codeBytes = type(Airdrop1155Template).creationCode;

        address instance = Clones.cloneByBytes(codeBytes);

        Airdrop1155Template(instance).init(msg.sender);

        airdrops.push(instance);

        emit CreateAirdropContract(instance);

        return instance;
    }

    /**
     * @dev Get the number of airdrop contracts.
     */
    function airdropsLength() public view returns (uint256) {
        return airdrops.length;
    }
}
