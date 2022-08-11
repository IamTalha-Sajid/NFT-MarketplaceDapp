// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IERC721Template is IERC721{
    function initialize(string memory name_, string memory symbol_, address _owner, string memory _uri) external;
}