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
    address avsDirectory = 0xB8F3221Bf7974F1682d0AcBC2F40ba3597db3151;
    address stakeRegistry;
    address rewardsCoordinator = 0x16A26002119C039DE57b051c8e8871b0AE8f2768;
    address delegationManager = 0xff8e53df56550c27bF6A8BAADC839eD86A7c99d7;
    address allocManager = 0x51FF720105655c01BE501523Dd5C2642ce53FDde;

    AVS public avs;

    function setUp() public {
        vm.createSelectFork(
            "https://base-sepolia.g.alchemy.com/v2/UCfPhTc7joIYqMspskE5rixdqPkrpC71",
            25779993
        );

        // set stake registry for the first time
        stakeRegistry = msg.sender;

        console.log(stakeRegistry);

        avs = new AVS(
            avsDirectory,
            stakeRegistry,
            rewardsCoordinator,
            delegationManager,
            allocManager
        );

        // avs.initialize(msg.sender, msg.sender, msg.sender);

        console.log(address(avs));
    }

    function test_GetAdmin() public {}
}
