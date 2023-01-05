// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStrategyTrade{
    
    function add(address _nft,address _payment,uint _tokenId,uint _amount,uint _price,uint _endAt)external;
    function buy(uint _orderId,uint _amount) external;
    function cancel(uint _orderId) external;//seller cancel and buyer cancel
    function bid(uint _orderId,uint _amount)external;
}