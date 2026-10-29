# Smart Contract Security Fundamentals and Auditing

A hands-on smart contract security lab focused on testing, static analysis, vulnerability identification, and remediation using Solidity, Hardhat, OpenZeppelin, and Slither.

This project demonstrates a practical security-auditing workflow: testing an original smart contract, identifying potential weaknesses, documenting audit observations, implementing fixes, and validating the revised contract with regression and integration tests.

## Project Overview

The project reviews a savings vault smart contract that allows users to deposit Ether, withdraw their balances after a fee, and allows the owner to configure fees and claim collected fees.

Two implementations are included:

- **`SavingsVault.sol`** — the original contract used as the security-audit baseline.
- **`SavingsVaultFixed.sol`** — the revised implementation with security improvements.

The original contract is retained for comparison and testing. The revised contract demonstrates how common smart contract security issues can be addressed.

## Technology Stack

- Solidity 0.8.24
- Hardhat 3.21.1
- TypeScript integration tests
- OpenZeppelin Contracts 5.x
- Slither 0.11.6
- `forge-std` for Solidity testing utilities
- Node.js and npm

## Project Structure

```text
SCS-LAB_unit4/
├── contracts/
│   ├── SavingsVault.sol
│   └── SavingsVaultFixed.sol
├── test/
│   ├── SavingsVault.t.sol
│   ├── SavingsVault.ts
│   └── SavingsVaultFixed.t.sol
├── screenshots/
│   ├── 01-tests-passing.png
│   ├── 02-original-slither-findings.png
│   └── 03-fixed-contract-tests.png
├── audit-summary.md
├── slither-report.txt
├── slither-fixed-report.txt
├── hardhat.config.ts
├── package.json
├── package-lock.json
├── .gitignore
└── README.md
```

*Note: The screenshot filenames above are suggested names. Add the actual screenshots before submitting. The tree may differ slightly depending on the files present in your local project.*

## Security Findings and Remediation

The original contract was reviewed for common smart contract vulnerabilities and unsafe implementation patterns.

| Finding | Observation in original contract | Remediation |
|---|---|---|
| Reentrancy risk | Withdrawal makes an external call before resetting the user's balance. | Apply Checks-Effects-Interactions and `ReentrancyGuard`. |
| Weak access control | `setFee()` uses `tx.origin` for authorization. | Use owner authorization based on `msg.sender`. |
| Missing zero-address validation | `claimFees()` does not reject a zero-address recipient. | Reject `address(0)`. |
| Unrestricted fee | The original fee setter has no maximum fee limit. | Limit the fee to 1,000 basis points (10%). |
| Mutable owner variable | The owner variable is not declared immutable. | Declare the owner as `immutable`. |
| Missing fee-update event | Fee changes are not emitted as events. | Add `FeeUpdated`. |
| Missing fee-claim event | Successful fee claims are not emitted as events. | Add `FeesClaimed`. |
| External call handling | ETH transfers use low-level calls or `transfer`, which require careful review. | Check transfer success and revert on failure. |

The original Slither analysis reported seven results across the following detector categories:

- `reentrancy-eth`
- `tx-origin`
- `missing-zero-check`
- `reentrancy-benign`
- `reentrancy-events`
- `low-level-calls`
- `immutable-states`

The three reentrancy-related results concern the same withdrawal flow and should not be interpreted as three separate confirmed exploits. Static-analysis results are indicators for investigation and must be interpreted in the context of the code.

## Improvements in SavingsVaultFixed.sol

The revised contract implements the following protections:

### 1. Access control

Owner-only functions use `msg.sender` through an `onlyOwner` modifier. This avoids the authorization weakness associated with using `tx.origin`.

### 2. Reentrancy protection

The withdrawal and fee-claiming functions use OpenZeppelin's `ReentrancyGuard`. In the withdrawal function, the user's balance and collected fees are updated before the external ETH transfer.

### 3. Fee limit

The revised contract defines `MAX_FEE_BPS` as 1,000 basis points, equivalent to a maximum fee of 10%. Attempts to set a higher fee revert.

### 4. Zero-address validation

The fee-claiming function rejects `address(0)` as the recipient.

### 5. Checked ETH transfers

Low-level ETH transfers check the returned success value. If a transfer fails, the transaction reverts.

### 6. Events

The revised implementation includes `FeeUpdated` and `FeesClaimed` events to make fee-related actions easier to track.

### 7. Immutable ownership

The owner is declared `immutable`, because the owner address is set during deployment and is not intended to change.

## Testing and Verification

The project includes Solidity tests, a fuzz test, TypeScript integration tests, and regression tests for the revised contract.

Run the complete test suite from the project root:

```bash
npx hardhat test
```

### Recorded test results

**18 tests passed:**

- 14 Solidity tests passed.
- 4 TypeScript integration tests passed.
- The fuzz test completed 256 runs successfully.

### Original contract tests

The original contract tests cover:

- Depositing Ether and updating balances.
- Withdrawing the deposited amount after the fee.
- Rejection of zero-value deposits.
- Owner fee configuration.
- Rejection of unauthorized fee claims.
- Fee collection and accounting.
- A fuzz property checking that the fee and payout add up to the deposited amount.

### Revised contract regression tests

The revised contract tests cover:

- The owner can update the fee.
- A non-owner cannot update the fee.
- A helper contract cannot exploit `tx.origin`-based authorization.
- Fees above the maximum are rejected.
- Fee claims to the zero address are rejected.
- Withdrawal updates the balance and collected-fee accounting correctly.

The recorded passing tests provide evidence that these tested behaviors work as expected. They do not prove the absence of all possible vulnerabilities.

## Static Analysis with Slither

Slither was used to analyze the original and revised contracts.

### Analyze the original contract

```bash
slither contracts/SavingsVault.sol
```

The original report is saved as:

`slither-report.txt`

### Analyze the revised contract

Run the following command from the project root in the WSL/Linux environment:

```bash
slither contracts/SavingsVaultFixed.sol --solc-remaps "@openzeppelin/=$(pwd)/node_modules/@openzeppelin/"
```

The revised-contract report is saved as:

`slither-fixed-report.txt`

### Interpreting the reports

The original contract analysis reported seven results.

The revised-contract analysis reported 13 results across the analyzed compilation, including findings related to assembly, compiler-version checks, pragmas, and low-level calls. Some results originate from imported OpenZeppelin dependency code rather than from the revised vault itself.

The remaining results require contextual review. A checked low-level call is not automatically a vulnerability, and a static-analysis warning is not by itself proof of an exploitable issue.

The direct contract-analysis command was used to generate the revised report because the full-project Slither Hardhat parser encountered a path-resolution error in the WSL environment.

## Audit Summary

The file `audit-summary.md` contains a summary of the original findings, the changes made to the revised contract, test results, and the remaining static-analysis considerations.

The files `slither-report.txt` and `slither-fixed-report.txt` provide the corresponding static-analysis output.

## Screenshots

Add genuine screenshots from your own terminal or code editor to the `screenshots/` folder.

Recommended screenshots:

1. **Test results:** Show the output of `npx hardhat test`, including the Solidity tests, the fuzz test's 256 runs, the TypeScript tests, and the final `18 passing` result.
2. **Original Slither findings:** Show the original analysis output, including the detector categories and the seven-result summary.
3. **Revised contract verification:** Show the six passing `SavingsVaultFixed` regression tests. If space permits, include the relevant revised-contract security protections in your editor.

These screenshots provide visual evidence of the work completed. Ensure that terminal output and code are readable.

## Running the Project

### Prerequisites

Install the following tools:

- Node.js compatible with the project
- npm
- Python and Slither for static analysis

### Install dependencies

From the project root:

```bash
npm install
```

### Run tests

```bash
npx hardhat test
```

### Run static analysis

Original contract:

```bash
slither contracts/SavingsVault.sol
```

Revised contract:

```bash
slither contracts/SavingsVaultFixed.sol --solc-remaps "@openzeppelin/=$(pwd)/node_modules/@openzeppelin/"
```

Run these commands in the appropriate environment. In this project, the tests and Slither analysis were run using WSL/Linux.

## Conclusion

This lab demonstrates a practical smart contract security workflow: establish a baseline, run automated tests and static analysis, identify and document potential weaknesses, implement targeted fixes, and validate the revised implementation with regression tests.

The revised vault improves access control, withdrawal accounting, reentrancy protection, fee validation, event logging, and transfer failure handling.

Passing tests and static analysis are useful verification steps, but they do not guarantee that a smart contract is completely secure. Further review and testing are needed before deploying a contract that manages real funds.
