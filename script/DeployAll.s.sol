// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {RWALaunchpad} from "../src/RWALaunchpad.sol";
import {RWAToken} from "../src/RWAToken.sol";

/**
 * @title DeployAll
 * @notice Script to deploy all contracts and create a sample token
 * @dev This script deploys the RWALaunchpad, creates a sample RWA token,
 *      and saves the addresses to a file for future use
 */
contract DeployAll is Script {
    // File to store deployed addresses
    // string constant ADDRESSES_FILE = "deployed_addresses.json";

    // Sample token parameters
    string constant NAME = "Sample Real Estate Token";
    string constant SYMBOL = "SRET";
    string constant INSTITUTION_NAME = "Sample Property Holdings Inc";
    string constant INSTITUTION_ADDRESS = "123 Main St, New York, NY";
    string constant DOCUMENT_URI = "ipfs://QmSampleDocument";
    string constant IMAGE_URI = "ipfs://QmSampleImage";
    uint256 constant TOTAL_SUPPLY = 1000 * 10 ** 18;
    uint256 constant PRICE_PER_RWA = 100 * 10 ** 18;
    string constant DESCRIPTION = "Sample tokenized real estate property in downtown area";

    function setUp() public {
        // No setup needed
    }

    function run() public {
        // Get the private key from environment variable or use a default for local testing
        uint256 deployerPrivateKey;
        try vm.envUint("PRIVATE_KEY") returns (uint256 key) {
            deployerPrivateKey = key;
        } catch {
            // Default private key for local testing (anvil's first account)
            deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
            console.log("Using default private key for local testing");
        }

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy RWALaunchpad
        RWALaunchpad launchpad = new RWALaunchpad();
        address launchpadAddress = address(launchpad);
        console.log("RWALaunchpad deployed at:", launchpadAddress);

        // Create a sample RWA token through the launchpad
        address tokenAddress = launchpad.createRWAToken(
            NAME,
            SYMBOL,
            INSTITUTION_NAME,
            INSTITUTION_ADDRESS,
            DOCUMENT_URI,
            IMAGE_URI,
            TOTAL_SUPPLY,
            PRICE_PER_RWA,
            DESCRIPTION
        );
        console.log("Sample RWA token deployed at:", tokenAddress);

        // Stop broadcasting transactions
        vm.stopBroadcast();

        // Save deployed addresses to a file
        saveAddresses(launchpadAddress, tokenAddress);
    }

    function saveAddresses(address launchpadAddress, address tokenAddress) internal {
        // Create JSON string with deployed addresses
        string memory json = string(
            abi.encodePacked(
                "{\n",
                '  "launchpad": "',
                vm.toString(launchpadAddress),
                '",\n',
                '  "sampleToken": "',
                vm.toString(tokenAddress),
                '",\n',
                // '  "network": "', getNetworkName(), '",\n',
                '  "deployedAt": "',
                vm.toString(block.timestamp),
                '"\n',
                "}"
            )
        );

        // Save to file
        // vm.writeFile(ADDRESSES_FILE, json);
        // console.log("Deployed addresses saved to", ADDRESSES_FILE);
    }

    // function getNetworkName() internal view returns (string memory) {
    //     // Get chain ID
    //     uint256 chainId = block.chainid;

    //     // Return network name based on chain ID
    //     if (chainId == 1) return "Ethereum Mainnet";
    //     if (chainId == 5) return "Goerli Testnet";
    //     if (chainId == 11155111) return "Sepolia Testnet";
    //     if (chainId == 137) return "Polygon Mainnet";
    //     if (chainId == 80001) return "Mumbai Testnet";
    //     if (chainId == 42161) return "Arbitrum One";
    //     if (chainId == 421613) return "Arbitrum Goerli";
    //     if (chainId == 10) return "Optimism";
    //     if (chainId == 420) return "Optimism Goerli";
    //     if (chainId == 56) return "BNB Smart Chain";
    //     if (chainId == 97) return "BNB Testnet";
    //     if (chainId == 43114) return "Avalanche C-Chain";
    //     if (chainId == 43113) return "Avalanche Fuji";
    //     if (chainId == 31337) return "Anvil Local";

    //     // Default to chain ID if network is unknown
    //     return vm.toString(chainId);
    // }
}
