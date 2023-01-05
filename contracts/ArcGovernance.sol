// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IArcGovernance.sol";

contract ArcGovernance is IArcGovernance {

    /**
     * @dev swap router account address.
     */
    address private _swapRouter;

    /**
     * @dev roleId => role address
     * master => 1  Master(CEO) account address.
     * cashier => 2  Cashier(CFO) account address.
     * system => 3 System account address.
     */
    mapping(uint256 => address) private roles;

    /**
     * @dev Initialize system address. Default value is deploy account address
     */
    constructor(address masterAddress, address cashierAddress) {

        roles[1] = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
        roles[2] = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;

        if (masterAddress != address(0)) roles[1] = masterAddress;
        if (cashierAddress != address(0)) roles[2] = cashierAddress;
        roles[3] = msg.sender;
    }

    /**
     * @dev Access modifier for master-only functionality
     */
    modifier onlyMaster() {
        require(roles[1] == msg.sender, "ARC:ONLY_MASTER");
        _;
    }

    /**
     * @dev Returns the address of the master.
     */
    function master() public view returns (address) {
        return roles[1];
    }

    /**
     * @dev Returns the address of the system.
     */
    function system() public view returns (address) {
        return roles[3];
    }

    /**
     * @dev Returns the address of the cashier.
     * @return address
     */
    function cashier() public view returns (address) {
        return roles[2];
    }

    /**
     * @dev Returns the address of the swap router.
     * @return address
     */
    function swapRouter() public view returns (address) {
        return _swapRouter;
    }

    /**
     * @dev set system account
     * @param account_ address
     */
    function setSwapRouter(address account_) public onlyMaster {
        require(account_ != address(0), "ARC:ZERO_ADDR");
        _swapRouter = account_;
    }
    
    /**
     * @dev set role 
     * @param roleId roleId
     * @param account_ address
     */
    function setRole(uint256 roleId, address account_) public onlyMaster {
         require(roleId > 0 && account_ != address(0), "ARC:ZERO_PARAMS");
         roles[roleId] = account_;
    }

    /**
     * @dev Returns the address of the swap router.
     * @return roleId
     */
    function getRoleAddress(uint256 roleId) public view returns (address) {
        require(roleId > 0, "ARC:ZEROID");
        return roles[roleId];
    }
}
