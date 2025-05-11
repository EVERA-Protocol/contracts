// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title IRWALaunchpad
 * @notice Interface for the RWA launchpad contract
 * @dev This interface defines the functions and events for the RWA launchpad
 */
interface IRWALaunchpad {
    /**
     * @notice Creates a new RWA token
     * @param name Token name
     * @param symbol Token symbol
     * @param institutionName Name of the issuing institution
     * @param institutionAddress Address of the issuing institution
     * @param documentURI IPFS URI for supporting documents
     * @param imageURI IPFS URI for RWA image
     * @param totalRWASupply Total supply of RWA tokens
     * @param pricePerRWA Initial price per RWA token
     * @param description Brief description of the RWA
     * @return tokenAddress Address of the newly created RWA token
     */
    function createRWAToken(
        string memory name,
        string memory symbol,
        string memory institutionName,
        string memory institutionAddress,
        string memory documentURI,
        string memory imageURI,
        uint256 totalRWASupply,
        uint256 pricePerRWA,
        string memory description
    ) external returns (address tokenAddress);

    /**
     * @notice Returns all RWA tokens created by a specific address
     * @param creator Address of the creator
     * @return Array of token addresses created by the creator
     */
    function getTokensByCreator(address creator) external view returns (address[] memory);

    /**
     * @notice Returns all RWA tokens created through this launchpad
     * @return Array of all token addresses
     */
    function getAllTokens() external view returns (address[] memory);

    /**
     * @notice Returns the total number of RWA tokens created
     * @return Total number of tokens
     */
    function getTotalTokensCount() external view returns (uint256);

    // Events
    /**
     * @notice Emitted when a new RWA token is created
     * @param creator Address of the creator
     * @param tokenAddress Address of the newly created token
     * @param name Token name
     * @param symbol Token symbol
     * @param totalSupply Total supply of tokens
     * @param initialPrice Initial price per token
     */
    event RWATokenCreated(
        address indexed creator,
        address indexed tokenAddress,
        string name,
        string symbol,
        uint256 totalSupply,
        uint256 initialPrice
    );
}
