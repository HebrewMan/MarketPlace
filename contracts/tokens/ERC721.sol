// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MyToken721 is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable{
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
     // Base URI
    string public baseURIextended;

    constructor(string memory _name,string memory _stymbol,string memory __baseURI) ERC721(_name,_stymbol) {
        baseURIextended = __baseURI;
    }

    function setBaseURI(string memory __baseURI)external onlyOwner{
        baseURIextended = __baseURI;
    }

    function setTokenURI(uint256 _tokenId, string memory _tokenURI)external onlyOwner {
        _setTokenURI(_tokenId,_tokenURI);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURIextended;
    }

    function safeMint(address to) public {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(to, tokenId);
            string memory tokenIdUri = string(abi.encodePacked(Strings.toString(tokenId), ".json"));
           _setTokenURI(tokenId, tokenIdUri);
    }

    function currentTokenId()external view returns(uint){
        return _tokenIdCounter.current();
    }

    // The following functions are overrides required by Solidity.
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}