// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract CVStake {
    mapping(address => uint256) public stake;
    uint256 public totalStake;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    function deposit() external payable {
        stake[msg.sender] += msg.value;
        totalStake += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external {
        require(stake[msg.sender] >= amount, "Not enough");
        stake[msg.sender] -= amount;
        totalStake -= amount;
        payable(msg.sender).transfer(amount);
        emit Withdrawn(msg.sender, amount);
    }
}
