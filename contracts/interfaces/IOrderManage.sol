// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../OrderType.sol";
interface IOrderManage{
    function getOrder(uint _orderId) external view returns (OrderType memory);
    function addOrder(address _strategy,address _seller,address _nft,address _payment,uint _tokenId,uint _amount,uint _price,uint _endAt) external;
    function buyOrder(uint _orderId,uint _amount) external;
    function cancelOrder(uint _orderId) external;
}