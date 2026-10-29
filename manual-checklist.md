# Manual Smart Contract Security Checklist

## Project Details
- Project: Smart Contract Security Fundamentals and Auditing
- Original Contract: contracts/SavingsVault.sol
- Revised Contract: contracts/SavingsVaultFixed.sol
- Solidity Version: 0.8.24

## 1. Access Control
**Original Result:** FAIL

The original setFee() function uses tx.origin for authorization. This can allow an intermediary contract to invoke a privileged function when the owner is induced to interact with it.

**Evidence:** SavingsVault.sol — setFee().

**Recommendation:** Use msg.sender-based owner authorization.

**Fixed Contract Result:** Addressed using the onlyOwner modifier and regression tests.

## 2. Reentrancy
**Original Result:** FAIL

The original withdrawAll() function sends ETH before clearing the user's recorded balance. A malicious recipient may re-enter before the state is updated.

**Evidence:** SavingsVault.sol — withdrawAll().

**Recommendation:** Apply Checks-Effects-Interactions and a reentrancy guard.

**Fixed Contract Result:** State is updated before the external call, and nonReentrant is applied.

## 3. Fee Bounds
**Original Result:** FAIL

The original contract allows the owner to set an unrestricted fee. An excessive fee can cause withdrawal calculations to revert.

**Evidence:** SavingsVault.sol — setFee() and withdrawAll().

**Recommendation:** Enforce a maximum fee.

**Fixed Contract Result:** MAX_FEE_BPS is 1000 (10%), and higher values revert.

## 4. Zero-Address Validation
**Original Result:** FAIL

The original claimFees() function does not reject address(0).

**Evidence:** SavingsVault.sol — claimFees().

**Recommendation:** Reject zero-address recipients.

**Fixed Contract Result:** The revised function reverts with ZeroAddress().

## 5. External Calls and Recipient Rejection
**Original Result:** REVIEW REQUIRED

The original contract uses a low-level call for withdrawals and transfer() for fee claims. Recipient contracts can reject ETH transfers, causing the relevant transaction to revert.

**Recommendation:** Check external-call success, use reentrancy protection, and consider recipient compatibility.

**Fixed Contract Result:** The revised contract checks call success and uses nonReentrant. Recipient rejection can still revert the transaction.

## 6. Arithmetic and Accounting
**Original Result:** REVIEW REQUIRED

Solidity 0.8.24 checks arithmetic overflow and underflow. However, an unrestricted fee can make the payout calculation revert.

**Recommendation:** Enforce fee bounds and test accounting invariants.

**Fixed Contract Result:** A 10% maximum fee is enforced. The existing fuzz test checks fee and payout accounting.

## 7. Events
**Original Result:** FAIL for fee administration events

The original contract does not emit events when fees are changed or claimed.

**Recommendation:** Emit events for fee updates and fee claims.

**Fixed Contract Result:** FeeUpdated and FeesClaimed events have been added.

## 8. Immutable Owner
**Original Result:** IMPROVEMENT IDENTIFIED

The original owner variable is not immutable, although the contract does not provide a function to change it.

**Recommendation:** Use immutable ownership if the owner must remain fixed after deployment.

**Fixed Contract Result:** The owner is declared immutable.

## Review Limitations
This checklist documents code-review observations and implemented changes. Tests and static analysis do not prove the absence of all vulnerabilities. Remaining static-analysis results require contextual review.
