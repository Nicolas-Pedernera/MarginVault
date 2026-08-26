// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/FeeManager.sol";

contract FeeManagerTest is Test {
    FeeManager feeManager;

    address newOwner = address(0xBEEF);
    address attacker = address(0xBAD);

    function setUp() public {
        feeManager = new FeeManager(100);
    }

    function testInitialValues() public view {
        assertEq(feeManager.owner(), address(this));
        assertEq(feeManager.feePercentage(), 100);
        assertEq(feeManager.pendingOwner(), address(0));
    }

    function testUpdateFee() public {
        feeManager.updateFee(500);
        assertEq(feeManager.feePercentage(), 500);
    }

    function testCalculateFee() public view {
        uint256 fee = feeManager.calculateFee(10_000);
        assertEq(fee, 100);
    }

    function testTransferOwnership() public {
        feeManager.transferOwnership(newOwner);

        assertEq(feeManager.pendingOwner(), newOwner);

        vm.prank(newOwner);
        feeManager.acceptOwnership();

        assertEq(feeManager.owner(), newOwner);
        assertEq(feeManager.pendingOwner(), address(0));
    }

    function testOnlyOwnerCannotUpdateFee() public {
        vm.prank(attacker);
        vm.expectRevert(FeeManager.NotOwner.selector);
        feeManager.updateFee(500);
    }
}
