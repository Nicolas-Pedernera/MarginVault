// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./FeeManager.sol";

contract MarginVault {
    struct Position {
        uint256 collateral;
        uint256 leverage;
        bool isLong;
        bool isOpen;
    }

    mapping(address => Position) public positions;

    uint256 public immutable maxLeverage;
    address public immutable owner;

    FeeManager public feeManager;

    uint256 public accumulatedFees;

    event PositionOpened(address indexed trader, uint256 collateral, uint256 leverage, bool isLong);

    event PositionClosed(address indexed trader, uint256 collateral);

    event FeeManagerUpdated(address indexed oldFeeManager, address indexed newFeeManager);

    event FeesWithdrawn(address indexed recipient, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(uint256 _maxLeverage) {
        require(_maxLeverage > 0, "Invalid leverage");

        maxLeverage = _maxLeverage;
        owner = msg.sender;
    }

    receive() external payable {}

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

        positions[msg.sender] = Position({collateral: netCollateral, leverage: leverage, isLong: isLong, isOpen: true});

        emit PositionOpened(msg.sender, netCollateral, leverage, isLong);
    }

    function getPnl(address) external pure returns (uint256) {
        return 0;
    }

    function closePosition() external {
        Position storage position = positions[msg.sender];

        require(position.isOpen, "No open position");

        uint256 collateral = position.collateral;

        position.collateral = 0;
        position.leverage = 0;
        position.isLong = false;
        position.isOpen = false;

        emit PositionClosed(msg.sender, collateral);

        (bool success,) = payable(msg.sender).call{value: collateral}("");

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
