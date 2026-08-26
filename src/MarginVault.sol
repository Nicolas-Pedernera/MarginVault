// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./FeeManager.sol";

contract MarginVault {
    struct Position {
        uint256 collateral;
        uint256 leverage;
        uint256 entryPrice;
        bool isLong;
        bool isOpen;
    }

    mapping(address => Position) public positions;

    uint256 public immutable maxLeverage;
    address public immutable owner;

    FeeManager public feeManager;

    uint256 public accumulatedFees;
    uint256 public currentPrice;

    event PositionOpened(address indexed trader, uint256 collateral, uint256 leverage, uint256 entryPrice, bool isLong);

    event PositionClosed(address indexed trader, uint256 collateral, int256 pnl);

    event FeeManagerUpdated(address indexed oldFeeManager, address indexed newFeeManager);

    event FeesWithdrawn(address indexed recipient, uint256 amount);

    event PriceUpdated(uint256 oldPrice, uint256 newPrice);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(uint256 _maxLeverage, uint256 _initialPrice) {
        require(_maxLeverage > 0, "Invalid leverage");
        require(_initialPrice > 0, "Invalid initial price");

        maxLeverage = _maxLeverage;
        currentPrice = _initialPrice;
        owner = msg.sender;
    }

    receive() external payable {}

    function setCurrentPrice(uint256 newPrice) external onlyOwner {
        require(newPrice > 0, "Invalid price");

        uint256 oldPrice = currentPrice;
        currentPrice = newPrice;

        emit PriceUpdated(oldPrice, newPrice);
    }

    function setFeeManager(address _feeManager) external onlyOwner {
        require(_feeManager != address(0), "Invalid fee manager");

        address oldFeeManager = address(feeManager);

        feeManager = FeeManager(_feeManager);

        emit FeeManagerUpdated(oldFeeManager, _feeManager);
    }

    function openPosition(uint256 leverage, bool isLong) external payable {
        require(msg.value > 0, "Collateral required");
        require(!positions[msg.sender].isOpen, "Position already open");
        require(leverage > 0 && leverage <= maxLeverage, "Invalid leverage");

        uint256 fee = 0;

        if (address(feeManager) != address(0)) {
            fee = feeManager.calculateFee(msg.value);
        }

        uint256 netCollateral = msg.value - fee;

        require(netCollateral > 0, "Collateral too low");

        accumulatedFees += fee;

        positions[msg.sender] = Position({
            collateral: netCollateral, leverage: leverage, entryPrice: currentPrice, isLong: isLong, isOpen: true
        });

        emit PositionOpened(msg.sender, netCollateral, leverage, currentPrice, isLong);
    }

    function getPnl(address trader) public view returns (int256) {
        Position memory position = positions[trader];

        require(position.isOpen, "No open position");

        int256 priceDifference = int256(currentPrice) - int256(position.entryPrice);

        int256 pnl =
            (int256(position.collateral) * int256(position.leverage) * priceDifference) / int256(position.entryPrice);

        if (!position.isLong) {
            pnl = -pnl;
        }

        return pnl;
    }

    function closePosition() external {
        Position storage position = positions[msg.sender];

        require(position.isOpen, "No open position");

        int256 pnl = getPnl(msg.sender);

        uint256 collateral = position.collateral;

        uint256 payout;

        if (pnl >= 0) {
            payout = collateral + uint256(pnl);
        } else {
            uint256 loss = uint256(-pnl);

            if (loss >= collateral) {
                payout = 0;
            } else {
                payout = collateral - loss;
            }
        }

        position.collateral = 0;
        position.leverage = 0;
        position.entryPrice = 0;
        position.isLong = false;
        position.isOpen = false;

        emit PositionClosed(msg.sender, payout, pnl);

        (bool success,) = payable(msg.sender).call{value: payout}("");

        require(success, "Collateral transfer failed");
    }

    function withdrawFees(address payable recipient) external onlyOwner {
        require(recipient != address(0), "Invalid recipient");

        uint256 amount = accumulatedFees;

        require(amount > 0, "No fees available");

        accumulatedFees = 0;

        emit FeesWithdrawn(recipient, amount);

        (bool success,) = recipient.call{value: amount}("");

        require(success, "Fee transfer failed");
    }
}
