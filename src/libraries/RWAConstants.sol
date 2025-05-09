// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title RWAConstants
 * @notice Library for RWA-related constants
 * @dev This library provides constants used across the RWA contracts
 */
library RWAConstants {
    // Error messages
    /// @notice Error thrown when an operation is attempted by a non-owner
    error Unauthorized();

    /// @notice Error thrown when an operation is attempted on a paused contract
    error ContractPaused();

    // KYC errors removed as Evera is a permissionless platform

    /// @notice Error thrown when a zero address is provided
    error ZeroAddress();

    /// @notice Error thrown when an invalid amount is provided
    error InvalidAmount();

    /// @notice Error thrown when an empty string is provided
    error EmptyString();

    // Constants
    /// @notice Maximum token name length
    uint256 public constant MAX_NAME_LENGTH = 64;

    /// @notice Maximum token symbol length
    uint256 public constant MAX_SYMBOL_LENGTH = 12;

    /// @notice Maximum description length
    uint256 public constant MAX_DESCRIPTION_LENGTH = 1024;
}
