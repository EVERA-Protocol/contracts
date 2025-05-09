// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {RWAToken} from "../src/RWAToken.sol";

contract DeployRWAToken is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Token parameters
        string memory name = "Standalone Real Estate Token";
        string memory symbol = "SRET";
        string memory institutionName = "Standalone Property Holdings Inc";
        string memory institutionAddress = "123 Main St, New York, NY";
        string memory documentURI = "ipfs://QmStandaloneDocument";
        string memory imageURI = "ipfs://QmStandaloneImage";
        uint256 totalRWASupply = 1000 * 10**18;
        uint256 pricePerRWA = 100 * 10**18;
        string memory description = "Standalone tokenized real estate property in downtown area";

        vm.startBroadcast(deployerPrivateKey);

        // Deploy RWAToken directly
        RWAToken token = new RWAToken(
            name,
            symbol,
            institutionName,
            institutionAddress,
            documentURI,
            imageURI,
            totalRWASupply,
            pricePerRWA,
            description,
            msg.sender // Owner is the deployer
        );

        console.log("Standalone RWA token deployed at:", address(token));

        vm.stopBroadcast();
    }
}
