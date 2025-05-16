// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IAVS} from "./interfaces/IAVS.sol";
import {ECDSAServiceManagerBase} from "@eigenlayer-middleware/src/unaudited/ECDSAServiceManagerBase.sol";
import {IServiceManager} from "@eigenlayer-middleware/src/interfaces/IServiceManager.sol";
import {SlasherHandler} from "./SlasherHandler.sol";
import {TaskManager} from "./libraries/TaskManager.sol";

contract AVS is ECDSAServiceManagerBase, IAVS {
    using TaskManager for *;

    uint32 public latestTaskNum;
    SlasherHandler public slasherHandler;

    // Mappings for task management
    mapping(uint32 => bytes32) public allTaskHashes;
    mapping(uint32 => Task) public tasks;
    mapping(uint32 => TaskResponse) public taskResponses;
    mapping(address => uint32[]) public operatorTasks;

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
        _transferOwnership(msg.sender);
        slasherHandler = new SlasherHandler(msg.sender, address(0));
    }

    function createTask(
        address assignee,
        uint256 deadline,
        address rwaToken,
        string calldata assetType
    ) external override {
        latestTaskNum++;
        TaskManager.createTask(
            latestTaskNum,
            assignee,
            deadline,
            rwaToken,
            assetType,
            tasks,
            allTaskHashes,
            operatorTasks
        );
    }

    function submitResponse(
        uint256 taskId,
        bytes32 taskHash,
        string calldata metadataURI,
        VerificationStatus status,
        bytes calldata signature
    ) external override {
        require(taskId <= latestTaskNum, "Invalid task ID");
        
        TaskManager.submitResponse(
            uint32(taskId),
            taskHash,
            metadataURI,
            status,
            signature,
            msg.sender,
            tasks,
            allTaskHashes,
            taskResponses
        );
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
        bytes calldata /*evidence*/
    ) external returns (bool) {
        require(taskId <= latestTaskNum, "Invalid task ID");
        require(msg.sender == slasherHandler.admin(), "Only admin can call this function");
        Task storage task = tasks[uint32(taskId)];
        require(task.operator != address(0), "Task does not exist");

        return slasherHandler.raiseSlashing(
            uint32(taskId),
            task.operator,
            reasonMetadata
        );
    }

    function getSlashingInfo(
        uint256 taskId
    ) external view override returns (SlashingInfo memory) {
        require(taskId <= latestTaskNum, "Invalid task ID");
        return slasherHandler.getSlashingInfo(uint32(taskId));
    }

    // These are just to comply with IServiceManager interface
    function addPendingAdmin(address) external onlyOwner {}
    function removePendingAdmin(address) external onlyOwner {}
    function removeAdmin(address) external onlyOwner {}
    function setAppointee(address, address, bytes4) external override onlyOwner {}
    function removeAppointee(address, address, bytes4) external onlyOwner {}
    function deregisterOperatorFromOperatorSets(address, uint32[] memory) external override {}
}
