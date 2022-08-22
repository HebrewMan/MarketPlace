// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IAirdropFactory.sol";
import "./ArcGuarder.sol";
import "./libraries/Clones.sol";
import "./TokenAirdropTemplate.sol";

contract TokenAirdropFactory is IAirdropFactory, ArcGuarder {
    address[] public airdrops;

    function createAirdropContract()
        public
        whenNotPaused
        returns (address)
    {
        bytes memory codeBytes = type(TokenAirdropTemplate).creationCode;

        address instance = Clones.cloneByBytes(codeBytes);

        TokenAirdropTemplate(instance).init(msg.sender);

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
