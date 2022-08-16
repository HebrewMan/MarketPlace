// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IArcGovernance.sol";

contract ArcGuarder {
    /**
     * @dev Governance's contract address
     */
    //address _governance;
    address _governance = address(0x182Bf190C46D0095aE0567E57156AdB05d182474);

    /**
     * @dev State of pause
     */
    bool internal paused = false;

    /**
     * @dev Access modifier for cashier only functionality
     */
    modifier onlyCashier() {
        require(
            IArcGovernance(_governance).cashier() == msg.sender,
            "ARC:Denied"
        );
        _;
    }

    /**
     * @dev Access modifier for master only functionality
     */
    modifier onlyMaster() {
        require(
            IArcGovernance(_governance).master() == msg.sender,
            "ARC:Denied"
        );
        _;
    }

    /**
     * @dev Access modifier for system only functionality
     */
    modifier onlySystem() {
        require(
            IArcGovernance(_governance).system() == msg.sender,
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
     * @dev Returns the address of the governance.
     * @return address
     */
    function governance() public view returns (address) {
        return _governance;
    }

    /**
     * @dev Called by any woner role to pause the contract. Used only when
     *  a bug or exploit is detected and we need to limit damage.
     */
    function pause() public onlySystem whenNotPaused {
        paused = true;
    }

    /**
     * @dev Unpauses the smart contract. Can only be called by the Owner, since
     *  one reason we may pause the contract is when CFO or COO accounts are compromised.
     * @notice This is public rather than external so it can be called by derived contracts.
     */
    function unpaused() public onlySystem whenPaused {
        paused = false;
    }

    /**
     * @dev an public method to set manager contract with permission. master only!
     * @param addr address
     */
    function setGovernance(address addr) public onlyMaster {
        _setGovernance(addr);
    }

    /**
     * @dev an internal method to set manager contract without permission. it can be override
     * @param addr address
     */
    function _setGovernance(address addr) internal {
        require(addr != address(0), "ARC:ADDR0");
        require(IArcGovernance(addr).master() != address(0), "ARC:ADDR0");
        _governance = addr;
    }
}
