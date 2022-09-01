// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IArcGovernance.sol";

contract ArcPause {

    //address _governance;
    address internal _governance = address(0x182Bf190C46D0095aE0567E57156AdB05d182474);

    /**
     * @dev State of pause
     */
    bool internal paused = false;

    /**
     * @dev Access modifier for cashier only functionality
     */
    modifier onlyRole(uint roleId) {
        require(
            IArcGovernance(_governance).getRoleAddress(roleId) == msg.sender,
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

}