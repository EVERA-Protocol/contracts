## Evera Smart Contarct
Mint anything RWA with Eigenlayer - AVS operator as assets validator

![WhatsApp Image 2025-05-17 at 13 42 38](https://github.com/user-attachments/assets/5114dbda-69a0-44c8-bcf7-1b9b2a866029)



## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

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

# AVS Deployment

This repository contains a refactored AVS (Actively Validated Service) integrated with EigenLayer middleware. The contract has been optimized to fit within Ethereum's contract size limits.

## Contract Architecture

The AVS architecture has been modularized into several components:

1. **AVS.sol**: The main contract that implements the EigenLayer AVS interface
2. **SignatureVerifier.sol**: Library for handling signature verification
3. **TaskManager.sol**: Library for managing task creation and responses
4. **SlasherHandler.sol**: Contract for handling slashing operations

## Setup

1. Copy the example environment file:
   ```
   cp deploy.env.example .env
   ```

2. Fill in your environment variables in the `.env` file:
   - `PRIVATE_KEY`: Your deployment wallet's private key
   - EigenLayer contract addresses (already filled with mainnet addresses):
     - AVS_DIRECTORY: 0xb8f3221bf7974f1682d0acbc2f40ba3597db3151
     - STAKE_REGISTRY: 0xe62a528fa2787b7ba2399506d94d82c98fafd01a
     - REWARDS_COORDINATOR: 0x16a26002119c039de57b051c8e8871b0ae8f2768
     - DELEGATION_MANAGER: 0xff8e53df56550c27bf6a8baadc839ed86a7c99d7
     - ALLOCATION_MANAGER: 0x51ff720105655c01be501523dd5c2642ce53fdde
   - Optional owner and rewards initiator addresses

## Deployment

### Prerequisites

- Foundry installed ([Installation guide](https://book.getfoundry.sh/getting-started/installation))
- Access to EigenLayer contracts on your target network
- Sufficient ETH for deployment

### Deploy using Forge script

```bash
# Install dependencies
forge install

# Build the contracts
forge build

# Deploy to mainnet
forge script script/DeployAVS.s.sol:DeployAVS --rpc-url $RPC_URL --broadcast --verify

# Deploy to testnet (specify the network)
forge script script/DeployAVS.s.sol:DeployAVS --rpc-url $RPC_URL --broadcast --verify --chain-id $CHAIN_ID
```

### Verify deployment

After deployment, the script will output the addresses of the deployed contracts:
- AVS contract address
- Slasher contract address

## Contract Size

The AVS contract has been optimized to fit within Ethereum's contract size limit:
- Original size: 28,919 bytes (exceeds the 24,576 byte limit)
- Refactored size: 22,091 bytes (well below the limit)

## Usage

Once deployed, the AVS contract can be used to:
- Create verification tasks for real-world assets
- Submit verification responses
- Slash operators for malicious behavior
- View task and response data

## License

UNLICENSED
