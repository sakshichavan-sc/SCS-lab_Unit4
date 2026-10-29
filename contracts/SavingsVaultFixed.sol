// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract SavingsVaultFixed is ReentrancyGuard {
    address public immutable owner;
    uint256 public feeBps = 50;
    uint256 public collectedFees;

    uint256 public constant MAX_FEE_BPS = 1000;

    mapping(address => uint256) public balances;

    error NotOwner();
    error FeeTooHigh(uint256 requested, uint256 maximum);
    error ZeroAddress();
    error NothingToWithdraw();
    error TransferFailed();

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount, uint256 fee);
    event FeeUpdated(uint256 oldFeeBps, uint256 newFeeBps);
    event FeesClaimed(address indexed to, uint256 amount);

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function deposit() external payable {
        require(msg.value > 0, "zero deposit");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function withdrawAll() external nonReentrant {
        uint256 amount = balances[msg.sender];
        if (amount == 0) revert NothingToWithdraw();

        uint256 fee = (amount * feeBps) / 10_000;
        uint256 payout = amount - fee;

        // Effects before interaction: follow Checks-Effects-Interactions.
        balances[msg.sender] = 0;
        collectedFees += fee;
        emit Withdrawn(msg.sender, amount, fee);

        (bool ok, ) = msg.sender.call{value: payout}("");
        if (!ok) revert TransferFailed();
    }

    function setFee(uint256 newFeeBps) external onlyOwner {
        if (newFeeBps > MAX_FEE_BPS) {
            revert FeeTooHigh(newFeeBps, MAX_FEE_BPS);
        }

        uint256 oldFeeBps = feeBps;
        feeBps = newFeeBps;
        emit FeeUpdated(oldFeeBps, newFeeBps);
    }

    function claimFees(address payable to) external onlyOwner nonReentrant {
        if (to == address(0)) revert ZeroAddress();

        uint256 amount = collectedFees;
        collectedFees = 0;

        (bool ok, ) = to.call{value: amount}("");
        if (!ok) revert TransferFailed();

        emit FeesClaimed(to, amount);
    }
}
