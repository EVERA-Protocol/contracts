// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./interfaces/IRWAToken.sol";
import "./libraries/RWAMetadata.sol";
import "./libraries/RWAConstants.sol";

/**
 * @title RWAToken
 * @notice ERC20 token representing a Real World Asset with extended metadata
 * @dev Implements IRWAToken interface and uses RWAMetadata library
 */
contract RWAToken is ERC20, ERC20Burnable, Ownable, Pausable, ReentrancyGuard, IRWAToken {
    // RWA Metadata
    RWAMetadata.Metadata private _metadata;

    /**
     * @notice Creates a new RWA token
     * @param name_ Token name
     * @param symbol_ Token symbol
     * @param institutionName_ Name of the issuing institution
     * @param institutionAddress_ Address of the issuing institution
     * @param documentURI_ IPFS URI for supporting documents
     * @param imageURI_ IPFS URI for RWA image
     * @param totalRWASupply_ Total supply of RWA tokens
     * @param pricePerRWA_ Initial price per RWA token
     * @param description_ Brief description of the RWA
     * @param owner_ Owner of the token contract
     */
    constructor(
        string memory name_,
        string memory symbol_,
        string memory institutionName_,
        string memory institutionAddress_,
        string memory documentURI_,
        string memory imageURI_,
        uint256 totalRWASupply_,
        uint256 pricePerRWA_,
        string memory description_,
        address owner_
    ) ERC20(name_, symbol_) Ownable(owner_) {
        // Validate inputs
        _validateInputs(
            name_,
            symbol_,
            institutionName_,
            institutionAddress_,
            totalRWASupply_,
            pricePerRWA_,
            owner_
        );

        // Initialize metadata
        _metadata = RWAMetadata.createMetadata(
            institutionName_,
            institutionAddress_,
            documentURI_,
            imageURI_,
            totalRWASupply_,
            pricePerRWA_,
            description_
        );

        // Mint the total supply to the owner
        _mint(owner_, totalRWASupply_);
    }

    /**
     * @dev Validates the input parameters for token creation
     * @param name_ Token name
     * @param symbol_ Token symbol
     * @param institutionName_ Name of the issuing institution
     * @param institutionAddress_ Address of the issuing institution
     * @param totalRWASupply_ Total supply of RWA tokens
     * @param pricePerRWA_ Initial price per RWA token
     * @param owner_ Owner of the token contract
     */
    function _validateInputs(
        string memory name_,
        string memory symbol_,
        string memory institutionName_,
        string memory institutionAddress_,
        uint256 totalRWASupply_,
        uint256 pricePerRWA_,
        address owner_
    ) private pure {
        if (bytes(name_).length == 0 || bytes(name_).length > RWAConstants.MAX_NAME_LENGTH) {
            revert RWAConstants.EmptyString();
        }
        if (bytes(symbol_).length == 0 || bytes(symbol_).length > RWAConstants.MAX_SYMBOL_LENGTH) {
            revert RWAConstants.EmptyString();
        }
        if (bytes(institutionName_).length == 0) {
            revert RWAConstants.EmptyString();
        }
        if (bytes(institutionAddress_).length == 0) {
            revert RWAConstants.EmptyString();
        }
        if (totalRWASupply_ == 0) {
            revert RWAConstants.InvalidAmount();
        }
        if (pricePerRWA_ == 0) {
            revert RWAConstants.InvalidAmount();
        }
        if (owner_ == address(0)) {
            revert RWAConstants.ZeroAddress();
        }
    }

    /**
     * @notice Updates the price per RWA
     * @param newPrice New price per RWA
     */
    function updatePrice(uint256 newPrice) external onlyOwner {
        if (newPrice == 0) {
            revert RWAConstants.InvalidAmount();
        }

        RWAMetadata.updatePrice(_metadata, newPrice);
        emit PriceUpdated(newPrice);
    }

    /**
     * @notice Updates the document URI
     * @param newDocumentURI New document URI
     */
    function updateDocumentURI(string memory newDocumentURI) external onlyOwner {
        if (bytes(newDocumentURI).length == 0) {
            revert RWAConstants.EmptyString();
        }

        RWAMetadata.updateDocumentURI(_metadata, newDocumentURI);
        emit DocumentURIUpdated(newDocumentURI);
    }

    /**
     * @notice Pauses token transfers
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses token transfers
     */
    function unpause() external onlyOwner {
        _unpause();
    }

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
    ) {
        return (
            _metadata.institutionName,
            _metadata.institutionAddress,
            _metadata.documentURI,
            _metadata.imageURI,
            _metadata.totalRWASupply,
            _metadata.pricePerRWA,
            _metadata.description
        );
    }

    /**
     * @notice Override of the transfer function to add pausable functionality
     * @dev Checks if the contract is paused
     */
    function _update(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._update(from, to, amount);
    }

    // Getter functions for metadata fields - using a single view function is more gas efficient
    function institutionName() external view returns (string memory) {
        return _metadata.institutionName;
    }

    function institutionAddress() external view returns (string memory) {
        return _metadata.institutionAddress;
    }

    function documentURI() external view returns (string memory) {
        return _metadata.documentURI;
    }

    function imageURI() external view returns (string memory) {
        return _metadata.imageURI;
    }

    function totalRWASupply() external view returns (uint256) {
        return _metadata.totalRWASupply;
    }

    function pricePerRWA() external view returns (uint256) {
        return _metadata.pricePerRWA;
    }

    function description() external view returns (string memory) {
        return _metadata.description;
    }

    /**
     * @notice Updates the image URI
     * @param newImageURI New image URI
     */
    function updateImageURI(string memory newImageURI) external onlyOwner {
        if (bytes(newImageURI).length == 0) {
            revert RWAConstants.EmptyString();
        }

        RWAMetadata.updateImageURI(_metadata, newImageURI);
        emit ImageURIUpdated(newImageURI);
    }

    // Override burn and burnFrom functions to resolve conflicts
    function burn(uint256 amount) public override(ERC20Burnable, IRWAToken) {
        super.burn(amount);
    }

    function burnFrom(address account, uint256 amount) public override(ERC20Burnable, IRWAToken) {
        super.burnFrom(account, amount);
    }
}