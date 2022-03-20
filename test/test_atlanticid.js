const AtlanticId = artifacts.require('AtlanticId')
// const assert = require("chai").assert
const truffleAssert = require('truffle-assertions')

contract('AtlanticId Function Testing', async accounts => {
    /** Full Test Variables */
    const owner = accounts[0]
    const acnt1 = accounts[1]
    const acnt2 = accounts[2]
    const acnt3 = accounts[3]
    const acnt4 = accounts[4]
    const acnt5 = accounts[5]
    const acnt6 = accounts[6]
    const acnt7 = accounts[7]
    const acnt8 = accounts[8]
    const acnt9 = accounts[9]
    var atlanticIdInstance

    /** TEST SETUP */
    before('Setup Contract', async function() {
        atlanticIdInstance = await AtlanticId.deployed()
    })

    describe("Test mint key & transfer key.", async () => {
        /**
         * Test should include pass and fail tests:
         * 
         * [Test #1 - mint_key]     : Assert  TRUE - key is created.
         * [Test #2 - mint_key]     : Assert FALSE - key is invalid type
         * [Test #3 - transfer_key] : Assert  TRUE - key is created.
         */

        /** TEST VARIABLES */
        const mint_key_true     = "asdkljf23jwj2mc4l4j4"
        const mint_key_false    = 123
        const transfer_key_true = true

        /** TEST #1 */
        it("Mint key is of correct type", async () => {
            await atlanticIdInstance.approveMint(mint_key_true, acnt1, {from: owner})
            const acnt1_mint_key = await atlanticIdInstance.getMintKey(acnt1, {from: owner})
            assert.equal(acnt1_mint_key, mint_key_true)
        })

        /** TEST #2 */
        it("Mint key is of wrong type", async () => {
            await atlanticIdInstance.approveMint(mint_key_false, acnt2, {from: owner})
            const acnt2_mint_key = await atlanticIdInstance.getMintKey(acnt2, {from: owner})
            assert.notEqual(acnt2_mint_key, mint_key_false)
        })

        /** TEST #3 */
        it("Transfer key is of correct type", async () => {
            await atlanticIdInstance.approveTransfer(acnt1, {from: owner})
            const acnt1_transfer_key = await atlanticIdInstance.getTransferKey(acnt1, {from: owner})
            assert.equal(acnt1_transfer_key, transfer_key_true)
        })
    })

    describe("Check events emitted when an NFT is minted.", async () => {

        /**
         * The Mint() method logs 3 events:
         *      [1] Transfer - Emitted when `tokenId` token is transferred from `from` to `to`.
         *                      |> Logs the "from" address, the "to" address, and the tokenId
         *      [2] Approval - Emitted when `owner` enables `approved` to manage the `tokenId` token.
         *                      |> Logs the owner address, the approved address, and the tokenId
         *      [3] Mint     - Emitted when an NFID is minted.
         *                      |> Logs the tokenId, timestamp and expiration year.
         */

        it("Check if Transfer event is emitted.", async () => {
            await atlanticIdInstance.approveMint("key4", acnt4, {from: owner})
            acnt4_mint_instance = await atlanticIdInstance.mint(
                "acnt4.ens",
                "myUid:1892389c83u2",
                "coinbase",
                "key4",
                {
                    from: acnt4
                }
            )
            truffleAssert.eventEmitted(acnt4_mint_instance, 'Transfer', (ev) => {
                return ev.tokenId == 0
            });
        })

        it("Check if Approval event is emitted.", async () => {
            await atlanticIdInstance.approveMint("key5", acnt5, {from: owner})
            const acnt5_mint_instance = await atlanticIdInstance.mint(
                "acnt5.ens",
                "myUid:1892389c83u2",
                "coinbase",
                "key5",
                {
                    from: acnt5
                }
            )
            truffleAssert.eventEmitted(acnt5_mint_instance, 'Approval', (ev) => {
                return ev.tokenId == 1
            });
        })

        it("Check if Mint event is emitted.", async () => {
            await atlanticIdInstance.approveMint("key6", acnt6, {from: owner})
            const acnt6_mint_instance = await atlanticIdInstance.mint(
                "acnt6.ens",
                "myUid:1892389c83u2",
                "coinbase",
                "key6",
                {
                    from: acnt6
                }
            )
            truffleAssert.eventEmitted(acnt6_mint_instance, 'Mint', (ev) => {
                return ev.tokenId == 2
            });
        })
    })

    describe("Test if mint creation works.", async () => {

        var acnt7_mint_instance
        var _tokenId
        const _ens = "acnt7.ens"
        const _uid = "myUid:1892389c83u2"
        const _exchange = "coinbase"
        const _key = "key7"

        /** TEST SETUP */
        before('Setup Contract', async function() {
            await atlanticIdInstance.approveMint("key7", acnt7, {from: owner})
            acnt7_mint_instance = await atlanticIdInstance.mint(
                _ens,
                _uid,
                _exchange,
                _key,
                {
                    from: acnt7
                }
            )
            _tokenId = acnt7_mint_instance.logs[2].args.tokenId.words[0]
        })

        it('Get account ens.', async () => {
            const acnt7_ens = await atlanticIdInstance.getEns(_tokenId)
            assert.equal(acnt7_ens, _ens)
        })

        it('Get account uid.', async () => {
            const acnt7_uid = await atlanticIdInstance.getUid(_tokenId)
            assert.equal(acnt7_uid, _uid)
        })

        it('Get account exchange.', async () => {
            const acnt7_exchange = await atlanticIdInstance.getExchange(_tokenId)
            assert.equal(acnt7_exchange, _exchange)
        })

        it('Get account expiration date (expry) - day, month, year', async () => {
            /** GET BLOCKCHAIN DATE */
            var acnt7_expry = await atlanticIdInstance.getExpry(_tokenId)
            const _day = acnt7_expry[0].words[0]
            const _month = acnt7_expry[1].words[0]
            const _year = acnt7_expry[2].words[0]

            /** GET CURRENT DATE */
            var date = new Date()
            var day = date.getUTCDate();
            var month = date.getUTCMonth() + 1; //months from 1-12
            var year = date.getUTCFullYear()+1;

            /** ASSERT TESTS */
            assert.equal(_day,day)
            assert.equal(_month,month)
            assert.equal(_year,year)
        })

        

        // truffleAssert.eventEmitted(acnt7_mint_instance, 'Mint', (ev) => {
        //     return ev.tokenId == 1
        // });
        // assert.equal(create_message, 1);
    });


    // afterEach('kill instance after each session', async () => {
    //     await atlanticIdInstance.kill({ from: owner });
    // });
})