// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IArcGovernance.sol";
import "./factories/ArcPause.sol";

contract ArcGuarder is ArcPause {

    function governance() public view returns (address) {
        return _governance;
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
        _governance = addr;
    }
}
