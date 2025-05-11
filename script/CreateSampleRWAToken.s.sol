// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {RWALaunchpad} from "../src/RWALaunchpad.sol";
import {RWAToken} from "../src/RWAToken.sol";

contract CreateSampleRWAToken is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address launchpadAddress = vm.envAddress("LAUNCHPAD_ADDRESS");

        // Sample token parameters
        string memory name = "Sample Real Estate Token";
        string memory symbol = "SRET";
        string memory institutionName = "Sample Property Holdings Inc";
        string memory institutionAddress = "123 Main St, New York, NY";
        string memory documentURI = "ipfs://QmSampleDocument";
        string memory imageURI = "ipfs://QmSampleImage";
        uint256 totalRWASupply = 1000 * 10 ** 18;
        uint256 pricePerRWA = 100 * 10 ** 18;
        string
            memory description = "Sample tokenized real estate property in downtown area";

        vm.startBroadcast(deployerPrivateKey);

        // Get the launchpad contract
        RWALaunchpad launchpad = RWALaunchpad(launchpadAddress);

        // Create a sample RWA token
        address tokenAddress = launchpad.createRWAToken(
            name,
            symbol,
            institutionName,
            institutionAddress,
            documentURI,
            imageURI,
            totalRWASupply,
            pricePerRWA,
            description
        );

        console.log("Sample RWA token deployed at:", tokenAddress);

        // Get the token contract
        RWAToken token = RWAToken(tokenAddress);

        vm.stopBroadcast();
    }
}
