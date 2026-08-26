// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title PriceOracle
/// @notice Stores and manages the current asset price used by MarginVault.
contract PriceOracle {
    address public immutable owner;
    uint256 public price;

    event PriceUpdated(uint256 oldPrice, uint256 newPrice);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(uint256 initialPrice) {
        require(initialPrice > 0, "Invalid initial price");

        owner = msg.sender;
        price = initialPrice;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        require(newPrice > 0, "Invalid price");

        uint256 oldPrice = price;
        price = newPrice;

        emit PriceUpdated(oldPrice, newPrice);
    }

    function getPrice() external view returns (uint256) {
        return price;
    }
}
