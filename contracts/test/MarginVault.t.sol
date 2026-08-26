// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../contracts/MarginVault.sol";

contract MarginVaultTest is Test {
    MarginVault vault;

    address owner = address(this);
    address oracle = address(0x100);
    address trader = address(0x200);
    address trader2 = address(0x300);
    address liquidator = address(0x400);

    uint256 initialPrice = 2000e18;

    function setUp() public {
        vault = new MarginVault(
            oracle,
            initialPrice
        );

        vm.deal(trader, 100 ether);
        vm.deal(trader2, 100 ether);
        vm.deal(liquidator, 100 ether);
    }

    function testOpenLongPosition() public {
        vm.prank(trader);

        vault.openPosition{value: 1 ether}(
            2,
            true
        );

        (
            uint256 collateral,
            uint256 size,
            uint256 entryPrice,
            bool isLong,
            bool open
        ) = vault.positions(trader);

        assertEq(collateral, 1 ether);
        assertEq(size, 2 ether);
        assertEq(entryPrice, initialPrice);
        assertTrue(isLong);
        assertTrue(open);
    }

    function testOpenShortPosition() public {
        vm.prank(trader);

        vault.openPosition{value: 1 ether}(
            3,
            false
        );

        (
            uint256 collateral,
            uint256 size,
            uint256 entryPrice,
            bool isLong,
            bool open
        ) = vault.positions(trader);

        assertEq(collateral, 1 ether);
        assertEq(size, 3 ether);
        assertEq(entryPrice, initialPrice);
        assertFalse(isLong);
        assertTrue(open);
    }

    function testInitialPnlIsZero() public {
        vm.prank(trader);

        vault.openPosition{value: 1 ether}(
            2,
            true
        );

        int256 pnl = vault.getPnl(trader);

        assertEq(pnl, 0);
    }

    function testRevertWhenPositionAlreadyOpen() public {
        vm.startPrank(trader);

        vault.openPosition{value: 1 ether}(
            2,
            true
        );

        vm.expectRevert(
            MarginVault.PositionAlreadyOpen.selector
        );

        vault.openPosition{value: 1 ether}(
            2,
            true
        );

        vm.stopPrank();
    }

    function testRevertWhenZeroCollateral() public {
        vm.prank(trader);

        vm.expectRevert(
            MarginVault.ZeroAmount.selector
        );

        vault.openPosition(
            2,
            true
        );
    }

    function testRevertWhenLeverageIsZero() public {
        vm.prank(trader);

        vm.expectRevert(
            MarginVault.LeverageTooHigh.selector
        );

        vault.openPosition{value: 1 ether}(
            0,
            true
        );
    }

    function testRevertWhenLeverageExceedsMaximum() public {
        vm.prank(trader);

        vm.expectRevert(
            MarginVault.LeverageTooHigh.selector
        );

        vault.openPosition{value: 1 ether}(
            11,
            true
        );
    }
}
