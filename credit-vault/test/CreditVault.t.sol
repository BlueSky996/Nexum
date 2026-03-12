// SPDX- License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/CreditVault.sol";

contract CreditVaultTest is Test {
    CreditVault vault;
    
    address user1 = address(0x1);
    address user2 = address(0x2);

    function setUp() public {
        vault = new CreditVault();

        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
    }

    function testMintLimit() public {
        vm.prank(user1);
        vault.deposit{value: 1 ether}();

        vm.prank(user1);
        vault.mint(0.5 ether); // should successd . total below LTV limit

        vm.prank(user1);
        vm.expectRevert(ExceedsBorrowLimit.selector); // check if we revert for the correct reason
        vault.mint(0.1 ether); // should fail . total 0.1 above LTV limit
    }
}
