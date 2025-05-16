// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {AVS} from "../src/AVS.sol";
import {InstantSlasher} from "@eigenlayer-middleware/src/slashers/InstantSlasher.sol";
import {IAllocationManager} from "@eigenlayer/contracts/interfaces/IAllocationManager.sol";
import {ISlashingRegistryCoordinator} from "@eigenlayer-middleware/src/interfaces/ISlashingRegistryCoordinator.sol";

/**
 * @title DeployAVS
 * @dev Script to deploy AVS and its related contracts
 */
contract DeployAVS is Script {
    event AVSDeployed(address indexed avs, address indexed slasher);

    function run() external {
        // Load environment variables
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address avsDirectory = vm.envAddress("AVS_DIRECTORY");
        address stakeRegistry = vm.envAddress("STAKE_REGISTRY");
        address rewardsCoordinator = vm.envAddress("REWARDS_COORDINATOR");
        address delegationManager = vm.envAddress("DELEGATION_MANAGER");
        address allocationManager = vm.envAddress("ALLOCATION_MANAGER");
        address owner = vm.envOr("OWNER", address(this));
        address rewardsInitiator = vm.envOr("REWARDS_INITIATOR", address(this));

        // Log environment variables to verify they are loaded correctly
        console.log("Environment variables loaded:");
        console.log("AVS_DIRECTORY:", avsDirectory);
        console.log("STAKE_REGISTRY:", stakeRegistry);
        console.log("REWARDS_COORDINATOR:", rewardsCoordinator);
        console.log("DELEGATION_MANAGER:", delegationManager);
        console.log("ALLOCATION_MANAGER:", allocationManager);
        console.log("OWNER:", owner);
        console.log("REWARDS_INITIATOR:", rewardsInitiator);
        
        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy InstantSlasher with all three required parameters
        InstantSlasher instantSlasher = new InstantSlasher(
            IAllocationManager(allocationManager),
            ISlashingRegistryCoordinator(avsDirectory),
            address(this)
        );
        address slasher = address(instantSlasher);

        // Deploy AVS
        AVS avsContract = new AVS(
            avsDirectory,
            stakeRegistry,
            rewardsCoordinator,
            delegationManager,
            allocationManager
        );
        address avs = address(avsContract);

        // Try to initialize AVS (will fail if already initialized)
        // try avsContract.initialize(owner, rewardsInitiator, slasher) {
        //     console.log("AVS initialized successfully");
        // } catch {
        //     console.log("AVS already initialized or initialization failed");
        // }

        // Stop broadcasting transactions
        vm.stopBroadcast();

        // Log deployment addresses
        console.log("AVS deployed at:", avs);
        console.log("Slasher deployed at:", slasher);

        // Emit event for tracking deployments
        emit AVSDeployed(avs, slasher);
    }
} 