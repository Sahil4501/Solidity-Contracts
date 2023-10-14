//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol"; //console.log equivalent for logging and debugging
import "@openzeppelin/contracts/utils/Counters.sol"; //Safe and secure implementation of counter
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol"; //set of functions/interface for storing token uri 
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFTMarketplace is ERC721URIStorage{
    address payable owner; //store owner address so that he can receive the commisions of the listing
    using Counters for Counters.Counter; // Counters.sol implementation
    Counters.Counter private _tokenIds;  // Store the counts of NFT 
    Counters.Counter private _itemsSold; // Store the number of NFT sold
    uint listPrice = 0.01 ether; //Price for listing the NFT in the marketplace which is sent to the owner of the marketplace

    constructor() ERC721("NFTMarketplace", "NFTM"){
        owner = payable(msg.sender); //Store the owner of the marketplace
    }
    struct ListedToken{
        uint tokenId;
        address payable owner;
        address payable seller;
        uint price;
        bool currentlyListed;
    }

    mapping(uint => ListedToken) private idToListedToken;

    function updateListedPrice(uint _listPrice) public payable{
        require(owner == msg.sender, "Only owner can update the listing price");
        listPrice = _listPrice;
    }
    function getListPrice() public view returns (uint){
        return listPrice;
    }
    function getLatestIdToListedToken() public view returns (ListedToken memory){
        uint currentTokenId = _tokenIds.current();
        return idToListedToken[currentTokenId];
    }
    function getListedForTokenId(uint tokenId) public view returns (ListedToken memory){
        return idToListedToken[tokenId];
    }
    function getCurrentToken() public view returns (uint){
        return _tokenIds.current();
    }

    function createToken(string memory tokenURI, uint price) public payable returns (uint){
        require(msg.value == listPrice, "Send enough ether to list");
        require(price >0, "make sure the price isnt negative");
        _tokenIds.increment();
        uint currentTokenId = _tokenIds.current();
        _safeMint(msg.sender, currentTokenId);
        _setTokenURI(currentTokenId, tokenURI);
        createListedToken(currentTokenId, price);
        return currentTokenId;
    }
    function createListedToken(uint tokenId, uint price) private{
        idToListedToken[tokenId] = ListedToken(
            tokenId,
            payable(address(this)),
            payable(msg.sender),
            price,
            true
        );
        _transfer(msg.sender, address(this), tokenId);
    }
    function getAllNFTs() public view returns(ListedToken[] memory){
        uint nftCount = _tokenIds.current();
        ListedToken[] memory tokens = new ListedToken[](nftCount);
        uint currentIndex = 0;
        for(uint i=0;i<nftCount;i++){
            uint currentId = i+1;
            ListedToken storage currentItem = idToListedToken[currentId];
            tokens[currentIndex] = currentItem;
            currentIndex += 1;
        }
        return tokens;
    }
    function getMyNFTs() public view returns(ListedToken[] memory){
        uint totalItemCount = _tokenIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;
        //Important to get a count of all the NFTs that belong to the user before we can make an array for them
        for (uint i = 0;i<totalItemCount; i++){
            if(idToListedToken[i+1].owner == msg.sender || idToListedToken[i+1].seller == msg.sender){
                itemCount += 1;
            }
        }
        //Once you have the count of relevent NFTs, create an array then store all the NFTs in it
        ListedToken[] memory items = new ListedToken[](itemCount);
        for (uint i=0; i<totalItemCount; i++){
            if(idToListedToken[i+1].owner == msg.sender || idToListedToken[i+1].seller == msg.sender){
                uint currentId = i+1;
                ListedToken storage currentItem = idToListedToken[currentId];
                items[currentIndex] = currentItem;
                currentIndex +=1;
            }
        }
        return items;
    }
    function executeSale(uint tokenId) public payable{
        uint price = idToListedToken[tokenId].price;
        require(msg.value == price, "Please submit the asking price for the NFT in order to purcahse");
        address seller = idToListedToken[tokenId].seller;
        idToListedToken[tokenId].currentlyListed = true;
        idToListedToken[tokenId].seller = payable(msg.sender);
        _itemsSold.increment();
        _transfer(address(this), msg.sender, tokenId);
        approve(address(this), tokenId);
        payable(owner).transfer(listPrice);
        payable(seller).transfer(msg.value);
    }
}