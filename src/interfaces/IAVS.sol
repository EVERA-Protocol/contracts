// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@eigenlayer-middleware/src/libraries/BN254.sol";
import {IStrategy} from "@eigenlayer/contracts/interfaces/IStrategy.sol";

interface IAVS {
    // Enum to represent the verification status
    enum VerificationStatus {
        PENDING,
        LEGIT,
        FRAUD,
        DISPUTED // New status for disputed cases
    }

    // Struct to hold slashing information
    struct SlashingInfo {
        address reporter; // Address that reported the slashing
        uint256 reportedAt; // When the slashing was reported
        string reasonMetadata; // IPFS/URL containing evidence
        bool processed; // Whether the slashing has been processed
        uint256 slashedAmount; // Amount of tokens slashed
    }

    // Struct to hold task details
    struct Task {
        bytes taskHash; // keccak256 hash of the task details
        uint256 deadline; // timestamp for task completion deadline
        address operator; // address of the operator assigned to verify
        address rwaToken; // identifier for the Real World Asset
        string assetType; // type of the Real World Asset
        uint32 taskCreatedBlock;
    }

    // Struct to hold the response from operators
    struct TaskResponse {
        string metadataURI; // IPFS/URL containing detailed verification metadata
        VerificationStatus status; // The vote (LEGIT/FRAUD)
        uint32 taskFinishedBlock;
        bytes signature; // operator's signature
    }

    // Events
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
        VerificationStatus status
    );

    event SlashingRaised(
        uint256 indexed taskId,
        address indexed reporter,
        address indexed operator,
        string reasonMetadata
    );

    // Core functions that should be implemented
    function createTask(
        address assignee,
        uint256 deadline,
        address rwaToken,
        string calldata assetType
    ) external;

    function submitResponse(
        uint256 taskId,
        bytes32 taskHash,
        string calldata metadataURI,
        VerificationStatus status,
        bytes calldata signature
    ) external;

    function getTask(uint256 taskId) external view returns (Task memory);

    function getTaskResponse(
        uint256 taskId
    ) external view returns (TaskResponse memory);

    function raiseSlashing(
        uint256 taskId,
        string calldata reasonMetadata,
        bytes calldata evidence
    ) external returns (bool);

    // function challengeResponse(
    //     uint256 taskId,
    //     string calldata evidence,
    //     bytes calldata challengeSignature
    // ) external payable;

    function getSlashingInfo(
        uint256 taskId
    ) external view returns (SlashingInfo memory);
}
