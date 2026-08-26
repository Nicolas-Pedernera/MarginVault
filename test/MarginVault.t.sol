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
        vault = new MarginVault(10);
        feeManager = new FeeManager(100); // 1%
    }

    function testConstructor() public view {
        assertEq(vault.maxLeverage(), 10);
    }

    function testOpenLongPosition() public {
        vault.openPosition{value: 1 ether}(5, true);

        (uint256 collateral, uint256 leverage, bool isLong, bool isOpen) =
            vault.positions(address(this));

        assertEq(collateral, 1 ether);
        assertEq(leverage, 5);
        assertTrue(isLong);
        assertTrue(isOpen);
    }

    function testOpenShortPosition() public {
        vault.openPosition{value: 1 ether}(3, false);

        (uint256 collateral, uint256 leverage, bool isLong, bool isOpen) =
            vault.positions(address(this));

        assertEq(collateral, 1 ether);
        assertEq(leverage, 3);
        assertFalse(isLong);
        assertTrue(isOpen);
    }

    function testGetPnl() public view {
        uint256 pnl = vault.getPnl(address(this));
        assertEq(pnl, 0);
    }

    function testClosePosition() public {
        vault.openPosition{value: 1 ether}(5, true);

        vault.closePosition();

        (,,, bool isOpen) = vault.positions(address(this));

        assertFalse(isOpen);
    }

    function testCannotCloseWithoutPosition() public {
        vm.expectRevert("No open position");

        vault.closePosition();
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

    function testOpenPositionWithFee() public {
        vault.setFeeManager(address(feeManager));

        vault.openPosition{value: 1 ether}(5, true);

        (uint256 collateral,,,) = vault.positions(address(this));

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
}
