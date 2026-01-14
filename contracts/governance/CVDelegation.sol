// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract CVDelegation {
    mapping(address => address) public delegateTo;
    mapping(address => uint256) public delegatedPower;

    event Delegated(address indexed from, address indexed to);
    event Revoked(address indexed from);

    function delegate(address to) external {
        delegateTo[msg.sender] = to;
        emit Delegated(msg.sender, to);
    }

    function revoke() external {
        delegateTo[msg.sender] = address(0);
        emit Revoked(msg.sender);
    }
}
