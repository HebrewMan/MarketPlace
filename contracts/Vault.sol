// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "./ArcTokenGuarder.sol";
import "./interfaces/IStrategyManage.sol";
import "hardhat/console.sol";
contract Vault is ArcTokenGuarder{

    bool public paused;

    IStrategyManage StrategyManage;

    constructor(IStrategyManage _StrategyManage){
        StrategyManage = _StrategyManage;
    }

    modifier isNotPaused {
        require(!paused,"Vault:Paused is true");
        _;
    }

    modifier onlyStrategists{
        require(StrategyManage.checkAccess(msg.sender),"Vault:No access");
        _;
    }

    function setPaused(bool _pause)external onlyRole(1){
        paused = _pause;
    }

    /**
     * dev
     * user can call this function to withdraw they's assets of deposited this vault
     */
    function withdraw(address _token,uint _amount) external onlyStrategists isNotPaused{
        require(IERC20(_token).balanceOf(address(this))>=_amount,"Vault:Insufficient balance");
        IERC20(_token).transfer(tx.origin, _amount);
    }

    function withdrawNFT(address _nft,uint _tokenId,uint _amount) external onlyStrategists isNotPaused{
        require(IERC1155(_nft).balanceOf(address(this),_tokenId)>=_amount,"Vault:Insufficient balance");
        string memory _type = verifyByAddress(_nft);
        if(keccak256(abi.encodePacked("1155")) == keccak256(abi.encodePacked(_type))){
            IERC1155(_nft).safeTransferFrom(address(this),tx.origin,_tokenId,_amount,"0x");
        }else{
            IERC721(_nft).safeTransferFrom(address(this),tx.origin,_tokenId,"0x");
        }
    }

    function receiver(address _token,uint _amount) external onlyStrategists isNotPaused{
        require(IERC20(_token).balanceOf(tx.origin) >= _amount,"Vault:Insufficient balance");
        IERC20(_token).transferFrom(tx.origin, address(this),_amount);
    }

    function receiverNFT(address _nft,uint _tokenId,uint _amount) external onlyStrategists isNotPaused{
        require(IERC1155(_nft).balanceOf(tx.origin,_tokenId)>=_amount,"Vault:Insufficient balance");
        string memory _type = verifyByAddress(_nft);

        if(keccak256(abi.encodePacked("1155")) == keccak256(abi.encodePacked(_type))){
            IERC1155(_nft).safeTransferFrom(tx.origin,address(this),_tokenId,_amount,"0x");
        }else{
            IERC721(_nft).safeTransferFrom(tx.origin,address(this),_tokenId,"0x");
        }
    }

}