// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import "hardhat/console.sol";

contract MarketPlace is ERC1155Holder {

    uint public batchListedCount;
    uint public priceOfanItem;

    uint[] public batchItemsIds;
    uint[] public batchItemsValues;

    uint totalListedItems;

    // uint[] public batchItemsIds = new uint256[](10);
    // uint[] public batchItemsValues = new uint256[](10);

    mapping(uint => bool) public itemSold;
    mapping(uint => mapping(uint => uint)) public mapX;
    mapping(uint => uint) public mapY;
    mapping(uint => uint) public batchIdIndex;
    mapping (address => mapping(uint=>uint)) public isVoted;//address,batchId=>1,2->1>rent,2>sell
    mapping(address=> mapping(uint=>uint)) public buyerCnt;
    mapping(uint=> address[]) public mapz;
    mapping(uint=> uint) public voteInBatchforRent;
    mapping(uint=> uint) public voteInBatchforResell;

    struct Batch {
        uint batchId;
        uint[] batchItemsIds;
        uint[] batchItemsValues;
        IERC1155 nft;
        uint batchPrice;
        address payable seller;
    }

    event Offered(
        uint batchId,
        address indexed nft,
        uint batchListedCount,
        uint batchPrice,
        address indexed seller
    );

    event Bought(
        uint batchId,
        uint batchItemIds,
        address indexed nft,
        uint batchListedCount,
        uint priceOfanItem,
        address indexed seller,
        address indexed buyer
    );

    // itemId -> Item
    mapping(uint => Batch) public batchs;

    function makeBatch(IERC1155 _nft, uint _batchId, uint _batchprice) external {

        totalListedItems = _batchId*10;
        batchListedCount++;

        for (uint i = totalListedItems-9; i <= totalListedItems; i++) {
            batchItemsIds.push(i);
            batchItemsValues.push(1);
        }

        _nft.safeBatchTransferFrom(msg.sender, address(this), batchItemsIds, batchItemsValues, "");

        Batch storage newBatch = batchs[batchListedCount];
        newBatch.batchId = batchListedCount;
        newBatch.batchItemsIds = batchItemsIds;
        newBatch.batchItemsValues = batchItemsValues;
        newBatch.nft = _nft;
        newBatch.batchPrice = _batchprice;
        newBatch.seller = payable(msg.sender);

        emit Offered(
            _batchId,
            address(_nft),
            batchListedCount,
            _batchprice,
            msg.sender
        );
    }

    function purchaseOneItemFromBatch(uint _batchId) external payable {

        require(_batchId > 0 && _batchId <= batchListedCount, "Item doesn't exist");
        require(batchIdIndex[_batchId]<=10,"All plots sold");
        
        // Ensure that the batchIdIndex is reset when a new batch is purchased
        if (batchIdIndex[_batchId] == 0) {
            batchIdIndex[_batchId] = 1;
        } else {
            batchIdIndex[_batchId]++;
        }
        Batch storage batch = batchs[_batchId];

        // Calculate the correct item ID based on the batch ID and index
        uint itemId = (_batchId - 1) * 10 + batchIdIndex[_batchId];


        priceOfanItem = batch.batchPrice/ 10;
        batch.seller.transfer(batch.batchPrice/ 10);

        buyerCnt[msg.sender][_batchId]++;
        mapz[_batchId].push(msg.sender);

        batch.nft.safeTransferFrom(address(this), msg.sender, itemId, 1, "");
        emit Bought(
            _batchId,
            itemId,
            address(batch.nft),
            batchListedCount,
            priceOfanItem,
            batch.seller,
            msg.sender
        );

    }

    function voteforRent(uint _batchId) external{
        isVoted[msg.sender][_batchId] = 1;
    }

    function voteforSell(uint _batchId) external{
        isVoted[msg.sender][_batchId] = 2;
    }

    function finaldecison(uint _batchId){
        for(uint i =0; i< mapz[_batchId].length; i++){
            require(isVoted[mapz[_batchId][i]][_batchId]!=0, 'Not voted');
            if(isVoted[mapz[_batchId][i]][_batchId]==1){
                voteInBatchforRent[_batchId]++;
            }else{
                voteInBatchforResell[_batchId]++;
            }
        }

        if(voteInBatchforRent>=voteInBatchforResell){
            decideRentingPrice() ;
        }
    }

    function decideRentPrice(uint _batchId) returns(uint){
        Batch storage batch = batchs[_batchId];
        uint price1 = batch.batchPrice+(5*batch.batchPrice)/100;
        uint price2 = batch.batchPrice+(10*batch.batchPrice)/100;
        uint price3 = batch.batchPrice+(15*batch.batchPrice)/100;
        uint price4 = batch.batchPrice+(20*batch.batchPrice)/100;
        uint price5 = batch.batchPrice+(25*batch.batchPrice)/100;
        return price3;
    }
}
