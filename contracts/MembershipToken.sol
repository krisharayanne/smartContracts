// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract MembershipToken is ERC1155 {
    string public constant name = "MembershipNFT";
    // Sample Base Metadata URI: "https://ipfs.io/ipfs/bafybeihjjkwdrxxjnuwevlqtqmh3iegcadc32sio4wmo7bv2gbf34qs34a/{id}.json"
    string public baseMetadataURI; 
    address public owner;
    uint256 public tokenId = 1;
    string[] public retailerNames;
    uint256[] public tokenIds;
    mapping(uint256 => string) public tokenIdToRetailerName;
    mapping(string => uint256) public retailerNameToTokenId;

    event addedRetailer(string retailerName, uint256 tokenId);
    event mintedTokens(string retailerName, uint256 tokenId, uint256 amount, string metadataURI);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() ERC1155("") {
        owner = msg.sender;
    }

    function addRetailer(string memory _retailerName) public onlyOwner returns(uint256){
        uint256 localTokenId = tokenId;
        retailerNames.push(_retailerName);
        tokenIds.push(localTokenId);
        tokenIdToRetailerName[localTokenId] = _retailerName;
        retailerNameToTokenId[_retailerName] = localTokenId;
        tokenId += 1;
        emit addedRetailer(_retailerName, localTokenId);
        return localTokenId;
    }

    function mintTokens(string memory _retailerName, uint256 amount, string memory _uri) public onlyOwner{
        setURI(_uri);
        baseMetadataURI = _uri;
        uint256 localTokenId = retailerNameToTokenId[_retailerName];
        _mint(owner, localTokenId, amount, "");
        emit mintedTokens(_retailerName, localTokenId, amount, _uri);
    }

    function getTokenIdByRetailerName(string memory _retailerName) public view returns(uint256) {
        return retailerNameToTokenId[_retailerName];
    }

    function getRetailerNameByTokenId(uint256 _tokenId) public view returns(string memory) {
        return tokenIdToRetailerName[_tokenId];
    }

    /*
    sets our URI and makes the ERC1155 OpenSea compatible
    */
    function uri(uint256 _tokenid) override public view returns (string memory) {
        return string(
            abi.encodePacked(
                baseMetadataURI,
                Strings.toString(_tokenid),".json"
            )
        );
    }

     /*
    used to change metadata, only owner access
    */
    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

}