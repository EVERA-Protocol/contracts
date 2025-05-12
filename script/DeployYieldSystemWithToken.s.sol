// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {YieldDistributionSystem} from "../src/yieldDistributionSystem.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title TestToken
 * @notice Simple ERC20 token for testing the YieldDistributionSystem
 */
contract TestToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("Test Token", "TEST") {
        _mint(msg.sender, initialSupply);
    }
}

/**
 * @title DeployYieldSystemWithToken
 * @notice Script to deploy both a test token and the YieldDistributionSystem contract
 * @dev This script deploys a test token and the YieldDistributionSystem in a single transaction
 */
contract DeployYieldSystemWithToken is Script {
    // File to store deployed addresses
    string constant ADDRESSES_FILE = "yield_system_with_token_addresses.json";

    // Initial token supply: 1 million tokens
    uint256 constant INITIAL_SUPPLY = 1_000_000 * 10 ** 18;

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

        // Deploy Test Token
        TestToken token = new TestToken(INITIAL_SUPPLY);
        address tokenAddress = address(token);
        console.log("Test Token deployed at:", tokenAddress);
        console.log("Initial supply:", INITIAL_SUPPLY / 10 ** 18, "TEST");

        // Deploy YieldDistributionSystem
        YieldDistributionSystem yieldSystem = new YieldDistributionSystem(tokenAddress);
        address yieldSystemAddress = address(yieldSystem);
        console.log("YieldDistributionSystem deployed at:", yieldSystemAddress);

        // Stop broadcasting transactions
        vm.stopBroadcast();

        // Save deployed addresses to a file
        saveAddresses(tokenAddress, yieldSystemAddress);
    }

    function saveAddresses(address tokenAddress, address yieldSystemAddress) internal {
        // Create JSON string with deployed addresses
        string memory json = string(
            abi.encodePacked(
                "{\n",
                '  "token": "',
                vm.toString(tokenAddress),
                '",\n',
                '  "yieldSystem": "',
                vm.toString(yieldSystemAddress),
                '",\n',
                '  "network": "',
                getNetworkName(),
                '",\n',
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

    function getNetworkName() internal view returns (string memory) {
        // Get chain ID
        uint256 chainId = block.chainid;

        // Return network name based on chain ID
        if (chainId == 1) return "Ethereum Mainnet";
        if (chainId == 5) return "Goerli Testnet";
        if (chainId == 11155111) return "Sepolia Testnet";
        if (chainId == 137) return "Polygon Mainnet";
        if (chainId == 80001) return "Mumbai Testnet";
        if (chainId == 42161) return "Arbitrum One";
        if (chainId == 421613) return "Arbitrum Goerli";
        if (chainId == 10) return "Optimism";
        if (chainId == 420) return "Optimism Goerli";
        if (chainId == 56) return "BNB Smart Chain";
        if (chainId == 97) return "BNB Testnet";
        if (chainId == 43114) return "Avalanche C-Chain";
        if (chainId == 43113) return "Avalanche Fuji";
        if (chainId == 31337) return "Anvil Local";
        if (chainId == 84532) return "Base Sepolia";

        // Default to chain ID if network is unknown
        return vm.toString(chainId);
    }
}
