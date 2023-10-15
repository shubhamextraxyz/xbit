const {expect} = require('chai')
const { ethers } = require('hardhat')

const toWei = (num) => ethers.parseEther(num.toString())
const fromWei = (num) => ethers.formatEther(num)

describe("Marketplace", ()=>{

    let deployer, market, nft, baseUri='Sample URI', addrs, buyer

    beforeEach(async()=>{      
        const MARKET = await ethers.getContractFactory("MarketPlace")
        const NFT = await ethers.getContractFactory("NFT")

        addrs = await ethers.getSigners();
        deployer = addrs[0];
        buyer = addrs[2];

        market = await MARKET.deploy()
        await market.waitForDeployment()
        nft = await NFT.deploy('Xbit','XB',baseUri)
        await nft.waitForDeployment()
    })

    describe('Deployement',()=>{

       it('should track name and symbol of nft contract',async()=>{
            const nftName = "Xbit"
            const nftSymbol = "XB"
            expect(await nft.name()).to.equal(nftName);
            expect(await nft.symbol()).to.equal(nftSymbol);

       }) 

    })

    describe('Minting',()=>{
        it('should track each Minted Batch', async()=>{
            await nft.connect(addrs[1]).mintTokens()
            expect(await nft.batchCount()).to.equal(1);
            expect(await nft.totalCount()).to.equal(10);
            expect(await nft.balanceOf(addrs[1].address, 1)).to.equal(1);
            expect(await nft.balanceOf(addrs[1].address, 3)).to.equal(1);
            expect(await nft.balanceOf(addrs[1].address, 5)).to.equal(1);
            expect(await nft.balanceOf(addrs[1].address, 10)).to.equal(1);

            await nft.connect(addrs[2]).mintTokens()
            expect(await nft.batchCount()).to.equal(2);
            expect(await nft.totalCount()).to.equal(20);
            expect(await nft.balanceOf(addrs[2].address, 11)).to.equal(1);
            expect(await nft.balanceOf(addrs[2].address, 13)).to.equal(1);
            expect(await nft.balanceOf(addrs[2].address, 15)).to.equal(1);
            expect(await nft.balanceOf(addrs[2].address, 20)).to.equal(1);
        })
    })

    describe('Making market place item', ()=>{

        let batchPrice =2;
        let transsaction, result;

        beforeEach(async()=>{
            console.log('market address', await market.getAddress())
            console.log('sop', addrs[1].address)

            transsaction = await nft.connect(addrs[1]).mintTokens()
            result = transsaction.wait()

            transsaction = await nft.connect(addrs[1]).setApprovalForAll(await market.getAddress(), true)
            result = transsaction.wait()

            transsaction = await market.connect(addrs[1]).makeBatch(await nft.getAddress(), 1 , toWei(batchPrice))
            result = transsaction.wait()

        })
        it('should track item created in marketplace, tranfer NFT to marketplace from seller, and omit Offered event', async()=>{

            for(let i =1; i<=10; i++ ){
                expect(await nft.balanceOf(addrs[1].address,i)).to.equal(0)
                expect(await nft.balanceOf(await market.getAddress(),i)).to.equal(1)

            }

            expect(await market.batchListedCount()).to.equal(1)

            const batch = await market.batchs(1)
            expect(batch.batchId).to.equal(1)
            expect(batch.nft).to.equal(await nft.getAddress())
            expect(batch.batchPrice).to.equal(toWei(batchPrice))

            await expect(result)
            .to.emit(market, "Offered")
            .withArgs(
              1,
              await nft.getAddress(),
              1,
              toWei(batchPrice),
              addrs[1].address,
            )
            
            });

    })

    describe('Purchasing an item from batch', ()=>{
        let batchPrice = 2;
        let priceOfanItem = batchPrice/10;
        let transsaction, result;

        beforeEach(async function () {

            transsaction = await nft.connect(addrs[1]).mintTokens()
            result = transsaction.wait()

            transsaction = await nft.connect(addrs[1]).setApprovalForAll(await market.getAddress(), true)
            result = transsaction.wait()

            transsaction = await market.connect(addrs[1]).makeBatch(await nft.getAddress(), 1 , toWei(batchPrice))
            result = transsaction.wait()

        })

        it('Should update item/items from a batch as sold, pay seller, transfer NFT to buyer, charge fees and emit a Bought event', async()=>{

            for (let index = 1; index <=10; index++) {

                await expect((await market.connect(buyer).purchaseOneItemFromBatch(1, {value: toWei(priceOfanItem)})).wait())
                .to.emit(market, "Bought")
                  .withArgs(
                    1,
                    index,
                    await nft.getAddress(),
                    1,
                    toWei(priceOfanItem),
                    addrs[1].address,
                    buyer.address
                  )          
                
            }

            for (let index = 1; index <= 10; index++) {
                expect(await nft.balanceOf(buyer.address, index)).to.equal(1)
                expect(await nft.balanceOf(await market.getAddress(), index)).to.equal(0)             
            }

        })


    })

    describe('Checking for Batch 2', ()=>{
        let batchPrice = 2;
        let priceOfanItem = batchPrice/10;
        let transsaction, result;

        beforeEach(async function () {

            transsaction = await nft.connect(addrs[1]).mintTokens()
            result = transsaction.wait()

            transsaction = await nft.connect(addrs[1]).setApprovalForAll(await market.getAddress(), true)
            result = transsaction.wait()

            transsaction = await market.connect(addrs[1]).makeBatch(await nft.getAddress(), 1 , toWei(batchPrice))
            result = transsaction.wait()

//--------------------------Batch 2------------------------------------------------------------
            transsaction = await nft.connect(addrs[1]).mintTokens()
            result = transsaction.wait()

            transsaction = await nft.connect(addrs[1]).setApprovalForAll(await market.getAddress(), true)
            result = transsaction.wait()

            transsaction = await market.connect(addrs[1]).makeBatch(await nft.getAddress(), 2 , toWei(batchPrice))
            result = transsaction.wait()

        })

        it('Should update item/items from a batch as sold, pay seller, transfer NFT to buyer, charge fees and emit a Bought event', async()=>{

            for (let index = 1; index <=10; index++) {

                await expect((await market.connect(buyer).purchaseOneItemFromBatch(1, {value: toWei(priceOfanItem)})).wait())
                .to.emit(market, "Bought")
                  .withArgs(
                    1,
                    index,
                    await nft.getAddress(),
                    1,
                    toWei(priceOfanItem),
                    addrs[1].address,
                    buyer.address
                  )          
                
            }
            
            // for (let index = 11; index <=20; index++) {

            //     await expect((await market.connect(buyer).purchaseOneItemFromBatch(2, {value: toWei(priceOfanItem)})).wait())
            //     .to.emit(market, "Bought")
            //       .withArgs(
            //         2,
            //         index,
            //         await nft.getAddress(),
            //         2,
            //         toWei(priceOfanItem),
            //         addrs[1].address,
            //         buyer.address
            //       )          
                
            // }

            // for (let index = 11; index <= 20; index++) {
            //     expect(await nft.balanceOf(buyer.address, index)).to.equal(1)
            //     expect(await nft.balanceOf(await market.getAddress(), index)).to.equal(0)             
            // }

        })


    })
})