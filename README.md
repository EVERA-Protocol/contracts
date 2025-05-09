# Evera RWA Platform

Evera is a permissionless Real World Asset (RWA) tokenization platform with the tagline "Bring and mint everything anything onchain". The platform allows users to create and manage tokenized real-world assets in a permissionless manner.

## Overview

The Evera platform consists of the following main components:

1. **RWATokenFactory**: A factory contract that creates new RWA tokens
2. **RWAToken**: The actual token contract that represents a Real World Asset
3. **RWAMetadata**: A library for handling metadata for RWA tokens

## Features

- Permissionless creation of RWA tokens
- Customizable metadata for each RWA token
- ERC20-compatible tokens for easy integration with existing DeFi protocols
- Ownership and management of RWA tokens
- Price updates for RWA tokens

## Metadata Fields

Each RWA token includes the following metadata:

1. Symbol RWA
2. Institution Name
3. Institution Address
4. Supporting Documents (optional)
5. Total Supply RWA
6. Price per RWA
7. Brief Description

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

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

To deploy the RWA Token Factory:

```shell
$ forge script script/DeployRWAFactory.s.sol --rpc-url <your_rpc_url> --private-key <your_private_key>
```

## Usage

### Creating a new RWA Token

To create a new RWA token, call the `createRWAToken` function on the factory contract:

```solidity
function createRWAToken(
    string memory _name,
    string memory _symbol,
    string memory _institutionName,
    string memory _institutionAddress,
    string memory _documentURI,
    uint256 _totalRWASupply,
    uint256 _pricePerRWA,
    string memory _description
) external returns (address);
```

### Updating RWA Token Price

The owner of an RWA token can update its price:

```solidity
function updatePrice(uint256 _newPrice) external onlyOwner;
```

### Getting RWA Token Metadata

To retrieve the metadata of an RWA token:

```solidity
function getMetadata() external view returns (
    string memory _institutionName,
    string memory _institutionAddress,
    string memory _documentURI,
    uint256 _totalRWASupply,
    uint256 _pricePerRWA,
    string memory _description
);
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
