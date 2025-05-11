// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {RWAMetadata} from "../src/libraries/RWAMetadata.sol";

contract RWAMetadataTest is Test {
    using RWAMetadata for RWAMetadata.Metadata;
    
    RWAMetadata.Metadata public metadata;
    
    // Metadata parameters
    string public institutionName = "Property Holdings Inc";
    string public institutionAddress = "123 Main St, New York, NY";
    string public documentURI = "ipfs://QmDocument";
    string public imageURI = "ipfs://QmImage";
    uint256 public totalRWASupply = 1000 * 10**18;
    uint256 public pricePerRWA = 100 * 10**18;
    string public description = "Tokenized real estate property in downtown area";
    
    function setUp() public {
        metadata = RWAMetadata.createMetadata(
            institutionName,
            institutionAddress,
            documentURI,
            imageURI,
            totalRWASupply,
            pricePerRWA,
            description
        );
    }
    
    function testCreateMetadata() public {
        // Verify metadata fields
        assertEq(metadata.institutionName, institutionName);
        assertEq(metadata.institutionAddress, institutionAddress);
        assertEq(metadata.documentURI, documentURI);
        assertEq(metadata.imageURI, imageURI);
        assertEq(metadata.totalRWASupply, totalRWASupply);
        assertEq(metadata.pricePerRWA, pricePerRWA);
        assertEq(metadata.description, description);
    }
    
    function testUpdatePrice() public {
        uint256 newPrice = 200 * 10**18;
        
        RWAMetadata.updatePrice(metadata, newPrice);
        
        assertEq(metadata.pricePerRWA, newPrice);
    }
    
    function testUpdateDocumentURI() public {
        string memory newDocumentURI = "ipfs://QmNewDocument";
        
        RWAMetadata.updateDocumentURI(metadata, newDocumentURI);
        
        assertEq(metadata.documentURI, newDocumentURI);
    }
    
    function testUpdateImageURI() public {
        string memory newImageURI = "ipfs://QmNewImage";
        
        RWAMetadata.updateImageURI(metadata, newImageURI);
        
        assertEq(metadata.imageURI, newImageURI);
    }
}
