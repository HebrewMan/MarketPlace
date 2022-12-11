// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./interfaces/IStrategyTrade.sol";
import "./interfaces/IStrategyConfig.sol";
import "./interfaces/IArcGovernance.sol";
import "./ArcGuarder.sol";
contract TradeProxy is ArcGuarder{


    //English auction and dutch auction call this function.
    function addOrder(address _strategy,address _nft,address _payment,uint _tokenId,uint _amount,uint _price,uint _endAt)external{
        IStrategyTrade(_strategy).add( _nft, _payment, _tokenId, _amount, _price, _endAt);
    }
    //English auction and dutch auction call this function.
    function buyOrder(address _strategy,uint _orderId,uint _amount)external{
        IStrategyTrade(_strategy).buy(_orderId,_amount);
    }
    //English auction and dutch auction call this function.
    function cancelOrder(address _strategy,uint _orderId)external {
        IStrategyTrade(_strategy).cancel(_orderId);
    }
    //English auction call this function.
    function bidOrder(address _strategy,uint _orderId,uint _amount)external{
        IStrategyTrade(_strategy).bid(_orderId,_amount);
    }
    //English auction call this function.
    function cancelBid(address _strategy,uint _orderId)external{
        IStrategyTrade(_strategy).cancel(_orderId);
    }

    receive() external payable {}

}
