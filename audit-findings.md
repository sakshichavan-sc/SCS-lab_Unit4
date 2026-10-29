# Smart Contract Audit Findings

## Audit Scope
- Original contract: contracts/SavingsVault.sol
- Revised contract: contracts/SavingsVaultFixed.sol
- Solidity version: 0.8.24
- Supporting evidence: Solidity tests, TypeScript integration tests, and Slither reports

## SV-01 — Reentrancy in Withdrawal
**Severity:** High  
**Location:** SavingsVault.sol — withdrawAll()  
**Status:** Fixed in revised contract

**Description:** The original function sends ETH before clearing the user's recorded balance.

**Evidence:** The external call occurs before balances[msg.sender] is set to zero.

**Impact:** A malicious recipient may re-enter the function before the balance is updated.

**Recommendation:** Apply Checks-Effects-Interactions and a reentrancy guard.

**Remediation:** The revised contract updates accounting before the external call and uses nonReentrant.

## SV-02 — Authorization Uses tx.origin
**Severity:** Medium  
**Location:** SavingsVault.sol — setFee()  
**Status:** Fixed in revised contract

**Description:** The original function authorizes fee changes using tx.origin.

**Evidence:** require(tx.origin == owner, "not owner").

**Impact:** An intermediary contract may invoke a privileged function during a transaction initiated by the owner.

**Recommendation:** Use msg.sender-based authorization.

**Remediation:** The revised contract uses an onlyOwner modifier and includes a helper-contract regression test.

## SV-03 — Missing Maximum Fee
**Severity:** High  
**Location:** SavingsVault.sol — setFee() and withdrawAll()  
**Status:** Fixed in revised contract

**Description:** The original fee setter accepts any uint256 value.

**Evidence:** The original setFee() function assigns newFeeBps without an upper-bound check.

**Impact:** An excessive fee can make withdrawals revert when the fee exceeds the deposit.

**Recommendation:** Enforce a documented maximum fee.

**Remediation:** The revised contract limits fees to 1,000 basis points (10%).

## SV-04 — Missing Zero-Address Validation
**Severity:** Medium  
**Location:** SavingsVault.sol — claimFees()  
**Status:** Fixed in revised contract

**Description:** The original fee-claiming function does not reject address(0).

**Evidence:** The recipient is not checked before the transfer.

**Impact:** Funds sent to the zero address may become unrecoverable.

**Recommendation:** Reject zero-address recipients.

**Remediation:** The revised contract reverts with ZeroAddress().

## SV-05 — External ETH Transfer Risks
**Severity:** Medium  
**Location:** SavingsVault.sol — withdrawAll() and claimFees()  
**Status:** Transfer handling improved; recipient rejection remains a design consideration

**Description:** The original contract makes external ETH transfers using call() and transfer().

**Evidence:** The withdrawal uses a low-level call; fee claiming uses transfer().

**Impact:** Recipient contracts may reject ETH and cause the relevant transaction to revert. External calls also require reentrancy review.

**Recommendation:** Check call success, protect state-changing external-call paths, and consider recipient compatibility.

**Remediation:** The revised contract checks low-level call results and applies nonReentrant to withdrawal and fee claiming.

## SV-06 — Missing Fee Administration Events
**Severity:** Low  
**Location:** SavingsVault.sol — setFee() and claimFees()  
**Status:** Fixed in revised contract

**Description:** The original contract does not emit events when fees are changed or claimed.

**Impact:** Off-chain monitoring and auditing have less event-based information.

**Recommendation:** Emit events for fee changes and fee claims.

**Remediation:** The revised contract emits FeeUpdated and FeesClaimed.

## SV-07 — Owner Not Immutable
**Severity:** Informational  
**Location:** SavingsVault.sol — owner state variable  
**Status:** Improvement implemented

**Description:** The original owner variable is not immutable, although the contract does not provide an owner-changing function.

**Impact:** This is primarily a design and gas-optimization observation, not proof of an exploitable vulnerability.

**Recommendation:** Declare the owner immutable if it must remain fixed.

**Remediation:** The revised contract declares owner as immutable.

## Overall Assessment
The revised contract implements targeted remediations for the observations above. The recorded test run reported 18 passing tests, including 256 fuzz runs.

Slither reported seven results for the original contract and thirteen results for the revised-contract analysis. Static-analysis results are not equivalent to confirmed exploitable vulnerabilities and must be reviewed in context.

Passing tests and implementing these changes do not guarantee that the contract is completely secure.
