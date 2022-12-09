// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "./interfaces/IOrderManage.sol";
import "./interfaces/IStrategyManage.sol";
//This contract only owner(proxy contract) can call.
import "hardhat/console.sol";
contract OrdersManage is IOrderManage{

    uint public currentId;

    mapping (uint => OrderType) public Orders;

    IStrategyManage StrategyManage;

    event AddOrder(address _strategy,address _seller,address _nft,address _payment,uint _tokenId,uint _amount,uint _price,uint _endAt,uint _orderId);
    event BuyOrder(address _buyer,uint _orderId,uint _amount);
    event CancelOrder(uint _orderId);
    event BidOrder(uint _orderId);
    event CancelBid(uint _orderId);

    constructor(IStrategyManage _StrategyManage){
        StrategyManage = _StrategyManage;
    }

    modifier isExist(uint _id) {
        require(Orders[_id].seller != address(0),"OrdersManage:Not existed!");
        _;
    }

    modifier onlyStrategists{
        require(StrategyManage.checkAccess(msg.sender),"OrdersManage:No access!");
        _;
    }

    /**
     * @dev Access modifier for cashier only functionality
     */
   
    function addOrder(address _strategy,address _seller,address _nft,address _payment,uint _tokenId,uint _amount,uint _price,uint _endAt)external onlyStrategists{
        currentId++;
        OrderType storage Order = Orders[currentId];
        Order.strategy = _strategy;
        Order.seller = _seller;
        Order.nft = _nft;
        Order.payment = _payment;
        Order.tokenId = _tokenId;
        Order.amount = _amount;
        Order.price = _price;
        Order.endAt = _endAt;
        emit AddOrder(_strategy, _seller,_nft, _payment, _tokenId, _amount, _price, _endAt,currentId);
    }
    function buyOrder(uint _orderId,uint _amount)external isExist(_orderId) onlyStrategists{
        OrderType storage Order = Orders[_orderId];
        require(_amount<=Order.amount,"OrdersManage:Params error!");
        //check is it expired
        if( block.timestamp > Order.endAt && Order.endAt>0){
            revert("OrdersManage:This order has expired!");
        }
        Order.amount -= _amount;
        emit BuyOrder(tx.origin,_orderId,_amount);
    }

    function getOrder(uint _orderId)external view returns(OrderType memory){
        return Orders[_orderId];
    }

    function cancelOrder(uint _orderId)external onlyStrategists isExist(_orderId){
        require(tx.origin == Orders[_orderId].seller,"OrdersManage:Not seller!");
        delete (Orders[_orderId]);
        emit CancelOrder(_orderId);
    }


}