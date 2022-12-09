// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "./ArcGuarder.sol";
contract StrategyConfig is ArcGuarder{
    uint public fee = 3;

    address public vaultAddr; 
    address public ordersAddr;
    address public proxyAddr;

    event SetFee(uint _fee);
    event SetVaultAddr(address _addr);
    event SetOrdersAddr(address _addr);
    event SetProxyAddr(address _addr);

    constructor(address _vaultAddr,address _ordersAddr,address _proxyAddr){
        vaultAddr = _vaultAddr;
        ordersAddr = _ordersAddr;
        proxyAddr = _proxyAddr;
    }

    function setFee(uint _fee)public  onlyRole(1){
        fee = _fee;
        emit SetFee(_fee);
    }

    function setVaultAddr(address _addr)public  onlyRole(1){
        vaultAddr = _addr;
        emit SetVaultAddr(_addr);
    }

    function setOrdersAddr(address _addr)public  onlyRole(1){
        ordersAddr = _addr;
        emit SetOrdersAddr(_addr);
    }

    function setProxyAddr(address _addr)public  onlyRole(1){
        proxyAddr = _addr;
        emit SetProxyAddr(_addr);
    }
}