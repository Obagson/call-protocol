import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v1.4.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.170.0/testing/asserts.ts';

Clarinet.test({
    name: "Call Protocol: Asset Minting Test",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;

        const block = chain.mineBlock([
            Tx.contractCall('call-nft', 'mint-asset', [
                types.uint(12345),
                types.utf8('generative'),
                types.uint(100),
                types.utf8('dynamic'),
                types.utf8('blue'),
                types.utf8('gradient'),
                types.utf8('modern'),
                types.ascii('https://asset-metadata.uri')
            ], wallet1.address)
        ]);

        assertEquals(block.receipts.length, 1);
        block.receipts[0].result.expectOk();
    }
});

Clarinet.test({
    name: "Call Protocol: Asset Listing Test",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;

        const block = chain.mineBlock([
            Tx.contractCall('call-nft', 'list-for-sale', [
                types.uint(1),
                types.uint(100000000),
                types.uint(1000)
            ], wallet1.address)
        ]);

        assertEquals(block.receipts.length, 1);
        block.receipts[0].result.expectOk();
    }
});