# MarginVault

Educational Solidity project focused on leveraged trading, ETH collateral management, profit and loss (PnL) calculations, protocol fees, price oracles, and smart contract access control.

## Overview

MarginVault is a simplified leveraged trading smart contract designed to demonstrate core DeFi concepts using Solidity and the Ethereum Virtual Machine (EVM).

The project implements:

* Leveraged long and short positions
* ETH collateral management
* Configurable maximum leverage
* Position opening and closing
* Profit and loss (PnL) calculations
* Protocol fee management
* External price oracle integration
* Owner-controlled administrative functions
* Fee withdrawal functionality

## Contracts

### MarginVault.sol

The main contract responsible for:

* Opening leveraged long and short positions
* Managing ETH collateral
* Calculating unrealized PnL
* Closing positions
* Integrating the protocol fee manager
* Reading market prices from the price oracle
* Owner-controlled configuration and fee withdrawal

### FeeManager.sol

Manages protocol fees and ownership.

Core functionality includes:

* Configurable protocol fee
* Maximum fee limit of 20%
* Fee calculation using basis points
* Owner-only fee updates
* Two-step ownership transfer
* Ownership transfer cancellation

### PriceOracle.sol

Provides the market price used by `MarginVault` for position entry and PnL calculations.

Core functionality includes:

* Initial price configuration
* Owner-controlled price updates
* Protection against zero-price updates
* Multiple price updates

## Technology Stack

* Solidity `^0.8.20`
* Foundry
* Ethereum / EVM
* Smart Contracts
* DeFi
* Leveraged Trading
* Unit Testing

## Core Functions

### MarginVault

* `openPosition()` — Opens a leveraged long or short position using ETH collateral.
* `closePosition()` — Closes the caller's open position and calculates the resulting PnL.
* `getPnl()` — Returns the current unrealized PnL for an open position.
* `setCurrentPrice()` — Updates the market price through the integrated `PriceOracle`.
* `setFeeManager()` — Configures the protocol fee manager.
* `withdrawFees()` — Allows the owner to withdraw accumulated protocol fees.

### FeeManager

* `calculateFee()` — Calculates the protocol fee for a given amount.
* `updateFee()` — Updates the protocol fee within the configured maximum.
* `transferOwnership()` — Starts a two-step ownership transfer.
* `acceptOwnership()` — Accepts a pending ownership transfer.
* `cancelOwnershipTransfer()` — Cancels a pending ownership transfer.

### PriceOracle

* `getPrice()` — Returns the current stored price.
* `setPrice()` — Updates the price through the authorized owner.

## Testing

The project includes unit tests written with Foundry.

The current test suite covers:

* Fee calculation
* Fee updates
* Fee access control
* Ownership transfers
* Oracle initialization
* Oracle price updates
* Oracle access control
* Long position opening
* Short position opening
* Long PnL profit and loss scenarios
* Short PnL profit and loss scenarios
* Position closing
* Position closing with profit
* Fee integration
* Fee withdrawal
* Access control for administrative functions
* Invalid position operations

### Test Results

The full Foundry test suite currently passes:

**25 tests passed — 0 failed — 0 skipped**

The project compiles successfully with Solidity `0.8.35` under the current Foundry environment.

A compiler warning is present in `test/PriceOracle.t.sol` because one test function's mutability could be restricted to `view`. This does not cause any test failures.

## Security & Limitations

This project is intended for educational and portfolio purposes.

The smart contracts have **not been professionally audited** and are **not intended for production use or real funds**.

Before production deployment, the system would require additional work, including:

* Comprehensive security auditing
* Extensive unit and integration testing
* Oracle manipulation and price-feed protection
* Reentrancy and access-control review
* Detailed liquidation and solvency mechanisms
* Production-grade deployment and monitoring infrastructure
* Formal review of economic and risk assumptions

## Verification

The contract was previously deployed and interacted with successfully in Remix VM to verify core position functionality and revert conditions.

The project is now also covered by a Foundry test suite containing 25 passing tests.

Example verified behavior:

`PositionAlreadyOpen` is correctly reverted when attempting to open a second position while the trader already has an active position.

## My Role

Designed and implemented the Solidity smart contract architecture for the MarginVault project, including:

* Leveraged position management
* Long and short PnL calculations
* ETH collateral handling
* Fee management integration
* Price oracle integration
* Ownership and access-control mechanisms
* Foundry unit tests
* Project configuration and deployment scripts

## Project Status

**Educational / Portfolio Project**

This project is not intended for deployment with real funds without substantial additional development, testing, auditing, and risk-management infrastructure.

## Author

**Nicolas Pedernera**

