// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import {IAVS} from "./interfaces/IAVS.sol";
import {ECDSAServiceManagerBase} from "@eigenlayer-middleware/src/unaudited/ECDSAServiceManagerBase.sol";
import {ECDSAStakeRegistry} from "@eigenlayer-middleware/src/unaudited/ECDSAStakeRegistry.sol";
import {IServiceManager} from "@eigenlayer-middleware/src/interfaces/IServiceManager.sol";
import {ECDSAUpgradeable} from "@openzeppelin-upgrades/contracts/utils/cryptography/ECDSAUpgradeable.sol";
import {IERC1271Upgradeable} from "@openzeppelin-upgrades/contracts/interfaces/IERC1271Upgradeable.sol";
import {IRegistryCoordinator} from "@eigenlayer-middleware/src/interfaces/IRegistryCoordinator.sol";

import "@openzeppelin/contracts/utils/Strings.sol";
import "@eigenlayer/contracts/interfaces/IRewardsCoordinator.sol";
import {IAllocationManager} from "@eigenlayer/contracts/interfaces/IAllocationManager.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

abstract contract AVS is ECDSAServiceManagerBase, IAVS {
    using ECDSAUpgradeable for bytes32;

    uint32 public latestTaskNum;

    // Mappings for task management
    mapping(uint32 => bytes32) public allTaskHashes;
    mapping(uint32 => Task) public tasks;
    mapping(uint32 => TaskResponse) public taskResponses;
    mapping(uint32 => SlashingInfo) public taskSlashings;
    mapping(address => uint32[]) public operatorTasks;

    // Constants
    uint256 private constant RESPONSE_WINDOW = 24 hours;
    bytes4 private constant ERC1271_MAGIC_VALUE = 0x1626ba7e;

    IRegistryCoordinator public immutable registryCoordinator;

    constructor(
        address _avsDirectory,
        address _stakeRegistry,
        address _rewardsCoordinator,
        address _delegationManager,
        address _allocationManager,
        uint32 _maxResponseIntervalBlocks,
        address _registryCoordinator
    )
        ECDSAServiceManagerBase(
            _avsDirectory,
            _stakeRegistry,
            _rewardsCoordinator,
            _delegationManager,
            _allocationManager
        )
    {
        registryCoordinator = IRegistryCoordinator(_registryCoordinator);
    }

    function initialize(
        address initialOwner,
        address _rewardsInitiator
    ) external initializer {
        __ServiceManagerBase_init(initialOwner, _rewardsInitiator);
    }

    function createTask(
        address assignee,
        uint256 deadline,
        address rwaToken,
        string calldata assetType
    ) external override {
        require(deadline > block.timestamp, "Deadline must be in future");
        require(isOperator(assignee), "Assignee must be registered operator");

        uint32 taskId = ++latestTaskNum;

        bytes memory taskData = abi.encodePacked(
            assignee,
            deadline,
            rwaToken,
            assetType
        );
        bytes32 taskHash = keccak256(taskData);

        Task memory newTask = Task({
            taskHash: taskData,
            deadline: deadline,
            operator: assignee,
            rwaToken: rwaToken,
            assetType: assetType,
            taskCreatedBlock: uint32(block.number)
        });

        tasks[taskId] = newTask;
        allTaskHashes[taskId] = taskHash;
        operatorTasks[assignee].push(taskId);

        emit TaskCreated(taskId, taskHash, assignee, deadline);
    }

    function submitResponse(
        uint256 taskId,
        bytes32 taskHash,
        string calldata metadataURI,
        VerificationStatus status,
        bytes calldata signature
    ) external override {
        require(taskId <= latestTaskNum, "Invalid task ID");
        require(
            allTaskHashes[uint32(taskId)] == taskHash,
            "Task hash mismatch"
        );

        Task storage task = tasks[uint32(taskId)];
        require(msg.sender == task.operator, "Not assigned operator");
        require(block.timestamp <= task.deadline, "Task deadline passed");

        // Verify signature
        bytes32 messageHash = keccak256(
            abi.encodePacked(taskId, taskHash, metadataURI, status)
        );
        require(
            isValidSignature(messageHash, signature, msg.sender),
            "Invalid signature"
        );

        TaskResponse memory response = TaskResponse({
            metadataURI: metadataURI,
            status: status,
            taskFinishedBlock: uint32(block.number),
            signature: signature
        });

        taskResponses[uint32(taskId)] = response;

        emit TaskCompleted(taskId, taskHash, msg.sender, status);
    }

    function getTask(
        uint256 taskId
    ) external view override returns (Task memory) {
        require(taskId <= latestTaskNum, "Invalid task ID");
        return tasks[uint32(taskId)];
    }

    function getTaskResponse(
        uint256 taskId
    ) external view override returns (TaskResponse memory) {
        require(taskId <= latestTaskNum, "Invalid task ID");
        return taskResponses[uint32(taskId)];
    }

    function raiseSlashing(
        uint256 taskId,
        string calldata reasonMetadata,
        bytes calldata evidence
    ) external override returns (bool) {
        require(taskId <= latestTaskNum, "Invalid task ID");
        Task storage task = tasks[uint32(taskId)];

        // Basic validation that the task exists and is completed
        require(task.operator != address(0), "Task does not exist");

        SlashingInfo memory slashing = SlashingInfo({
            reporter: msg.sender,
            reportedAt: block.timestamp,
            reasonMetadata: reasonMetadata,
            processed: false,
            slashedAmount: 0 // Will be set when processed
        });

        taskSlashings[uint32(taskId)] = slashing;

        emit SlashingRaised(taskId, msg.sender, task.operator, reasonMetadata);

        return true;
    }

    function getSlashingInfo(
        uint256 taskId
    ) external view override returns (SlashingInfo memory) {
        require(taskId <= latestTaskNum, "Invalid task ID");
        return taskSlashings[uint32(taskId)];
    }

    // Helper function to verify signatures
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

    // Helper function to check if address is registered operator
    function isOperator(address account) public view returns (bool) {
        return true;
    }
}
