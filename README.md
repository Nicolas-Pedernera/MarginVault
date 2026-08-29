# MarginVault

Educational Solidity project focused on leveraged trading, margin management, liquidation, fees, and smart contract ownership.

## Overview

MarginVault is a simplified leveraged trading smart contract designed to demonstrate core DeFi concepts using Solidity.

The project includes:

- Leveraged long and short positions
- ETH collateral management
- Position opening and closing
- Profit and loss calculations
- Margin and liquidation checks
- Price updates through an oracle
- Protocol fee management
- Ownership transfer management

## Contracts

### MarginVault.sol

Main contract responsible for leveraged trading positions, collateral, margin requirements, PnL calculations, and liquidation logic.

### FeeManager.sol

Manages protocol fees and contract ownership, including fee calculation, fee updates, and secure ownership transfers.

## Technology Stack

- Solidity ^0.8.20
- Ethereum / EVM
- Smart Contracts
- DeFi / Leveraged Trading

## Core Smart Contract Functions

- `openPosition()` — Opens leveraged long or short positions with ETH collateral.
- `closePosition()` — Closes a position and calculates the resulting PnL.
- `liquidate()` — Liquidates positions that exceed the defined loss threshold.
- `getPnl()` — Returns the current unrealized PnL.
- `isLiquidatable()` — Checks whether a position can be liquidated.
- `updatePrice()` — Updates the asset price through the authorized oracle.
- `transferOwnership()` / `acceptOwnership()` — Two-step ownership management.

## FeeManager.sol

Manages protocol fees and contract ownership.

Core features:

- Configurable protocol fee
- Maximum fee limit of 20%
- Fee calculation using basis points
- Two-step ownership transfer
- Ownership transfer cancellation
- Owner-only fee updates

## Security & Limitations

This project is intended for educational and portfolio purposes.

The smart contracts have not been professionally audited and are not intended for production use or real funds.

Before production deployment, the system would require:

- Comprehensive unit and integration testing
- Professional smart contract security audit
- Oracle manipulation and price-feed protection
- Reentrancy and access-control review
- Extensive liquidation and solvency testing
- Deployment and monitoring infrastructure

## My Role

Designed and implemented the Solidity smart contracts for the MarginVault project, including leveraged position management, margin checks, liquidation logic, price updates, and protocol fee management.

## Project Status

Educational / portfolio project.

## Author

Nicolas Pedernera

This project is not intended for deployment with real funds without substantial additional development, testing, auditing, and risk-management infrastructure.

## Testing & Verification

The contract was tested in Remix VM to verify the main position lifecycle and safety checks.

Verified functionality includes:

- Opening leveraged long and short positions
- Preventing multiple open positions for the same trader
- PnL calculation
- Liquidation status checks
- Position closing
- ETH collateral handling
- Reversion of invalid operations through custom Solidity errors

Example validation:

`PositionAlreadyOpen` is correctly reverted when attempting to open a second position while an existing position is still active.

The contract was deployed and interacted with successfully in Remix VM.

## Related Projects

This repository focuses specifically on leveraged trading mechanics — margin, liquidation, and PnL calculation. For other Solidity work in my portfolio with a different focus:

- [defi-vault-contracts](https://github.com/Nicolas-Pedernera/defi-vault-contracts) — a simpler staking vault (deposit/withdraw only, no leverage), focused on demonstrating reentrancy protection with an automated Hardhat test suite that actively attacks the contract.
- [remix-crypto-escrow](https://github.com/Nicolas-Pedernera/remix-crypto-escrow) — a two-party escrow contract, unrelated to trading or lending.
