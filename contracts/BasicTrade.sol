// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IStrategyTrade.sol";
import "./interfaces/IStrategyConfig.sol";
import "./interfaces/IOrderManage.sol";
import "./interfaces/IVault.sol";

import "./OrderType.sol";

abstract contract BasicTrade is IStrategyTrade{

    IStrategyConfig StrategyConfig;

    uint public fee = StrategyConfig.getFee();
    address public vaultAddr = StrategyConfig.getVaultAddr();
    address public ordersAddr = StrategyConfig.getOrdersAddr();
    address public proxyAddr = StrategyConfig.getProxyAddr();

    modifier onlyProxy {
        require(msg.sender == StrategyConfig.getProxyAddr());
        _;
    }

    constructor(IStrategyConfig _StrategyConfig){
        StrategyConfig = _StrategyConfig;
    }

    function add(address _strategy,address _nft,address _payment,uint _tokenId,uint _amount,uint _price,uint _endAt) external onlyProxy{
        IOrderManage(ordersAddr).addOrder(_strategy, msg.sender, _nft, _payment, _tokenId, _amount, _price, _endAt);
        IVault(vaultAddr).receiverNFT(_nft,_tokenId,_amount);//Before that seller must be approve to vault contract;
    }

    function cancel(uint _orderId) external onlyProxy{
        OrderType memory _Order = IOrderManage(ordersAddr).getOrder(_orderId);

        IOrderManage(ordersAddr).cancelOrder(_orderId);
        IVault(vaultAddr).withdrawNFT(_Order.nft,_Order.tokenId,_Order.amount);
    }

    function buy(uint _orderId,uint _amount) external onlyProxy{
        OrderType memory _Order = IOrderManage(ordersAddr).getOrder(_orderId);
        IOrderManage(ordersAddr).buyOrder(_orderId,_amount);//update orders

        //check
        IERC20 ERC20 = IERC20(_Order.payment);
        require(ERC20.balanceOf(msg.sender)>=_Order.price*_amount,"BasicTrade:Insufficient balance");

        uint vaultFee = _Order.price * fee/1000;
        uint sellerFee = _Order.price * _amount - vaultFee;

        ERC20.transferFrom(msg.sender,vaultAddr,vaultFee);
        ERC20.transferFrom(msg.sender,_Order.seller,sellerFee);

        IVault(StrategyConfig.getVaultAddr()).withdrawNFT(_Order.nft,_Order.tokenId,_amount);
    }

    function bid(uint _orderId,uint _amount)external {}

}
