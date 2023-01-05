// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "./ArcGuarder.sol";
contract StrategyConfig is ArcGuarder{
    
    uint internal fee;
    address internal vaultAddr; 
    address internal ordersAddr;
    address internal proxyAddr;

    event SetFee(uint _fee);
    event SetVaultAddr(address indexed _addr);
    event SetOrdersAddr(address indexed _addr);
    event SetProxyAddr(address indexed _addr);

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


    function getFee() external view returns (uint){
        return fee;
    }

    function getVaultAddr() external view returns (address){
        return vaultAddr;
    }

    function getOrdersAddr() external view returns (address){
        return ordersAddr;
    }

    function getProxyAddr() external view returns (address){
        return proxyAddr;
    }
}