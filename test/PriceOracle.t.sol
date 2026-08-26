// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/PriceOracle.sol";

contract PriceOracleTest is Test {
    PriceOracle oracle;

    address owner = address(this);
    address nonOwner = address(0x123);

    uint256 initialPrice = 2000e18;

    function setUp() public {
        oracle = new PriceOracle(initialPrice);
    }

    function testInitialValues() public {
        assertEq(oracle.owner(), owner);
        assertEq(oracle.price(), initialPrice);
        assertEq(oracle.getPrice(), initialPrice);
    }

    function testOwnerCanUpdatePrice() public {
        uint256 newPrice = 2500e18;

        oracle.setPrice(newPrice);

        assertEq(oracle.price(), newPrice);
        assertEq(oracle.getPrice(), newPrice);
    }

    function testNonOwnerCannotUpdatePrice() public {
        vm.prank(nonOwner);

        vm.expectRevert("Not owner");
        oracle.setPrice(2500e18);
    }

    function testCannotSetZeroPrice() public {
        vm.expectRevert("Invalid price");
        oracle.setPrice(0);
    }

    function testConstructorRejectsZeroPrice() public {
        vm.expectRevert("Invalid initial price");
        new PriceOracle(0);
    }

    function testPriceCanBeUpdatedMultipleTimes() public {
        oracle.setPrice(2100e18);
        assertEq(oracle.getPrice(), 2100e18);

        oracle.setPrice(1900e18);
        assertEq(oracle.getPrice(), 1900e18);

        oracle.setPrice(3000e18);
        assertEq(oracle.getPrice(), 3000e18);
    }
}
