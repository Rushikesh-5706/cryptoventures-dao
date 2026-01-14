// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract CVDelegationFixed {
    mapping(address => address) public delegateOf;
    mapping(address => uint256) public receivedPower;

    event Delegated(address indexed from, address indexed to);
    event Revoked(address indexed from);

    function delegate(address to) external {
        require(to != msg.sender, "Self");
        delegateOf[msg.sender] = to;
        emit Delegated(msg.sender, to);
    }

    function revoke() external {
        delegateOf[msg.sender] = address(0);
        emit Revoked(msg.sender);
    }
}
