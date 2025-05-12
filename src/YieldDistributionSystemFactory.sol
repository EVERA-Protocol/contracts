// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./YieldDistributionSystem.sol";

/**
 * @title YieldDistributionSystemFactory
 * @notice Factory contract for deploying YieldDistributionSystem contracts for RWA tokens
 * @dev Allows creating new yield distribution systems tied to specific tokens
 */
contract YieldDistributionSystemFactory {
    // Mapping of token address to corresponding yield system
    mapping(address => address) public tokenToYieldSystem;

    // Array to track all created yield systems
    address[] public allYieldSystems;

    // Event emitted when a new yield system is created
    event YieldSystemCreated(address indexed token, address indexed yieldSystem, uint256 timestamp);

    /**
     * @notice Creates a new YieldDistributionSystem for a token
     * @param tokenAddress The address of the token to link with the yield system
     * @return The address of the newly created YieldDistributionSystem
     */
    function createYieldSystem(address tokenAddress) external returns (address) {
        require(tokenAddress != address(0), "Invalid token address");
        require(tokenToYieldSystem[tokenAddress] == address(0), "Yield system already exists for token");

        // Deploy a new YieldDistributionSystem
        YieldDistributionSystem yieldSystem = new YieldDistributionSystem(tokenAddress);
        address yieldSystemAddress = address(yieldSystem);

        // Store the mapping between token and yield system
        tokenToYieldSystem[tokenAddress] = yieldSystemAddress;
        allYieldSystems.push(yieldSystemAddress);

        // Transfer ownership to the caller
        yieldSystem.transferOwnership(msg.sender);

        emit YieldSystemCreated(tokenAddress, yieldSystemAddress, block.timestamp);

        return yieldSystemAddress;
    }

    /**
     * @notice Gets the YieldDistributionSystem address for a given token
     * @param tokenAddress The address of the token
     * @return The address of the associated YieldDistributionSystem, or zero if none exists
     */
    function getYieldSystem(address tokenAddress) external view returns (address) {
        return tokenToYieldSystem[tokenAddress];
    }

    /**
     * @notice Gets the number of yield systems created
     * @return The total number of yield systems created
     */
    function getYieldSystemCount() external view returns (uint256) {
        return allYieldSystems.length;
    }

    /**
     * @notice Gets all yield systems created by this factory
     * @return An array of all yield system addresses
     */
    function getAllYieldSystems() external view returns (address[] memory) {
        return allYieldSystems;
    }
}
