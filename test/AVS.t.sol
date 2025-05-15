// // SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Test, console} from "forge-std/Test.sol";
import {IAVS} from "../src/interfaces/IAVS.sol";
import {InstantSlasher} from "@eigenlayer-middleware/src/slashers/InstantSlasher.sol";
import {IRegistryCoordinator} from "@eigenlayer-middleware/src/interfaces/IRegistryCoordinator.sol";
import {IAllocationManagerTypes} from "@eigenlayer/contracts/interfaces/IAllocationManager.sol";
import {IStrategy} from "@eigenlayer/contracts/interfaces/IStrategy.sol";
import {AVS} from "../src/AVS.sol";

contract AVSTest is Test {
    address public avsDirectory = address(0);
    address public stakeRegistry = address(0);
    address public rewardsCoordinator = address(0);
    address public delegationManager = address(0);
    address public allocManager = address(0);
    address public registryCoordinator = address(0);

    AVS public avs;

    function setUp() public {
        avs = new AVS(
            avsDirectory,
            stakeRegistry,
            rewardsCoordinator,
            delegationManager,
            allocManager,
            registryCoordinator
        );
    }
}
