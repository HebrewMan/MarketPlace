// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IStrategyConfig.sol";
import "./interfaces/IOrderManage.sol";
import "./interfaces/IVault.sol";

import "./OrderType.sol";
import "hardhat/console.sol";
contract BasicTrade{

    IStrategyConfig public StrategyConfig;

    modifier onlyProxy {
        require(msg.sender == StrategyConfig.getProxyAddr(),"BasicTrade:Not Proxy!");
        _;
    }

    constructor(IStrategyConfig _StrategyConfig){
        StrategyConfig = _StrategyConfig;
    }

    function add(address _nft,address _payment,uint _tokenId,uint _amount,uint _price,uint _endAt) external onlyProxy{
        IOrderManage(StrategyConfig.getOrdersAddr()).addOrder(address(this),tx.origin, _nft, _payment, _tokenId, _amount, _price, _endAt);
        IVault(StrategyConfig.getVaultAddr()).receiverNFT(_nft,_tokenId,_amount);//Before that seller must be approve to vault contract;
    }

    function cancel(uint _orderId) external onlyProxy{
        OrderType memory _Order = IOrderManage(StrategyConfig.getOrdersAddr()).getOrder(_orderId);

        IOrderManage(StrategyConfig.getOrdersAddr()).cancelOrder(_orderId);
        IVault(StrategyConfig.getVaultAddr()).withdrawNFT(_Order.nft,_Order.tokenId,_Order.amount);
    }

    function buy(uint _orderId,uint _amount) external onlyProxy{
        OrderType memory _Order = IOrderManage(StrategyConfig.getOrdersAddr()).getOrder(_orderId);
        IOrderManage(StrategyConfig.getOrdersAddr()).buyOrder(_orderId,_amount);//update orders

        //check
        IERC20 ERC20 = IERC20(_Order.payment);
        require(ERC20.balanceOf(tx.origin) >= _Order.price*_amount,"BasicTrade:Insufficient balance");

        uint vaultFee;
        if(StrategyConfig.getFee()>0){
            vaultFee = _Order.price * _amount * StrategyConfig.getFee()/1000;
        }else{
            vaultFee = 0;
        }
        uint sellerFee = _Order.price * _amount - vaultFee;

        ERC20.transferFrom(tx.origin,StrategyConfig.getVaultAddr(),vaultFee);
        ERC20.transferFrom(tx.origin,_Order.seller,sellerFee);

        IVault(StrategyConfig.getVaultAddr()).withdrawNFT(_Order.nft,_Order.tokenId,_amount);
    }

    function bid(uint _orderId,uint _amount)external {}

}
