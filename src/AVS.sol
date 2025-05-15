// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IAVS} from "./interfaces/IAVS.sol";
import {ECDSAServiceManagerBase} from "@eigenlayer-middleware/src/unaudited/ECDSAServiceManagerBase.sol";
import {IServiceManager} from "@eigenlayer-middleware/src/interfaces/IServiceManager.sol";
import {ECDSAUpgradeable} from "@openzeppelin-upgrades/contracts/utils/cryptography/ECDSAUpgradeable.sol";
import {IERC1271Upgradeable} from "@openzeppelin-upgrades/contracts/interfaces/IERC1271Upgradeable.sol";
import {IStrategy} from "@eigenlayer/contracts/interfaces/IStrategy.sol";

import {InstantSlasher} from "@eigenlayer-middleware/src/slashers/InstantSlasher.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@eigenlayer/contracts/interfaces/IRewardsCoordinator.sol";
import {IAllocationManagerTypes} from "@eigenlayer/contracts/interfaces/IAllocationManager.sol";
import {IAllocationManager} from "@eigenlayer/contracts/interfaces/IAllocationManager.sol";

contract AVS is ECDSAServiceManagerBase, IAVS {
    using ECDSAUpgradeable for bytes32;

    uint32 public latestTaskNum;
    address public admin;
    address public instantSlasher;

    // Mappings for task management
    mapping(uint32 => bytes32) public allTaskHashes;
    mapping(uint32 => Task) public tasks;
    mapping(uint32 => TaskResponse) public taskResponses;
    mapping(uint32 => SlashingInfo) public taskSlashings;
    mapping(address => uint32[]) public operatorTasks;

    // Constants
    bytes4 private constant ERC1271_MAGIC_VALUE = 0x1626ba7e;

    // Modifiers
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    constructor(
        address _avsDirectory,
        address _stakeRegistry,
        address _rewardsCoordinator,
        address _delegationManager,
        address _allocationManager
    )
        ECDSAServiceManagerBase(
            _avsDirectory,
            _stakeRegistry,
            _rewardsCoordinator,
            _delegationManager,
            _allocationManager
        )
    {
        admin = msg.sender;
    }

    function initialize(
        address initialOwner,
        address _rewardsInitiator,
        address _slasher
    ) external initializer {
        __ServiceManagerBase_init(initialOwner, _rewardsInitiator);
        instantSlasher = _slasher;
    }

    // Admin management functions
    function changeAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "New admin cannot be zero address");
        admin = newAdmin;
    }

    function changeSlasher(address newSlasher) external onlyAdmin {
        require(newSlasher != address(0), "New slasher cannot be zero address");
        instantSlasher = newSlasher;
    }

    function createTask(
        address assignee,
        uint256 deadline,
        address rwaToken,
        string calldata assetType
    ) external override {
        require(deadline > block.timestamp, "Deadline must be in future");
        // require(isOperator(assignee), "Assignee must be registered operator");

        latestTaskNum++;
        uint32 taskId = latestTaskNum;

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
    ) external onlyAdmin returns (bool) {
        require(taskId <= latestTaskNum, "Invalid task ID");
        Task storage task = tasks[uint32(taskId)];

        // Basic validation that the task exists and is completed
        require(task.operator != address(0), "Task does not exist");

        // Check if there's already a slashing for this task
        require(
            !taskSlashings[uint32(taskId)].processed,
            "Slashing already processed"
        );

        SlashingInfo memory slashing = SlashingInfo({
            reporter: msg.sender,
            reportedAt: block.timestamp,
            reasonMetadata: reasonMetadata,
            processed: true, // Mark as processed since admin is doing it
            slashedAmount: 0 // Will be set when processed by slasher
        });

        taskSlashings[uint32(taskId)] = slashing;

        // Call the instant slasher if set
        if (instantSlasher != address(0)) {
            // Create empty arrays for strategies and wads
            IStrategy[] memory strategies = new IStrategy[](0);
            uint256[] memory wadsToSlash = new uint256[](0);

            try
                InstantSlasher(instantSlasher).fulfillSlashingRequest(
                    IAllocationManagerTypes.SlashingParams({
                        operator: task.operator,
                        operatorSetId: uint8(taskId),
                        strategies: strategies,
                        wadsToSlash: wadsToSlash,
                        description: reasonMetadata
                    })
                )
            {
                taskSlashings[uint32(taskId)].slashedAmount = 1; // Set actual amount if needed
            } catch {
                // If slashing fails, mark as unprocessed
                taskSlashings[uint32(taskId)].processed = false;
            }
        }

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

    // These are just to comply with IServiceManager interface
    function addPendingAdmin(address _admin) external onlyOwner {}
    function removePendingAdmin(address pendingAdmin) external onlyOwner {}
    function removeAdmin(address _admin) external onlyOwner {}
    function setAppointee(
        address appointee,
        address target,
        bytes4 selector
    ) external override onlyOwner {}
    function removeAppointee(
        address appointee,
        address target,
        bytes4 selector
    ) external onlyOwner {}
    function deregisterOperatorFromOperatorSets(
        address operator,
        uint32[] memory operatorSetIds
    ) external override {}
}
