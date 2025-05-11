// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title RWAMetadata
 * @notice Library for handling RWA token metadata
 * @dev This library provides a struct and functions for managing RWA metadata
 */
library RWAMetadata {
    /**
     * @notice Struct to store RWA metadata
     * @param institutionName Name of the issuing institution
     * @param institutionAddress Address of the issuing institution
     * @param documentURI IPFS URI for supporting documents
     * @param imageURI IPFS URI for RWA image
     * @param totalRWASupply Total supply of RWA tokens
     * @param pricePerRWA Price per RWA token
     * @param description Brief description of the RWA
     */
    struct Metadata {
        string institutionName;
        string institutionAddress;
        string documentURI;
        string imageURI;
        uint256 totalRWASupply;
        uint256 pricePerRWA;
        string description;
    }

    /**
     * @notice Creates a new metadata struct
     * @param institutionName_ Name of the issuing institution
     * @param institutionAddress_ Address of the issuing institution
     * @param documentURI_ IPFS URI for supporting documents
     * @param imageURI_ IPFS URI for RWA image
     * @param totalRWASupply_ Total supply of RWA tokens
     * @param pricePerRWA_ Price per RWA token
     * @param description_ Brief description of the RWA
     * @return metadata The created metadata struct
     */
    function createMetadata(
        string memory institutionName_,
        string memory institutionAddress_,
        string memory documentURI_,
        string memory imageURI_,
        uint256 totalRWASupply_,
        uint256 pricePerRWA_,
        string memory description_
    ) internal pure returns (Metadata memory metadata) {
        return Metadata({
            institutionName: institutionName_,
            institutionAddress: institutionAddress_,
            documentURI: documentURI_,
            imageURI: imageURI_,
            totalRWASupply: totalRWASupply_,
            pricePerRWA: pricePerRWA_,
            description: description_
        });
    }

    /**
     * @notice Updates the price in a metadata struct
     * @param metadata The metadata struct to update
     * @param newPrice The new price to set
     */
    function updatePrice(Metadata storage metadata, uint256 newPrice) internal {
        metadata.pricePerRWA = newPrice;
    }

    /**
     * @notice Updates the document URI in a metadata struct
     * @param metadata The metadata struct to update
     * @param newDocumentURI The new document URI to set
     */
    function updateDocumentURI(Metadata storage metadata, string memory newDocumentURI) internal {
        metadata.documentURI = newDocumentURI;
    }

    /**
     * @notice Updates the image URI in a metadata struct
     * @param metadata The metadata struct to update
     * @param newImageURI The new image URI to set
     */
    function updateImageURI(Metadata storage metadata, string memory newImageURI) internal {
        metadata.imageURI = newImageURI;
    }
}
