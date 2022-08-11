//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract ERC721Template is ERC721("ERC721Template", "ERC721T"), Ownable, ERC721URIStorage { 
    
    bool initialized = false;
    string private _name;
    string private _symbol;
    // initialize the template
    function initialize(string memory name_, string memory symbol_, address _owner, string memory _uri) public {
        require(!initialized, "Already initialized");

        _name = name_;
        _symbol = symbol_;
        _setOwner(_owner);
        
        _safeMint(_owner, 1);
        _setTokenURI(1, _uri);

        initialized = true;

    }

    function _setOwner(address _owner) private {
        _transferOwnership(_owner);
    }

    // here are the funtions that need to be overwritten

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

}
