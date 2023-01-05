
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
//This contract only owner(proxy contract) can call.
import "./ArcGuarder.sol";

contract StrategyManage is ArcGuarder{

    mapping (address => bool) public accessAddr;

    function addStrategist(address _addr)external virtual onlyRole(1){
        accessAddr[_addr] = true;
    }

    function deleteStrategist(address _addr)external virtual onlyRole(1){
        accessAddr[_addr] = false;
    }

    function checkAccess(address _addr)external view virtual returns(bool){
        return accessAddr[_addr];
    }
}