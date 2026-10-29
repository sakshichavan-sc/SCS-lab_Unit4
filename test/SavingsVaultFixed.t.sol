// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {SavingsVaultFixed} from "../contracts/SavingsVaultFixed.sol";

contract FeeSetterHelper {
    function changeFee(SavingsVaultFixed vault, uint256 fee) external {
        vault.setFee(fee);
    }
}

contract SavingsVaultFixedTest is Test {
    SavingsVaultFixed vault;
    address owner = address(0xA11CE);
    address alice = address(0xB0B);
    address recipient = address(0xCAFE);

    function setUp() public {
        vm.prank(owner);
        vault = new SavingsVaultFixed();
        vm.deal(alice, 1 ether);
    }

    function testOwnerCanSetFee() public {
        vm.prank(owner);
        vault.setFee(100);
        assertEq(vault.feeBps(), 100);
    }

    function testNonOwnerCannotSetFee() public {
        vm.prank(alice);
        vm.expectRevert(SavingsVaultFixed.NotOwner.selector);
        vault.setFee(100);
    }

    function testRejectsTxOriginOwnerWithHelperCaller() public {
        FeeSetterHelper helper = new FeeSetterHelper();

        vm.expectRevert(SavingsVaultFixed.NotOwner.selector);
        vm.prank(owner, owner);
        helper.changeFee(vault, 100);
    }

    function testFeeAboveMaximumReverts() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                SavingsVaultFixed.FeeTooHigh.selector,
                1001,
                1000
            )
        );
        vm.prank(owner);
        vault.setFee(1001);
    }

    function testClaimFeesRejectsZeroAddress() public {
        vm.expectRevert(SavingsVaultFixed.ZeroAddress.selector);
        vm.prank(owner);
        vault.claimFees(payable(address(0)));
    }

    function testWithdrawUpdatesBalanceAndCollectsFee() public {
        vm.prank(alice);
        vault.deposit{value: 1 ether}();

        vm.prank(alice);
        vault.withdrawAll();

        assertEq(vault.balances(alice), 0);
        assertEq(vault.collectedFees(), 0.005 ether);
        assertEq(alice.balance, 0.995 ether);
    }
}
