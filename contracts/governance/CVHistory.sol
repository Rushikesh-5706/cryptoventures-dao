// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract CVHistory {
    mapping(uint256 => address[]) public voters;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
}
