// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title MarginVault
/// @notice Simplified margin and liquidation module for leveraged positions.
/// @dev Educational / portfolio project. Not audited and not production-ready.
///      Does not implement funding rates, advanced oracle manipulation protection,
///      or a complete solvency mechanism.
contract MarginVault {
    // =============================================================
    // Types
    // =============================================================

    struct Position {
        uint256 collateral;
        uint256 size;
        uint256 entryPrice;
        bool isLong;
        bool open;
    }

    // =============================================================
    // State
    // =============================================================

    address public owner;
    address public pendingOwner;

    address public priceOracle;
    uint256 public currentPrice;

    uint256 public constant MAX_LEVERAGE = 10;

    // Minimum collateral remaining before liquidation.
    // 500 BPS = 5% of the initial collateral.
    uint256 public constant LIQUIDATION_THRESHOLD_BPS = 500;

    // 1,000 BPS = 10% of the remaining collateral.
    uint256 public constant LIQUIDATION_REWARD_BPS = 1_000;

    uint256 public constant BPS_DENOMINATOR = 10_000;

    mapping(address => Position) public positions;

    // =============================================================
    // Events
    // =============================================================

    event PositionOpened(
        address indexed trader,
        uint256 collateral,
        uint256 size,
        bool isLong,
        uint256 entryPrice
    );

    event PositionClosed(
        address indexed trader,
        int256 pnl
    );

    event PositionLiquidated(
        address indexed trader,
        address indexed liquidator,
        int256 pnl,
        uint256 liquidatorReward,
        uint256 traderRefund
    );

    event PriceUpdated(
        uint256 newPrice
    );

    event OracleUpdated(
        address indexed newOracle
    );

    event OwnershipTransferStarted(
        address indexed currentOwner,
        address indexed pendingOwner
    );

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    event OwnershipTransferCancelled(
        address indexed currentOwner,
        address indexed cancelledPendingOwner
    );

    // =============================================================
    // Errors
    // =============================================================

    error NotOwner();
    error NotOracle();
    error NotPendingOwner();

    error ZeroAddress();
    error ZeroAmount();

    error PositionAlreadyOpen();
    error PositionNotOpen();

    error LeverageTooHigh();
    error NotLiquidatable();

    error TransferFailed();

    error SameAddress();
    error NoPendingTransfer();

    // =============================================================
    // Modifiers
    // =============================================================

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier onlyOracle() {
        if (msg.sender != priceOracle) revert NotOracle();
        _;
    }

    // =============================================================
    // Constructor
    // =============================================================

    /// @param _priceOracle Address authorized to update the asset price.
    /// @param _initialPrice Initial asset price, scaled to 1e18.
    constructor(
        address _priceOracle,
        uint256 _initialPrice
    ) {
        if (_priceOracle == address(0)) revert ZeroAddress();
        if (_initialPrice == 0) revert ZeroAmount();

        owner = msg.sender;
        priceOracle = _priceOracle;
        currentPrice = _initialPrice;

        emit OwnershipTransferred(address(0), msg.sender);
        emit PriceUpdated(_initialPrice);
        emit OracleUpdated(_priceOracle);
    }

    // =============================================================
    // Ownership
    // =============================================================

    /// @notice Starts a two-step ownership transfer.
    /// @param newOwner Address that must accept ownership.
    function transferOwnership(
        address newOwner
    ) external onlyOwner {
        if (newOwner == address(0)) revert ZeroAddress();
        if (newOwner == owner) revert SameAddress();

        pendingOwner = newOwner;

        emit OwnershipTransferStarted(
            owner,
            newOwner
        );
    }

    /// @notice Cancels a pending ownership transfer.
    function cancelOwnershipTransfer()
        external
        onlyOwner
    {
        if (pendingOwner == address(0)) {
            revert NoPendingTransfer();
        }

        address cancelledOwner = pendingOwner;

        pendingOwner = address(0);

        emit OwnershipTransferCancelled(
            owner,
            cancelledOwner
        );
    }

    /// @notice Accepts a previously initiated ownership transfer.
    function acceptOwnership() external {
        if (msg.sender != pendingOwner) {
            revert NotPendingOwner();
        }

        address previousOwner = owner;

        owner = pendingOwner;
        pendingOwner = address(0);

        emit OwnershipTransferred(
            previousOwner,
            owner
        );
    }

    // =============================================================
    // Oracle administration
    // =============================================================

    /// @notice Updates the authorized price oracle.
    /// @param newOracle New authorized oracle address.
    function setPriceOracle(
        address newOracle
    ) external onlyOwner {
        if (newOracle == address(0)) {
            revert ZeroAddress();
        }

        priceOracle = newOracle;

        emit OracleUpdated(newOracle);
    }

    /// @notice Updates the current asset price.
    /// @param newPrice New asset price, scaled to 1e18.
    function updatePrice(
        uint256 newPrice
    ) external onlyOracle {
        if (newPrice == 0) {
            revert ZeroAmount();
        }

        currentPrice = newPrice;

        emit PriceUpdated(newPrice);
    }

    // =============================================================
    // Position management
    // =============================================================

    /// @notice Opens a leveraged long or short position using ETH as collateral.
    /// @param leverage Leverage multiplier from 1x to 10x.
    /// @param isLong True for long, false for short.
    function openPosition(
        uint256 leverage,
        bool isLong
    ) external payable {
        if (msg.value == 0) {
            revert ZeroAmount();
        }

        if (
            leverage == 0 ||
            leverage > MAX_LEVERAGE
        ) {
            revert LeverageTooHigh();
        }

        if (positions[msg.sender].open) {
            revert PositionAlreadyOpen();
        }

        uint256 positionSize = msg.value * leverage;

        positions[msg.sender] = Position({
            collateral: msg.value,
            size: positionSize,
            entryPrice: currentPrice,
            isLong: isLong,
            open: true
        });

        emit PositionOpened(
            msg.sender,
            msg.value,
            positionSize,
            isLong,
            currentPrice
        );
    }

    /// @notice Closes the caller's position at the current price.
    function closePosition() external {
        Position storage pos = positions[msg.sender];

        if (!pos.open) {
            revert PositionNotOpen();
        }

        int256 pnl = _calculatePnl(pos);

        uint256 payout = _payoutAmount(
            pos.collateral,
            pnl
        );

        // Checks-Effects-Interactions:
        // Close state before making the external transfer.
        pos.open = false;

        emit PositionClosed(
            msg.sender,
            pnl
        );

        if (payout > 0) {
            (bool success, ) = msg.sender.call{
                value: payout
            }("");

            if (!success) {
                revert TransferFailed();
            }
        }
    }

    /// @notice Liquidates a position whose loss exceeds the liquidation threshold.
    /// @param trader Address of the trader to liquidate.
    function liquidate(
        address trader
    ) external {
        Position storage pos = positions[trader];

        if (!pos.open) {
            revert PositionNotOpen();
        }

        int256 pnl = _calculatePnl(pos);

        if (
            !_isLiquidatable(
                pos.collateral,
                pnl
            )
        ) {
            revert NotLiquidatable();
        }

        uint256 remaining = _payoutAmount(
            pos.collateral,
            pnl
        );

        // Checks-Effects-Interactions.
        pos.open = false;

        uint256 liquidatorReward =
            (remaining * LIQUIDATION_REWARD_BPS)
            / BPS_DENOMINATOR;

        uint256 traderRefund =
            remaining - liquidatorReward;

        emit PositionLiquidated(
            trader,
            msg.sender,
            pnl,
            liquidatorReward,
            traderRefund
        );

        if (liquidatorReward > 0) {
            (bool successLiquidator, ) =
                msg.sender.call{
                    value: liquidatorReward
                }("");

            if (!successLiquidator) {
                revert TransferFailed();
            }
        }

        if (traderRefund > 0) {
            (bool successTrader, ) =
                trader.call{
                    value: traderRefund
                }("");

            if (!successTrader) {
                revert TransferFailed();
            }
        }
    }

    // =============================================================
    // Views
    // =============================================================

    /// @notice Returns the current unrealized PnL of a trader.
    function getPnl(
        address trader
    ) external view returns (int256) {
        Position memory pos = positions[trader];

        if (!pos.open) {
            return 0;
        }

        return _calculatePnl(pos);
    }

    /// @notice Returns whether a trader's position can currently be liquidated.
    function isLiquidatable(
        address trader
    ) external view returns (bool) {
        Position memory pos = positions[trader];

        if (!pos.open) {
            return false;
        }

        int256 pnl = _calculatePnl(pos);

        return _isLiquidatable(
            pos.collateral,
            pnl
        );
    }

    /// @notice Returns the ETH balance held by the vault.
    function vaultBalance()
        external
        view
        returns (uint256)
    {
        return address(this).balance;
    }

    // =============================================================
    // Internal accounting
    // =============================================================

    /// @dev Calculates unrealized PnL.
    ///      Prices are scaled to 1e18.
    function _calculatePnl(
        Position memory pos
    ) internal view returns (int256) {
        int256 priceDiff =
            int256(currentPrice) -
            int256(pos.entryPrice);

        int256 rawPnl =
            (priceDiff * int256(pos.size)) /
            int256(pos.entryPrice);

        if (pos.isLong) {
            return rawPnl;
        }

        return -rawPnl;
    }

    /// @dev Determines whether the position has crossed the liquidation threshold.
    ///      The trader must retain at least 5% of the original collateral.
    function _isLiquidatable(
        uint256 collateral,
        int256 pnl
    ) internal pure returns (bool) {
        if (pnl >= 0) {
            return false;
        }

        uint256 loss = uint256(-pnl);

        uint256 minimumRemaining =
            (collateral * LIQUIDATION_THRESHOLD_BPS)
            / BPS_DENOMINATOR;

        return loss >= collateral - minimumRemaining;
    }

    /// @dev Calculates the amount returned to the trader.
    ///      Losses cannot reduce the payout below zero.
    function _payoutAmount(
        uint256 collateral,
        int256 pnl
    ) internal pure returns (uint256) {
        if (pnl >= 0) {
            return collateral + uint256(pnl);
        }

        uint256 loss = uint256(-pnl);

        if (loss >= collateral) {
            return 0;
        }

        return collateral - loss;
    }

    // =============================================================
    // ETH receiver
    // =============================================================

    /// @notice Allows the vault to receive ETH for additional funding.
    receive() external payable {}
}
