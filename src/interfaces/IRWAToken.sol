// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title IRWAToken
 * @notice Interface for the RWA token contract
 * @dev This interface defines the functions and events for the RWA token
 */
interface IRWAToken {
    /**
     * @notice Updates the price per RWA
     * @param newPrice New price per RWA
     */
    function updatePrice(uint256 newPrice) external;

    /**
     * @notice Updates the document URI
     * @param newDocumentURI New document URI
     */
    function updateDocumentURI(string memory newDocumentURI) external;

    /**
     * @notice Updates the image URI
     * @param newImageURI New image URI
     */
    function updateImageURI(string memory newImageURI) external;

    /**
     * @notice Pauses token transfers
     */
    function pause() external;

    /**
     * @notice Unpauses token transfers
     */
    function unpause() external;

    /**
     * @notice Returns all metadata for the RWA token
     * @return _institutionName Name of the issuing institution
     * @return _institutionAddress Address of the issuing institution
     * @return _documentURI IPFS URI for supporting documents
     * @return _imageURI IPFS URI for RWA image
     * @return _totalRWASupply Total supply of RWA tokens
     * @return _pricePerRWA Price per RWA token
     * @return _description Brief description of the RWA
     */
    function getMetadata() external view returns (
        string memory _institutionName,
        string memory _institutionAddress,
        string memory _documentURI,
        string memory _imageURI,
        uint256 _totalRWASupply,
        uint256 _pricePerRWA,
        string memory _description
    );

    // KYC functions removed as Evera is a permissionless platform

    /**
     * @notice Burns tokens from the caller's balance
     * @param amount Amount of tokens to burn
     */
    function burn(uint256 amount) external;

    /**
     * @notice Burns tokens from a specific account (requires approval)
     * @param account Account to burn tokens from
     * @param amount Amount of tokens to burn
     */
    function burnFrom(address account, uint256 amount) external;

    // Events
    /**
     * @notice Emitted when the price per RWA is updated
     * @param newPrice New price per RWA
     */
    event PriceUpdated(uint256 newPrice);

    /**
     * @notice Emitted when the document URI is updated
     * @param newDocumentURI New document URI
     */
    event DocumentURIUpdated(string newDocumentURI);

    /**
     * @notice Emitted when the image URI is updated
     * @param newImageURI New image URI
     */
    event ImageURIUpdated(string newImageURI);

    // KYC events removed as Evera is a permissionless platform
}
