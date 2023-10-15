// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import "hardhat/console.sol";

contract MarketPlace is ERC1155Holder {

    uint public batchListedCount;
    uint public batchIdIndex;
    uint public priceOfanItem;

    uint[] public batchItemsIds;
    uint[] public batchItemsValues;

    uint totalListedItems;

    // uint[] public batchItemsIds = new uint256[](10);
    // uint[] public batchItemsValues = new uint256[](10);

    mapping(uint => bool) public itemSold;

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

// DIkat yha pe hai
        if (batchIdIndex < 10) {
            batchIdIndex++;
        } else {
            if (batchIdIndex >= 10) {
                batchIdIndex = 0;
            }
            batchIdIndex++;
        }

        Batch storage batch = batchs[_batchId];
        require(_batchId > 0 && _batchId <= batchListedCount, "Item doesn't exist");

        priceOfanItem = batch.batchPrice/ 10;
        batch.seller.transfer(batch.batchPrice/ 10);

        batch.nft.safeTransferFrom(address(this), msg.sender, batch.batchItemsIds[batchIdIndex - 1], batch.batchItemsValues[batchIdIndex - 1], "");
        emit Bought(
            _batchId,
            batch.batchItemsIds[batchIdIndex - 1],
            address(batch.nft),
            batchListedCount,
            priceOfanItem,
            batch.seller,
            msg.sender
        );

    }
}
