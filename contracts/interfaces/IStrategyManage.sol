// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStrategyManage {
    function addStrategist(address _strategist)external;
    function deleteStrategist(address _strategist)external;
    function checkAccess (address _addr) external returns(bool);
}
