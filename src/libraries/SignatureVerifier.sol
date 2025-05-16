// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {ECDSAUpgradeable} from "@openzeppelin-upgrades/contracts/utils/cryptography/ECDSAUpgradeable.sol";
import {IERC1271Upgradeable} from "@openzeppelin-upgrades/contracts/interfaces/IERC1271Upgradeable.sol";

library SignatureVerifier {
    using ECDSAUpgradeable for bytes32;
    
    // Constants
    bytes4 private constant ERC1271_MAGIC_VALUE = 0x1626ba7e;

    /**
     * @dev Verifies if a signature is valid for a given message hash and signer
     * @param messageHash The hash of the message to verify
     * @param signature The signature to verify
     * @param signer The address that allegedly signed the message
     * @return Whether the signature is valid
     */
    function isValidSignature(
        bytes32 messageHash,
        bytes memory signature,
        address signer
    ) internal view returns (bool) {
        bytes32 ethSignedMessageHash = messageHash.toEthSignedMessageHash();

        // Try regular EOA signature verification
        if (ethSignedMessageHash.recover(signature) == signer) {
            return true;
        }

        // Try ERC1271 verification for smart contract wallets
        try
            IERC1271Upgradeable(signer).isValidSignature(messageHash, signature)
        returns (bytes4 magicValue) {
            return magicValue == ERC1271_MAGIC_VALUE;
        } catch {
            return false;
        }
    }
} 