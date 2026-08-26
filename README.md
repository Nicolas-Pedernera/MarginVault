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

## Technology

- Solidity ^0.8.20
- Ethereum / EVM
- Smart Contract Development
- DeFi
- Leveraged Trading

## Project Status

Educational / portfolio project.

This project has not been audited and is not intended for production use.

It is designed to demonstrate Solidity development, smart contract architecture, state management, access control, margin management, and liquidation logic.

## My Role

Designed and implemented the Solidity smart contracts for the MarginVault project, including leveraged position management, margin checks, liquidation logic, price updates, and protocol fee management.

## Technology Stack

- Solidity 0.8.20
- Ethereum / EVM
- Smart Contracts
- DeFi / Leveraged Trading

## Author

Nicolas Pedernera
It is not intended for deployment with real funds without substantial additional development, testing, auditing, and risk-management infrastructure.

## Core Smart Contract Functions

- `openPosition()` — Opens leveraged long or short positions with ETH collateral.
- `closePosition()` — Closes a position and calculates the resulting PnL.
- `liquidate()` — Liquidates positions that exceed the defined loss threshold.
- `getPnl()` — Returns the current unrealized PnL.
- `isLiquidatable()` — Checks whether a position can be liquidated.
- `updatePrice()` — Updates the asset price through the authorized oracle.
- `transferOwnership()` / `acceptOwnership()` — Two-step ownership management.
