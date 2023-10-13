// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "hardhat/console.sol";

contract MarketPlace{

    uint public batchCount;
    uint public itemNumber;

    mapping(uint => bool) public itemSold;

    struct Batch {
        uint batchId;
        uint[] itemIds;
        uint[] itemAmounts; 
        IERC1155 nft;
        uint batchPrice;
        address payable seller;
        mapping(uint => bool) itemSoldForBatch;
    
    }

    event Offered(
        uint batchId,
        address indexed nft,
        uint batchCount,
        uint batchPrice,
        address indexed seller
    );

    event Bought(
        uint itemId,
        address indexed nft,
        uint tokenId,
        uint price,
        address indexed seller,
        address indexed buyer
    );

    // itemId -> Item
    mapping(uint => Batch) public batchs;

        // Make item to offer on the marketplace
    function makeBatch(IERC1155 _nft, uint _batchId, uint _batchprice, uint[] memory _itemIds, uint[] memory _itemAmounts) external nonReentrant {
        require(_price > 0, "Price must be greater than zero");
        // increment itemCount
        batchCount ++;
        // transfer nft
        _nft.safeBatchTransferFrom(msg.sender, address(this), _itemIds, _itemAmounts, "");

        batchs[batchCount] = Batch (
            batchCount,
            _itemIds,
            _itemAmounts,
            _nft,
            _batchprice,
            msg.sender,
            false
        );

        emit Offered(
            _batchId,
            address(_nft),
            batchCount,
            _batchprice,
            msg.sender
        );
    }

    function purchaseItemFromBatch(uint _batchId) external payable nonReentrant {

        if(itemNumber<=10){
            itemNumber++;
        } else{
            itemNumber = 0;
        }
        
        itemNumber++;

        Batch storage batch = batchs[_batchId];
        require(_batchId > 0 && _batchId <= batchCount, "item doesn't exist"); 

        require(!batch.itemSoldForBatch[itemNumber], "item already sold");
        
        batch.seller.transfer(batch.batchPrice/batch.itemIds.length);
    
        batch.itemSoldForBatch[itemNumber] = true;

        batch.nft.safeTransferFrom(address(this), msg.sender, itemIds[itemNumber], itemAmounts[itemNumber], "");
        emit Bought(
            _batchId,
            itemIds[itemNumber],
            address(batch.nft),
            batchCount,
            batch.batchPrice,
            msg.sender,
            batch.seller
        );
    }


}