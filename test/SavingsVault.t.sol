
 // SPDX-License-Identifier: MIT
 pragma solidity 0.8.24;

 import {Test} from "forge-std/Test.sol";
 import {SavingsVault} from "../contracts/SavingsVault.sol";

 contract SavingsVaultTest is Test {
     SavingsVault vault;
     address owner = makeAddr("owner");
     address alice = makeAddr("alice");

     function setUp() public {
         vm.prank(owner);
         vault = new SavingsVault();
         vm.deal(alice, 10 ether);
     }

     function test_DepositCreditsSender() public {
         vm.prank(alice);
         vault.deposit{value: 1 ether}();

         assertEq(vault.balances(alice), 1 ether);
         assertEq(address(vault).balance, 1 ether);
     }

     function test_WithdrawAllPaysAmountMinusFee() public {
         vm.startPrank(alice);
         vault.deposit{value: 1 ether}();
         vault.withdrawAll();
         vm.stopPrank();

         uint256 fee = (1 ether * vault.feeBps()) / 10_000;

         assertEq(alice.balance, 10 ether - fee);
         assertEq(vault.balances(alice), 0);
         assertEq(vault.collectedFees(), fee);
     }

     function test_RevertWhen_NonOwnerClaimsFees() public {
         vm.prank(alice);
         vm.expectRevert(bytes("not owner"));
         vault.claimFees(payable(alice));
     }

     function testFuzz_FeePlusPayoutEqualsDeposit(uint96 amount) public {
         amount = uint96(bound(amount, 1, 10 ether));
         vm.deal(alice, amount);

         vm.startPrank(alice);
         vault.deposit{value: amount}();
         vault.withdrawAll();
         vm.stopPrank();

         assertLe(vault.collectedFees(), amount);
         assertEq(alice.balance + vault.collectedFees(), amount);
     }
     
function test_RevertWhen_DepositIsZero() public {
    vm.prank(alice);
    vm.expectRevert(bytes("zero deposit"));
    vault.deposit{value: 0}();
}

function test_OwnerClaimsExactFees() public {
    vm.startPrank(alice);
    vault.deposit{value: 1 ether}();
    vault.withdrawAll();
    vm.stopPrank();

    uint256 fee = vault.collectedFees();
    uint256 ownerBalanceBefore = owner.balance;

    vm.prank(owner);
    vault.claimFees(payable(owner));

    assertEq(owner.balance, ownerBalanceBefore + fee);
    assertEq(vault.collectedFees(), 0);
}

function test_RevertWhen_OwnerIsNotTxOrigin() public {
    vm.prank(owner);
    vm.expectRevert(bytes("not owner"));
    vault.setFee(100);
}

function test_OwnerCanSetFeeWhenTxOriginIsOwner() public {
    vm.prank(owner, owner);
    vault.setFee(100);

    assertEq(vault.feeBps(), 100);
}

 }
