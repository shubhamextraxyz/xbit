// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract NFT is ERC1155{

    string public name;
    string public symbol;
    string public baseURI;

    // This will also work

    // uint256[] public ids = new uint256[](10);
    // uint256[] public values = new uint256[](10);

    uint256[] public ids;
    uint256[] public values;

    uint256 public totalCount;
    uint256 public batchCount;

    constructor(string memory _name, string memory _symbol, string memory _baseURI) ERC1155(_baseURI){
        name = _name;
        symbol = _symbol;
        baseURI = _baseURI;
    }

    function mintTokens() public{

        totalCount = totalCount + 10;
        batchCount++;

        for(uint i = totalCount-9; i<=totalCount; i++){

            // This will also work
            
            // ids[i - (totalCount - 9)] = i;
            // values[i - (totalCount - 9)] = 1;

            ids.push(i);
            values.push(1);
        }

        _mintBatch(msg.sender, ids, values, "");
    }


    function totalSupply() public view returns (uint256){
        return totalCount;
    }

    
}

