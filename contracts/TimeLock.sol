// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

import "./ArcTokenGuarder.sol";
import "hardhat/console.sol";

contract TimeLock is Ownable ,ArcTokenGuarder{

    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;

    struct Order {
        address tokenAddr;
        uint lockAmount;
        uint startTime;
        uint endTime;
        bool isClaimed;
    }

    EnumerableSet.AddressSet private _tokens;

    //address==>Order[]
    mapping(address => Order[]) userOrders;

    //token=>lockAmount
    mapping(address => uint) tokenLockAmounts;

    event Lock(address indexed user, address indexed tokenAddr, uint value, uint time,uint index);
    event UnLock(address indexed user, address indexed tokenAddr, uint value,uint index);

    function lock(address _tokenAddr, uint _amount, uint _seconds) external{
        require(_tokenAddr != address(0), "Arc:invalid token address");
        require(_amount > 0 && _seconds > 0, "Arc:not be o");

        Order memory order = Order(_tokenAddr, _amount, block.timestamp, block.timestamp + _seconds, false);
        userOrders[msg.sender].push(order);

        tokenLockAmounts[_tokenAddr] += _amount;
        if (!EnumerableSet.contains(_tokens, _tokenAddr)) {
            EnumerableSet.add(_tokens, _tokenAddr);
        }

        IERC20(_tokenAddr).transferFrom(msg.sender, address(this), _amount);
        emit Lock(msg.sender, _tokenAddr, _amount, _seconds ,userOrders[msg.sender].length-1);
    }

    function unlock(uint _index) external{
        require(userOrders[msg.sender].length - 1 >= _index, "Arc:invalid index");
        Order storage order = userOrders[msg.sender][_index];
        require(!order.isClaimed, "claimed");
        require(block.timestamp >= order.endTime, "Arc:unlock time not reached");
        order.isClaimed = true;

        IERC20(order.tokenAddr).transfer(msg.sender, order.lockAmount);
        tokenLockAmounts[order.tokenAddr] -= order.lockAmount;
        emit UnLock(msg.sender, order.tokenAddr, order.lockAmount,_index);
    }

    function getOrders() public view returns (Order[] memory order){
        return userOrders[msg.sender];
    }

    function getUserOrderLength() public view returns (uint){
        return userOrders[msg.sender].length;
    }

    function getOrder(uint _index) public view returns (Order memory order){
        require(getUserOrderLength() > _index,"ARC:INVALID_INDEX");
        return userOrders[msg.sender][_index];
    }

    function canUnlock(uint _index) public view returns (bool){
        return block.timestamp >= userOrders[msg.sender][_index].endTime ? true : false;
    }

    function getTokens() public view returns (address[] memory){
        address[] memory tokens = new address[](getTokensLength());
        for (uint i = 0; i < getTokensLength(); i++) {
            tokens[i] = EnumerableSet.at(_tokens, i);
        }
        return tokens;
    }

    function getTokensLength() public view returns (uint){
        return EnumerableSet.length(_tokens);
    }

    function getToken(uint _index) public view returns (address){
        require(getTokensLength() > _index,"ARC:INVALID_INDEX");
        return EnumerableSet.at(_tokens, _index);
    }

    function getTokenLockAmounts(address _tokenAddr) public view returns(uint){
        return tokenLockAmounts[_tokenAddr];
    }

    function containsToken(address _tokenAddr) public view returns (bool) {
        return EnumerableSet.contains(_tokens, _tokenAddr);
    }

}