// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title CVDelegationFixed
 * @notice Allows DAO members to delegate their voting power to another address
 * @dev Delegated voting power is automatically included when the delegate votes
 */
contract CVDelegationFixed {

    /// @notice Mapping of delegator → delegate
    mapping(address => address) public delegateOf;

    /// @notice Emitted when delegation changes
    event Delegated(address indexed from, address indexed to);

    /**
     * @notice Assigns voting power to another address
     * @dev Only one active delegate is allowed; setting to address(0) clears delegation
     * @param to Address that will receive voting power
     */
    function delegate(address to) external {
        delegateOf[msg.sender] = to;
        emit Delegated(msg.sender, to);
    }

    /**
     * @notice Clears any existing delegation
     * @dev Restores voting power back to the original holder
     */
    function clearDelegation() external {
        delegateOf[msg.sender] = address(0);
        emit Delegated(msg.sender, address(0));
    }
}

