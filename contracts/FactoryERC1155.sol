// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC1155Token.sol";

contract FactoryERC1155 {

    ERC1155Token[] public tokens; //an array that contains different ERC1155 tokens deployed
    mapping(uint256 => address) public indexToContract; //index to contract address mapping
    mapping(uint256 => address) public indexToOwner; //index to ERC1155 owner address

    event ERC1155Created(address owner, address tokenContract); //emitted when ERC1155 token is deployed
    event ERC1155Minted(address owner, address tokenContract, uint amount); //emitted when ERC1155 token is minted
    event RetailerAdded(address tokenContract, string retailerName, uint tokenId); //emitted when retailer is added to token

    /*
    deployERC1155 - deploys a ERC1155 token with given parameters - returns deployed address

    _contractName - name of our ERC1155 token
    _uri - URI resolving to our hosted metadata
    _ids - IDs the ERC1155 token should contain
    _name - Names each ID should map to. Case-sensitive.
    */
    function deployERC1155(string memory _contractName, string memory _uri, uint[] memory _ids, string[] memory _names) public returns (address) {
        ERC1155Token t = new ERC1155Token(_contractName, _uri, _names, _ids);
        tokens.push(t);
        indexToContract[tokens.length - 1] = address(t);
        indexToOwner[tokens.length - 1] = tx.origin;
        emit ERC1155Created(msg.sender,address(t));
        return address(t);
    }

    /*
    mintERC1155 - mints a ERC1155 token with given parameters

    _index - index position in our tokens array - represents which ERC1155 you want to interact with
    _name - Case-sensitive. Name of the token (this maps to the ID you created when deploying the token)
    _amount - amount of tokens you wish to mint
    */
    function mintERC1155(uint _index, string memory _name, uint256 amount, string memory _metadata) public {

        uint id = getIdByName(_index, _name);
        tokens[_index].mint(indexToOwner[_index], id, amount, _metadata);
        emit ERC1155Minted(tokens[_index].owner(), address(tokens[_index]), amount);
    }

    /*
    addRetailer - adds a retailer with given parameters

    _index - index position in our tokens array - represents which ERC1155 you want to interact with
    _retailerName - retailer name which will be added to names array in token's contract
    _tokenid - token id which is to be associated with the retailer, which will be added to ids array in token's contract
    */
   function addRetailer(uint _index, string memory _retailerName, uint256 _tokenid) public {
    tokens[_index].addRetailer(_retailerName, _tokenid);
    emit RetailerAdded(address(tokens[_index]), _retailerName, _tokenid);
   }

    /*
    Helper functions below retrieve contract data given an ID or name and index in the tokens array.
    */
    // function getCountERC1155byIndex(uint256 _index, uint256 _id) public view returns (uint amount) {
    //     return tokens[_index].balanceOf(indexToOwner[_index], _id);
    // }

    // function getCountERC1155byName(uint256 _index, string calldata _name) public view returns (uint amount) {
    //     uint id = getIdByName(_index, _name);
    //     return tokens[_index].balanceOf(indexToOwner[_index], id);
    // }

    function getIdByName(uint _index, string memory _name) public view returns (uint) {
        return tokens[_index].nameToId(_name);
    }

    function getNameById(uint _index, uint _id) public view returns (string memory) {
        return tokens[_index].idToName(_id);
    }

    // function getERC1155byIndexAndId(uint _index, uint _id)
    //     public
    //     view
    //     returns (
    //         address _contract,
    //         address _owner,
    //         string memory _uri,
    //         uint supply
    //     )
    // {
    //     ERC1155Token token = tokens[_index];
    //     return (address(token), token.owner(), token.uri(_id), token.balanceOf(indexToOwner[_index], _id));
    // }
}