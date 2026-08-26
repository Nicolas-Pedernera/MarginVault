// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../contracts/MarginVault.sol";

contract MarginVaultTest {
    MarginVault vault;

    function setUp() public {
        vault = new MarginVault(2000);
    }

    function testOpenPosition() public {
        vault.openPosition{value: 1 wei}(2, true);

        uint256 pnl = vault.getPnl(address(this));

        assert(pnl == 0);
    }

    function testPositionAlreadyOpen() public {
        vault.openPosition{value: 1 wei}(2, true);

        try vault.openPosition{value: 1 wei}(2, true) {
            assert(false);
        } catch {
            assert(true);
        }
    }
}
