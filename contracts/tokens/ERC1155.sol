// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

contract MyToken1155 is ERC1155, Ownable, ERC1155Supply {

    string public name;
    uint256 public constant ERC721_0 = 0;
    uint256 public constant ERC721_1 = 1;
    uint256 public constant ERC721_2 = 2;
    uint256 public constant ERC20_3 = 3;
    uint256 public constant ERC20_4 = 4;

    mapping(uint256 => string) private uris;

    constructor(string memory _name) ERC1155("https://www.github.io/practice-codes/one/{id}.json") {
        name = _name;
        _mint(msg.sender, ERC721_0, 1, ""); 
        _mint(msg.sender, ERC721_1, 1, ""); 
        _mint(msg.sender, ERC721_2, 1, ""); 
        _mint(msg.sender, ERC20_3, 1000000, ""); 
        _mint(msg.sender, ERC20_4, 1000000, ""); 
    }
    
    
    function uri(uint256 _tokenId) public view  override returns (string memory) {
        return uris[_tokenId];
    }

    function setTokenUri(uint256 _tokenId,string memory _uri) public onlyOwner{
        uris[_tokenId] =  _uri;
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyOwner
    {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
