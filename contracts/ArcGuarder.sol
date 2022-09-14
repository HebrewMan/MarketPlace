// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IArcGovernance.sol";

contract ArcGuarder {

    //address governance;
    address public governance = address(0x7427D5cA662f6c2e43cE0530BDcc7E82a0db06b7);

    /**
     * @dev State of pause
     */
    bool internal paused = false;

    /**
     * @dev Access modifier for cashier only functionality
     */
    modifier onlyRole(uint roleId) {
        require(
            IArcGovernance(governance).getRoleAddress(roleId) == msg.sender,
            "ARC:Denied"
        );
        _;
    }
    /**
     * @dev an public method to set manager contract with permission. master only!
     * @param addr address
     */
    function setGovernance(address addr) public onlyRole(1) {
        _setGovernance(addr);
    }

    /**
     * @dev an internal method to set manager contract without permission. it can be override
     * @param addr address
     */
    function _setGovernance(address addr) internal {
        require(addr != address(0), "ARC:ADDR0");
        governance = addr;
    }
   
}
