// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title CVStake
 * @notice Manages ETH deposits and converts them into governance voting power
 * @dev Voting power is derived using anti-whale square-root scaling
 */
contract CVStake {

    /// @notice Raw ETH deposited by each user
    mapping(address => uint256) public stake;

    /// @notice Total ETH deposited into the DAO
    uint256 public totalStake;

    /// @notice Emitted when a user deposits ETH
    event Deposited(address indexed user, uint256 amount);

    /**
     * @notice Deposit ETH to gain governance power
     * @dev Voting power grows sub-linearly to prevent whale dominance
     */
    function deposit() external payable {
        require(msg.value > 0, "Zero deposit");
        stake[msg.sender] += msg.value;
        totalStake += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /**
     * @notice Returns a user's voting power
     * @dev Uses square-root based scaling
     * @param user Address to query
     */
    function votingPower(address user) public view virtual returns (uint256) {
        return _sqrt(stake[user]);
    }

    /**
     * @notice Returns total DAO voting power
     */
    function totalPower() public view virtual returns (uint256) {
        return _sqrt(totalStake);
    }

    /**
     * @dev Integer square-root function
     */
    function _sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

