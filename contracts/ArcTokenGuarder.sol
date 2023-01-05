// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./ArcGuarder.sol";
import "./Receiver.sol";

contract ArcTokenGuarder is ArcGuarder, Receiver {


    /**
     * @dev In case of accident or emergency, transfer the ERC20 assets of this contract.emergency only!
     * @param token ERC20 token address of the asset to be migrated
     */

    function emergencyMigrateAsset(address token) public onlyRole(2) {
        uint256 _balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(msg.sender, _balance);
    }

    /**
     * @dev In case of accident or emergency, transfer the ETH assets of this contract.emergency only!
     */
    function emergencyMigrateAssetETH() public onlyRole(2) {
        uint256 balance = address(this).balance;
        (bool sent,) = payable(msg.sender).call{value: balance}("");
        require(sent, "Failed to send Ether");
    }

    function emergencyMigrateAssetNFT(address _nft,uint _tokenId) external onlyRole(2){
        string memory _type = verifyByAddress(_nft);
        uint256 _balance = IERC1155(_nft).balanceOf(address(this), _tokenId);

        if(keccak256(abi.encodePacked("1155")) == keccak256(abi.encodePacked(_type))){
            IERC1155(_nft).safeTransferFrom(address(this),msg.sender,_tokenId,_balance,"");
        }else{
            IERC721(_nft).safeTransferFrom(address(this),msg.sender,_tokenId,"");
        }

    }

      function verifyByAddress(address _address) public view returns(string memory contractType ){
        
        try IERC721(_address).supportsInterface(type(IERC721).interfaceId){
            if(IERC721(_address).supportsInterface(type(IERC721).interfaceId)){
                return "721";
            }else if(IERC1155(_address).supportsInterface(type(IERC1155).interfaceId)){
                return "1155";
            }
        } catch (bytes memory) {
            return "20";
        }
        
    }

    receive() external payable {}
}