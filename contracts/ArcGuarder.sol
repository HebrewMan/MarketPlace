// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IArcGovernance.sol";

contract ArcGuarder {

    //address governance;
    address public governance = address(0x2c7F56B4b78355C5D898dafc8a39bcC7c6bE7EF3);

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
     * @dev Modifier to allow actions only when the contract IS NOT paused
     */
    modifier whenNotPaused() {
        require(!paused, "ARC:PAUSED");
        _;
    }

    /**
     * @dev Modifier to allow actions only when the contract IS paused
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

     /**
     * @dev Called by any woner role to pause the contract. Used only when
     *  a bug or exploit is detected and we need to limit damage.
     */
    function pause() public onlyRole(2) whenNotPaused {
        paused = true;
    }

    /**
     * @dev Unpauses the smart contract. Can only be called by the Owner, since
     *  one reason we may pause the contract is when CFO or COO accounts are compromised.
     * @notice This is public rather than external so it can be called by derived contracts.
     */
    function unpaused() public onlyRole(2) whenPaused {
        paused = false;
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
