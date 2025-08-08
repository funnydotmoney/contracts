# funny.money contracts

A Solidity diamond implementation for launching tokens on the EVM.

## Overview

FunnyMoney is a token launchpad built using the Diamond pattern (EIP-2535), which provides a modular and upgradeable smart contract architecture. This approach allows for flexible additions and modifications to the platform's functionality without deploying entirely new contracts.

## Installation

Clone the repository and install dependencies:

```bash
git clone https://github.com/yourusername/funnymoney-contracts.git
cd funnymoney-contracts
bun i
```

## Compilation

Compile the contracts:

```bash
bun run compile
```

## Deployment

### Testnet Deployment

Deploy to a testnet (Mantle Sepolia):

```bash
bun run deploy:testnet
```

### Mainnet Deployment

Deploy to Mantle mainnet:

```bash
bun run deploy
```
