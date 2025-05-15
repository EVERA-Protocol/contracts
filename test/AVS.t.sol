// // SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// import {Test, console} from "forge-std/Test.sol";
// import {IAVS} from "../src/interfaces/IAVS.sol";
// import {InstantSlasher} from "@eigenlayer-middleware/src/slashers/InstantSlasher.sol";
// import {IRegistryCoordinator} from "@eigenlayer-middleware/src/interfaces/IRegistryCoordinator.sol";
// import {IAllocationManagerTypes} from "@eigenlayer/contracts/interfaces/IAllocationManager.sol";
// import {IStrategy} from "@eigenlayer/contracts/interfaces/IStrategy.sol";
// import {AVS} from "../src/AVS.sol";

// contract MockInstantSlasher {
//     bool public shouldRevert = false;

//     function setShouldRevert(bool _shouldRevert) external {
//         shouldRevert = _shouldRevert;
//     }

//     function fulfillSlashingRequest(
//         address operator,
//         uint8 taskId,
//         string memory description
//     ) external returns (bool) {
//         if (shouldRevert) {
//             revert("Slashing failed");
//         }
//         return true;
//     }
// }

// contract AVSTest is Test {
//     // Contract instances
//     AVS public avs;
//     MockInstantSlasher public mockSlasher;

//     // Test accounts
//     address public admin = address(0x1);
//     address public operator = address(0x2);
//     address public user = address(0x3);
//     address public newAdmin = address(0x4);

//     // RWA token address
//     address public rwaToken = address(0x7);
//     string public assetType = "Real Estate";

//     // Task parameters
//     uint256 public taskDeadline;

//     // Setup for fork testing
//     uint256 sepoliaFork;

//     function setUp() public {
//         // Create a fork of Sepolia
//         sepoliaFork = vm.createFork(
//             "https://eth-sepolia.g.alchemy.com/v2/UCfPhTc7joIYqMspskE5rixdqPkrpC71"
//         );
//         vm.selectFork(sepoliaFork);
//         vm.rollFork(8330241); // Use the specific block

//         // Set up test environment
//         vm.startPrank(admin);

//         // Deploy mock slasher
//         mockSlasher = new MockInstantSlasher();

//         // Deploy mock AVS
//         avs = new AVS(admin, address(mockSlasher));

//         // Set task deadline for 1 day in the future
//         taskDeadline = block.timestamp + 1 days;

//         vm.stopPrank();
//     }

//     /*** Admin Tests ***/

//     function testInitialState() public {
//         assertEq(avs.admin(), admin);
//         assertEq(avs.instantSlasher(), address(mockSlasher));
//     }

//     function testChangeAdmin() public {
//         vm.prank(admin);
//         avs.changeAdmin(newAdmin);
//         assertEq(avs.admin(), newAdmin);
//     }

//     function testChangeAdmin_NotAdmin() public {
//         vm.prank(user);
//         vm.expectRevert("Only admin can call this function");
//         avs.changeAdmin(newAdmin);
//     }

//     function testChangeSlasher() public {
//         address newSlasher = address(0x8);

//         vm.prank(admin);
//         avs.changeSlasher(newSlasher);
//         assertEq(avs.instantSlasher(), newSlasher);
//     }

//     function testChangeSlasher_NotAdmin() public {
//         address newSlasher = address(0x8);

//         vm.prank(user);
//         vm.expectRevert("Only admin can call this function");
//         avs.changeSlasher(newSlasher);
//     }

//     /*** Task Creation and Response Tests ***/

//     function testCreateTask() public {
//         vm.prank(admin);
//         avs.createTask(operator, taskDeadline, rwaToken, assetType);

//         // Check task was created with correct ID
//         assertEq(avs.latestTaskNum(), 1);

//         // Retrieve the task
//         IAVS.Task memory task = avs.getTask(1);

//         // Verify task details
//         assertEq(task.deadline, taskDeadline);
//         assertEq(task.operator, operator);
//         assertEq(task.rwaToken, rwaToken);
//         assertEq(task.assetType, assetType);
//         assertEq(task.taskCreatedBlock, uint32(block.number));
//     }

//     function testCreateTask_InvalidDeadline() public {
//         uint256 pastDeadline = block.timestamp - 1 hours;

//         vm.prank(admin);
//         vm.expectRevert("Deadline must be in future");
//         avs.createTask(operator, pastDeadline, rwaToken, assetType);
//     }

//     function testSubmitResponse() public {
//         // Create a task
//         vm.prank(admin);
//         avs.createTask(operator, taskDeadline, rwaToken, assetType);

//         uint256 taskId = 1;
//         bytes32 storedTaskHash = avs.allTaskHashes(uint32(taskId));
//         string memory metadataURI = "ipfs://QmTaskResponse";
//         IAVS.VerificationStatus status = IAVS.VerificationStatus.LEGIT;
//         bytes memory signature = new bytes(65);

//         // Submit response
//         vm.prank(operator);
//         avs.submitResponse(
//             taskId,
//             storedTaskHash,
//             metadataURI,
//             status,
//             signature
//         );

//         // Verify response was recorded
//         IAVS.TaskResponse memory response = avs.getTaskResponse(taskId);
//         assertEq(response.metadataURI, metadataURI);
//         assertEq(uint(response.status), uint(status));
//         assertEq(response.taskFinishedBlock, uint32(block.number));
//     }

//     function testSubmitResponse_NotOperator() public {
//         // Create a task
//         vm.prank(admin);
//         avs.createTask(operator, taskDeadline, rwaToken, assetType);

//         uint256 taskId = 1;
//         bytes32 storedTaskHash = avs.allTaskHashes(uint32(taskId));
//         string memory metadataURI = "ipfs://QmTaskResponse";
//         IAVS.VerificationStatus status = IAVS.VerificationStatus.LEGIT;
//         bytes memory signature = new bytes(65);

//         // Try to submit as non-operator
//         vm.prank(user);
//         vm.expectRevert("Not assigned operator");
//         avs.submitResponse(
//             taskId,
//             storedTaskHash,
//             metadataURI,
//             status,
//             signature
//         );
//     }

//     function testSubmitResponse_TaskExpired() public {
//         // Create a task with short deadline
//         uint256 shortDeadline = block.timestamp + 1 minutes;

//         vm.prank(admin);
//         avs.createTask(operator, shortDeadline, rwaToken, assetType);

//         uint256 taskId = 1;
//         bytes32 storedTaskHash = avs.allTaskHashes(uint32(taskId));
//         string memory metadataURI = "ipfs://QmTaskResponse";
//         IAVS.VerificationStatus status = IAVS.VerificationStatus.LEGIT;
//         bytes memory signature = new bytes(65);

//         // Fast forward past deadline
//         vm.warp(shortDeadline + 1);

//         // Try to submit after deadline
//         vm.prank(operator);
//         vm.expectRevert("Task deadline passed");
//         avs.submitResponse(
//             taskId,
//             storedTaskHash,
//             metadataURI,
//             status,
//             signature
//         );
//     }

//     /*** Slashing Tests ***/

//     function testRaiseSlashing() public {
//         // Create a task
//         vm.prank(admin);
//         avs.createTask(operator, taskDeadline, rwaToken, assetType);

//         uint256 taskId = 1;
//         string memory reasonMetadata = "Operator provided false verification";

//         // Raise slashing
//         vm.prank(admin);
//         bool result = avs.raiseSlashing(taskId, reasonMetadata);

//         // Check result
//         assertTrue(result);

//         // Check slashing info
//         IAVS.SlashingInfo memory info = avs.getSlashingInfo(taskId);
//         assertEq(info.reporter, admin);
//         assertEq(info.reasonMetadata, reasonMetadata);
//         assertTrue(info.processed);
//     }

//     function testRaiseSlashing_NotAdmin() public {
//         // Create a task
//         vm.prank(admin);
//         avs.createTask(operator, taskDeadline, rwaToken, assetType);

//         uint256 taskId = 1;
//         string memory reasonMetadata = "Operator provided false verification";

//         // Try to raise slashing as non-admin
//         vm.prank(user);
//         vm.expectRevert("Only admin can call this function");
//         avs.raiseSlashing(taskId, reasonMetadata);
//     }

//     function testRaiseSlashing_SlasherFails() public {
//         // Create a task
//         vm.prank(admin);
//         avs.createTask(operator, taskDeadline, rwaToken, assetType);

//         uint256 taskId = 1;
//         string memory reasonMetadata = "Operator provided false verification";

//         // Make slasher fail
//         mockSlasher.setShouldRevert(true);

//         // Raise slashing
//         vm.prank(admin);
//         bool result = avs.raiseSlashing(taskId, reasonMetadata);

//         // Should still return true
//         assertTrue(result);

//         // But processed flag should be false
//         IAVS.SlashingInfo memory info = avs.getSlashingInfo(taskId);
//         assertFalse(info.processed);
//     }

//     function testRaiseSlashing_AlreadyProcessed() public {
//         // Create a task
//         vm.prank(admin);
//         avs.createTask(operator, taskDeadline, rwaToken, assetType);

//         uint256 taskId = 1;
//         string memory reasonMetadata = "Operator provided false verification";

//         // Raise slashing first time
//         vm.prank(admin);
//         avs.raiseSlashing(taskId, reasonMetadata);

//         // Try to raise again
//         vm.prank(admin);
//         vm.expectRevert("Slashing already processed");
//         avs.raiseSlashing(taskId, reasonMetadata);
//     }
// }
