
## NFT Marketplace contract

**Run on-chain auction and sell NFT for ERC-20 via meta-transactions**

The auctions should work as follows:


- Owner of the NFT approves all NFT’s to the Marketplace
- Owner of the NFT signs to create an off-chain auction listing with a minimum price
-  Bidder approves ERC20 tokens to Marketplace
- Bidder signs a bid for the auction
-  If owner approves the bid, signs it back and retrieve to bidder
-   Anyone with both signatures can settle the transaction, the owner takes the ERC20 whilst the bidder takes the NFT.

## Demo screencast
[Unlisted - available only by direct link ]
https://youtu.be/-mHsl1NFQio 

## Deployment

Sepolia: https://sepolia.etherscan.io/address/0x42d2C93839ED64b73Baa59A8ceB1C464287C8113

## Features
- Support of EIP-712 typed structured data hashing
- Protection from re-play attack by introducing nonce in listing structure
- Support TTL for bid

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
