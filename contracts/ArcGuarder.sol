// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./interfaces/IArcGovernance.sol";
import "hardhat/console.sol";
contract ArcGuarder {

    //test 0xd8152729FAfD176Ba76df3B3d07f1982ACF4cF18
    //main 0x7427D5cA662f6c2e43cE0530BDcc7E82a0db06b7
    //hardhat 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
    address public governance = 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0;

    /**
     * @dev Access modifier for cashier only functionality
     */
    modifier onlyRole(uint roleId) {
        require(
            IArcGovernance(governance).getRoleAddress(roleId) == msg.sender,
            "ArcGuarder:Denied"
        );
        _;
    }
    /**
     * @dev an public method to set manager contract with permission. master only!
     * @param addr address
     */
    function setGovernance(address addr) public onlyRole(1) {
        require(addr != address(0), "ArcGuarder:Address 0");
        governance = addr;
    }
   
}
