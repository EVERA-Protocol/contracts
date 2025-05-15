// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Script, console} from "forge-std/Script.sol";
import {AVS} from "../src/AVS.sol";

contract AVSDeployer is Script {
    // EigenLayer contract addresses for Base Sepolia
    address constant AVS_DIRECTORY = 0xB8F3221Bf7974F1682d0AcBC2F40ba3597db3151;
    address constant REWARDS_COORDINATOR =
        0x16A26002119C039DE57b051c8e8871b0AE8f2768;
    address constant DELEGATION_MANAGER =
        0xff8e53df56550c27bF6A8BAADC839eD86A7c99d7;
    address constant ALLOCATION_MANAGER =
        0x51FF720105655c01BE501523Dd5C2642ce53FDde;

    function run() external {
        // Get private key for deployment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);

        // console.log(
        //     "Deploying AVS implementation from address:",
        //     deployerAddress
        // );

        vm.startBroadcast(deployerPrivateKey);

        // Deploy implementation contract
        // console.log("deployer is: ", msg.sender);
        AVS implementation = new AVS(
            AVS_DIRECTORY,
            deployerAddress,
            REWARDS_COORDINATOR,
            DELEGATION_MANAGER,
            ALLOCATION_MANAGER
        );
        console.log("AVS implementation deployed at:", address(implementation));

        // implementation.initialize(
        //     deployerAddress,
        //     deployerAddress,
        //     deployerAddress
        // );

        vm.stopBroadcast();
    }
}
