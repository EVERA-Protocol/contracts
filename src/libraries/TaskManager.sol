// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IAVS} from "../interfaces/IAVS.sol";
import {SignatureVerifier} from "./SignatureVerifier.sol";

/**
 * @title TaskManager
 * @dev Library for task management functions
 */
library TaskManager {
    event TaskCreated(
        uint256 indexed taskId,
        bytes32 indexed taskHash,
        address indexed operator,
        uint256 deadline
    );

    event TaskCompleted(
        uint256 indexed taskId,
        bytes32 indexed taskHash,
        address indexed operator,
        IAVS.VerificationStatus status
    );

    /**
     * @dev Create a new task
     * @param taskId The task ID
     * @param assignee The assignee operator
     * @param deadline The deadline for the task
     * @param rwaToken The RWA token address
     * @param assetType The asset type
     * @param tasks Tasks mapping
     * @param allTaskHashes Task hashes mapping
     * @param operatorTasks Operator tasks mapping
     */
    function createTask(
        uint32 taskId,
        address assignee,
        uint256 deadline,
        address rwaToken,
        string calldata assetType,
        mapping(uint32 => IAVS.Task) storage tasks,
        mapping(uint32 => bytes32) storage allTaskHashes,
        mapping(address => uint32[]) storage operatorTasks
    ) external returns (bytes32) {
        require(deadline > block.timestamp, "Deadline must be in future");

        bytes memory taskData = abi.encodePacked(
            assignee,
            deadline,
            rwaToken,
            assetType
        );
        bytes32 taskHash = keccak256(taskData);

        tasks[taskId] = IAVS.Task({
            taskHash: taskData,
            deadline: deadline,
            operator: assignee,
            rwaToken: rwaToken,
            assetType: assetType,
            taskCreatedBlock: uint32(block.number)
        });

        allTaskHashes[taskId] = taskHash;
        operatorTasks[assignee].push(taskId);

        emit TaskCreated(taskId, taskHash, assignee, deadline);
        
        return taskHash;
    }

    /**
     * @dev Submit a response for a task
     * @param taskId The task ID
     * @param taskHash The task hash
     * @param metadataURI The metadata URI
     * @param status The verification status
     * @param signature The operator signature
     * @param sender The message sender
     * @param tasks Tasks mapping
     * @param allTaskHashes Task hashes mapping
     * @param taskResponses Task responses mapping
     */
    function submitResponse(
        uint32 taskId,
        bytes32 taskHash,
        string calldata metadataURI,
        IAVS.VerificationStatus status,
        bytes calldata signature,
        address sender,
        mapping(uint32 => IAVS.Task) storage tasks,
        mapping(uint32 => bytes32) storage allTaskHashes,
        mapping(uint32 => IAVS.TaskResponse) storage taskResponses
    ) external {
        require(
            allTaskHashes[taskId] == taskHash,
            "Task hash mismatch"
        );

        IAVS.Task storage task = tasks[taskId];
        require(sender == task.operator, "Not assigned operator");
        require(block.timestamp <= task.deadline, "Task deadline passed");

        // Verify signature
        bytes32 messageHash = keccak256(
            abi.encodePacked(taskId, taskHash, metadataURI, status)
        );
        require(
            SignatureVerifier.isValidSignature(messageHash, signature, sender),
            "Invalid signature"
        );

        taskResponses[taskId] = IAVS.TaskResponse({
            metadataURI: metadataURI,
            status: status,
            taskFinishedBlock: uint32(block.number),
            signature: signature
        });

        emit TaskCompleted(taskId, taskHash, sender, status);
    }
} 