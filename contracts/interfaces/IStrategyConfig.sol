// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStrategyConfig {
    function getFee() external returns (uint);

    function getVaultAddr() external returns (address);

    function getOrdersAddr() external returns (address);

    function getProxyAddr() external returns (address);

    function setFee(uint _fee)external;

    function setVaultAddr(address _addr)external;

    function setOrdersAddr(address _addr)external;

    function setProxyAddr(address _addr)external;
}
