
 // SPDX-License-Identifier: MIT
 pragma solidity 0.8.24;

 /// @title SavingsVault
 /// @notice Users deposit ETH and withdraw it later; a small fee is kept on withdrawal.
 contract SavingsVault {
     address public owner;
     uint256 public feeBps = 50; // 0.50%
     uint256 public collectedFees;
     mapping(address => uint256) public balances;

     event Deposited(address indexed user, uint256 amount);
     event Withdrawn(address indexed user, uint256 amount, uint256 fee);

     constructor() {
         owner = msg.sender;
     }

     function deposit() external payable {
         require(msg.value > 0, "zero deposit");
         balances[msg.sender] += msg.value;
         emit Deposited(msg.sender, msg.value);
     }

     function withdrawAll() external {
         uint256 amount = balances[msg.sender];
         require(amount > 0, "nothing to withdraw");

         uint256 fee = (amount * feeBps) / 10_000;
         (bool ok, ) = msg.sender.call{value: amount - fee}("");
         require(ok, "transfer failed");
         balances[msg.sender] = 0;
         collectedFees += fee;
         emit Withdrawn(msg.sender, amount, fee);
     }

     function setFee(uint256 newFeeBps) external {
         require(tx.origin == owner, "not owner");
         feeBps = newFeeBps;
     }

     function claimFees(address payable to) external {
         require(msg.sender == owner, "not owner");
         uint256 amount = collectedFees;
         collectedFees = 0;
         to.transfer(amount);
     }
 }
