// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import "../src/MarginVault.sol";
import "../src/FeeManager.sol";

contract MarginVaultTest is Test {
    MarginVault vault;
    FeeManager feeManager;

    receive() external payable {}

    function setUp() public {
        vault = new MarginVault(10, 1000);
        feeManager = new FeeManager(100);
    }

    function testConstructor() public view {
        assertEq(vault.maxLeverage(), 10);
        assertEq(vault.currentPrice(), 1000);
    }

    function testOpenLongPosition() public {
        vault.openPosition{value: 1 ether}(5, true);

        (uint256 collateral, uint256 leverage, uint256 entryPrice, bool isLong, bool isOpen) =
            vault.positions(address(this));

        assertEq(collateral, 1 ether);
        assertEq(leverage, 5);
        assertEq(entryPrice, 1000);
        assertTrue(isLong);
        assertTrue(isOpen);
    }

    function testOpenShortPosition() public {
        vault.openPosition{value: 1 ether}(3, false);

        (uint256 collateral, uint256 leverage, uint256 entryPrice, bool isLong, bool isOpen) =
            vault.positions(address(this));

        assertEq(collateral, 1 ether);
        assertEq(leverage, 3);
        assertEq(entryPrice, 1000);
        assertFalse(isLong);
        assertTrue(isOpen);
    }

    function testLongPnlProfit() public {
        vault.openPosition{value: 1 ether}(2, true);

        vault.setCurrentPrice(1100);

        int256 pnl = vault.getPnl(address(this));

        assertEq(pnl, int256(0.2 ether));
    }

    function testLongPnlLoss() public {
        vault.openPosition{value: 1 ether}(2, true);

        vault.setCurrentPrice(900);

        int256 pnl = vault.getPnl(address(this));

        assertEq(pnl, -int256(0.2 ether));
    }

    function testShortPnlProfit() public {
        vault.openPosition{value: 1 ether}(2, false);

        vault.setCurrentPrice(900);

        int256 pnl = vault.getPnl(address(this));

        assertEq(pnl, int256(0.2 ether));
    }

    function testShortPnlLoss() public {
        vault.openPosition{value: 1 ether}(2, false);

        vault.setCurrentPrice(1100);

        int256 pnl = vault.getPnl(address(this));

        assertEq(pnl, -int256(0.2 ether));
    }

    function testClosePositionReturnsCollateral() public {
        address trader = address(0x123);

        vm.deal(trader, 10 ether);

        vm.startPrank(trader);

        vault.openPosition{value: 1 ether}(5, true);

        uint256 balanceBeforeClose = trader.balance;

        vault.closePosition();

        uint256 balanceAfterClose = trader.balance;

        vm.stopPrank();

        assertEq(balanceAfterClose, balanceBeforeClose + 1 ether);
    }

    function testClosePositionWithProfit() public {
        address trader = address(0x123);

        vm.deal(trader, 10 ether);

        vm.startPrank(trader);
        vault.openPosition{value: 1 ether}(2, true);
        vm.stopPrank();

        // Liquidez suficiente para pagar colateral + profit
        vm.deal(address(vault), 2 ether);

        vault.setCurrentPrice(1100);

        uint256 balanceBeforeClose = trader.balance;

        vm.prank(trader);
        vault.closePosition();

        uint256 balanceAfterClose = trader.balance;

        assertEq(balanceAfterClose, balanceBeforeClose + 1.2 ether);
    }

    function testCannotCloseWithoutPosition() public {
        vm.expectRevert("No open position");

        vault.closePosition();
    }

    function testOpenPositionWithFee() public {
        vault.setFeeManager(address(feeManager));

        vault.openPosition{value: 1 ether}(5, true);

        (uint256 collateral,,,,) = vault.positions(address(this));

        uint256 expectedFee = (1 ether * 100) / 10_000;

        assertEq(collateral, 1 ether - expectedFee);
        assertEq(vault.accumulatedFees(), expectedFee);
    }

    function testWithdrawFees() public {
        vault.setFeeManager(address(feeManager));

        vault.openPosition{value: 1 ether}(5, true);

        uint256 expectedFee = (1 ether * 100) / 10_000;

        address payable recipient = payable(address(0x123));

        uint256 balanceBefore = recipient.balance;

        vault.withdrawFees(recipient);

        assertEq(recipient.balance, balanceBefore + expectedFee);
        assertEq(vault.accumulatedFees(), 0);
    }

    function testOnlyOwnerCanSetFeeManager() public {
        vm.prank(address(0x123));

        vm.expectRevert("Not owner");

        vault.setFeeManager(address(feeManager));
    }

    function testOnlyOwnerCanUpdatePrice() public {
        vm.prank(address(0x123));

        vm.expectRevert("Not owner");

        vault.setCurrentPrice(2000);
    }
}
