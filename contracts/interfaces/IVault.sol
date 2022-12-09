// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVault{
    function receiver(address _nft,uint _amount)external;
    function withdraw (address _nft,uint _amount) external;
    function receiverNFT(address _nft,uint _tokenId,uint _amount)external;
    function withdrawNFT (address _nft,uint _tokenId,uint _amount) external;
}
