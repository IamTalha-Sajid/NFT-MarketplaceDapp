// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IERC721Template.sol";
import "./interfaces/IERC721CollectionTemplate.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

contract NFTMarket is Ownable {
    uint256 maxRoyaltyPercentage;
    uint256 ownerPercentage;
    address payable ownerFeesAccount;

    // ENUM
    enum TemplateType {
        ERC721,
        ERC721Collection
    }

    // STRUCTS
    struct Template {
        address templateAddress;
        bool isActive;
        TemplateType templateType;
    }

    struct listingFixPrice {
        uint256 price;
        address seller;
    }

    struct nft {
        address erc721;
        uint256 tokenId;
        address creator;
    }

    struct royalty {
        address payable creator;
        uint256 percentageRoyalty;
    }

    //Constructor
    constructor() {}

    //Events
    event nftCreated(
        address indexed erc721,
        address indexed tokenId,
        address creator
    );
    event tokenListedFixPrice(
        address indexed seller,
        uint256 indexed tokenId,
        uint256 indexed price
    );
    event tokenUnlistedFixPrice(
        address indexed seller,
        uint256 indexed tokenId
    );
    event nftBoughtFixPrice(
        address indexed buyer,
        uint256 indexed tokenId,
        uint256 indexed price
    );

    //Mappings
    mapping(address => mapping(uint256 => listingFixPrice)) listingFixPrices;
    mapping(address => mapping(uint256 => royalty)) royalties;
    mapping(address => mapping(uint256 => nft)) nfts;
    mapping(address => uint256) balanceOf;
    mapping(uint256 => Template) public templates;

    function createTemplate(
        TemplateType _type,
        address _template,
        uint256 _index
    ) public onlyOwner {
        require(
            templates[_index].templateAddress == address(0),
            "Template already exists"
        );

        templates[_index] = Template({
            templateAddress: _template,
            isActive: true,
            templateType: _type
        });
    }

    function removeTemplate(uint256 _index) public onlyOwner {
        require(
            templates[_index].templateAddress != address(0),
            "Template does not exist"
        );

        delete templates[_index];
    }

    function changeTemplateStatus(uint256 _index, bool _status)
        public
        onlyOwner
    {
        require(
            templates[_index].templateAddress != address(0),
            "Template does not exist"
        );

        templates[_index].isActive = _status;

    }

    function createNft(
        uint256 _ERC721TemplateIndex,
        string memory _name,
        string memory _symbol,
        string memory _uri,
        uint256 _royalty
    )
        public
    {
        require(
            _royalty <= maxRoyaltyPercentage,
            "Royalty Percentage Must Be Less Than Or Equal To Max Royalty Percentage"
        );

        require(
            templates[_ERC721TemplateIndex].templateAddress != address(0) &&
                templates[_ERC721TemplateIndex].isActive &&
                templates[_ERC721TemplateIndex].templateType ==
                TemplateType.ERC721,
            "ERC721 template does not exist or is not active"
        );

        // clone ERC721Template
        address erc721Token = Clones.clone(
            templates[_ERC721TemplateIndex].templateAddress
        );

        // initialize erc721Token
        IERC721Template(erc721Token).initialize(
            _name,
            _symbol,
            msg.sender,
            _uri
        );

        nfts[erc721Token][0] = nft(erc721Token, 0, msg.sender);
        address payable _creator = payable(msg.sender);
        royalties[erc721Token][0] = royalty(_creator , _royalty);

    }

    function createNftCollection(
        uint256 _ERC721CollectionTemplateIndex,
        string memory _name,
        string memory _symbol,
        string memory _uri,
        uint256 _royalty,
        uint256 _amount
    )
        public
    {
        require(
            _royalty <= maxRoyaltyPercentage,
            "Royalty Percentage Must Be Less Than Or Equal To Max Royalty Percentage"
        );

        require(
            templates[_ERC721CollectionTemplateIndex].templateAddress != address(0) &&
                templates[_ERC721CollectionTemplateIndex].isActive &&
                templates[_ERC721CollectionTemplateIndex].templateType ==
                TemplateType.ERC721Collection,
            "ERC721 template does not exist or is not active"
        );

        // clone ERC721Template
        address erc721CollectionToken = Clones.clone(
            templates[_ERC721CollectionTemplateIndex].templateAddress
        );

        // initialize erc721Token
        IERC721CollectionTemplate(erc721CollectionToken).initialize(
            _name,
            _symbol,
            msg.sender,
            _uri,
            _amount
        );

        for (uint256 i = 0; i < _amount; i++) {
            nfts[erc721CollectionToken][i] = nft(erc721CollectionToken, i, msg.sender);
            address payable _creator = payable(msg.sender);
            royalties[erc721CollectionToken][i] = royalty(_creator , _royalty);
        }

    }

    function getNftDetails(address _token, uint256 _tokenId)
        public
        view
        returns (address _erc721, uint256 _tokenId, address _creator)
    {
        require(
            nfts[_token][_tokenId].erc721 == _token,
            "NFT does not exist"
        );

        return (nfts[_token][_tokenId].erc721, nfts[_token][_tokenId].tokenId, nfts[_token][_tokenId].creator);
    }

    function setMaxRoyaltyPercentage(uint256 _maxRoyaltyPercentage)
        public
        onlyOwner
    {
        maxRoyaltyPercentage = _maxRoyaltyPercentage;
    }

    function setOwnerPercentage(uint256 _ownerPercentage) public onlyOwner {
        ownerPercentage = _ownerPercentage;
    }

    function setOwnerAccount(address payable _ownerFeesAccount)
        public
        onlyOwner
    {
        ownerFeesAccount = _ownerFeesAccount;
    }

    function listNftFixPrice(
        uint256 _price,
        address _token,
        uint256 _tokenId
    ) public {

        require(_token != address(0), "Token address cannot be 0");
        require(
            IERC721(_token).ownerOf(_tokenId) == msg.sender,
            "You Dont Own the Given Token"
        );
        require(_price > 0, "Price Must Be Greater Than 0");
        require(
            IERC721(_token).isApprovedForAll(msg.sender, address(this)),
            "This Contract is not Approved"
        );

        listingFixPrices[_token][_tokenId] = listingFixPrice(
            _price,
            msg.sender
        );

        emit tokenListedFixPrice(msg.sender, _tokenId, _price);
    }

    function unlistNftFixPrice(address _token, uint256 _tokenId) public {
        require(_token != address(0), "Token address cannot be 0");
        require(
            IERC721(_token).ownerOf(_tokenId) == msg.sender,
            "You Dont Own the Given Token"
        );

        delete listingFixPrices[_token][_tokenId];
        delete royalties[_token][_tokenId];
        emit tokenUnlistedFixPrice(msg.sender, _tokenId);
    }

    function buyNftFixedPrice(address _token, uint256 _tokenId) public payable {
        require(_token != address(0), "Token address cannot be 0");
        require(
            msg.value >= listingFixPrices[_token][_tokenId].price,
            "You Must Pay At Least The Price"
        );

        uint256 feesToPayOwner = (listingFixPrices[_token][_tokenId].price *
            ownerPercentage) / 100;
        uint256 royaltyToPay = (listingFixPrices[_token][_tokenId].price *
            royalties[_token][_tokenId].percentageRoyalty) / 100;
        uint256 totalPrice = msg.value - royaltyToPay - feesToPayOwner;
        IERC721(_token).safeTransferFrom(
            listingFixPrices[_token][_tokenId].seller,
            msg.sender,
            _tokenId
        );
        balanceOf[listingFixPrices[_token][_tokenId].seller] += totalPrice;
        royalties[_token][_tokenId].creator.transfer(royaltyToPay);
        ownerFeesAccount.transfer(feesToPayOwner);
        unlistNftFixPrice(_token, _tokenId);

        emit nftBoughtFixPrice(msg.sender, _tokenId, msg.value);
    }

    function withdraw(uint256 amount, address payable desAdd) public {
        require(balanceOf[msg.sender] >= amount, "Insuficient Funds");

        desAdd.transfer(amount);
        balanceOf[msg.sender] -= amount;
    }
}
