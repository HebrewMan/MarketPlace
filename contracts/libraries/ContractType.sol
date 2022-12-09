
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "hardhat/console.sol";

library ContractType {
    
    function verifyByAddress(address _address) public returns(string memory contractType ){
        
        /*
        if(IERC721(_address).supportsInterface(type(IERC721).interfaceId)){
            return "721";
        }else if(IERC1155(_address).supportsInterface(type(IERC1155).interfaceId)){
            return "1155";
        }else {
            return "20";
        */
        
        /*
        try IERC721(_address).supportsInterface(type(IERC721).interfaceId){
            return "721";
        } catch (bytes memory) {
            return "20";
        }
        try IERC1155(_address).supportsInterface(type(IERC1155).interfaceId){
            return "1155";
        } catch (bytes memory) {
            return "20";
        }
        */

        /*
        try IERC721(_address).supportsInterface(type(IERC721).interfaceId){
            if(IERC721(_address).supportsInterface(type(IERC721).interfaceId)){
                return "721";
            }else if(IERC1155(_address).supportsInterface(type(IERC1155).interfaceId)){
                return "1155";
            }
        } catch (bytes memory) {
            return "20";
        }
        */


        bytes memory ownerOfData =  abi.encodeWithSignature("ownerOf(uint256)",0);
        (bool success,bytes memory returnOwnerOfData) = _address.call{value: 0}(ownerOfData);
        console.log("returnOwnerOfData",success);
        if(returnOwnerOfData.length > 0){
            return "721";
        }else{
            bytes memory totalSupplyData =  abi.encodeWithSignature("totalSupply()");
            (bool success2,bytes memory returnTotalSupplyData) = _address.call{value: 0}(totalSupplyData);
            console.log("returnTotalSupplyData",success2);
            if(returnTotalSupplyData.length > 0){
                return "20";
            }else{
                return "1155";
            }       
        }
    }
}

