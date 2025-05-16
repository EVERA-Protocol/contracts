// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {InstantSlasher} from "@eigenlayer-middleware/src/slashers/InstantSlasher.sol";
import {IStrategy} from "@eigenlayer/contracts/interfaces/IStrategy.sol";
import {IAllocationManagerTypes} from "@eigenlayer/contracts/interfaces/IAllocationManager.sol";
import {IAVS} from "./interfaces/IAVS.sol";

/**
 * @title SlasherHandler
 * @dev Contract to handle the slashing functionality, extracted from AVS
 */
contract SlasherHandler {
    address public admin;
    address public instantSlasher;
    
    // Mapping for slashing info
    mapping(uint32 => IAVS.SlashingInfo) public taskSlashings;
    
    // Events
    event SlashingRaised(
        uint256 indexed taskId,
        address indexed reporter,
        address indexed operator,
        string reasonMetadata
    );
    
    // Modifiers
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }
    
    constructor(address _admin, address _instantSlasher) {
        admin = _admin;
        instantSlasher = _instantSlasher;
    }
    
    /**
     * @dev Change the admin address
     * @param newAdmin The new admin address
     */
    function changeAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "New admin cannot be zero address");
        admin = newAdmin;
    }
    
    /**
     * @dev Change the slasher address
     * @param newSlasher The new slasher address
     */
    function changeSlasher(address newSlasher) external onlyAdmin {
        require(newSlasher != address(0), "New slasher cannot be zero address");
        instantSlasher = newSlasher;
    }
    
    /**
     * @dev Raise a slashing request
     * @param taskId The ID of the task
     * @param operator The operator address
     * @param reasonMetadata The reason for slashing
     * @return success Whether the slashing was successful
     */
    function raiseSlashing(
        uint32 taskId,
        address operator,
        string calldata reasonMetadata
    ) external onlyAdmin returns (bool) {
        // Check if there's already a slashing for this task
        require(
            !taskSlashings[taskId].processed,
            "Slashing already processed"
        );

        IAVS.SlashingInfo memory slashing = IAVS.SlashingInfo({
            reporter: msg.sender,
            reportedAt: block.timestamp,
            reasonMetadata: reasonMetadata,
            processed: true, // Mark as processed since admin is doing it
            slashedAmount: 0 // Will be set when processed by slasher
        });

        taskSlashings[taskId] = slashing;

        // Call the instant slasher if set
        if (instantSlasher != address(0)) {
            // Create empty arrays for strategies and wads
            IStrategy[] memory strategies = new IStrategy[](0);
            uint256[] memory wadsToSlash = new uint256[](0);

            try
                InstantSlasher(instantSlasher).fulfillSlashingRequest(
                    IAllocationManagerTypes.SlashingParams({
                        operator: operator,
                        operatorSetId: uint8(taskId),
                        strategies: strategies,
                        wadsToSlash: wadsToSlash,
                        description: reasonMetadata
                    })
                )
            {
                taskSlashings[taskId].slashedAmount = 1; // Set actual amount if needed
            } catch {
                // If slashing fails, mark as unprocessed
                taskSlashings[taskId].processed = false;
            }
        }

        emit SlashingRaised(taskId, msg.sender, operator, reasonMetadata);

        return true;
    }
    
    /**
     * @dev Get slashing information for a task
     * @param taskId The ID of the task
     * @return The slashing information
     */
    function getSlashingInfo(
        uint32 taskId
    ) external view returns (IAVS.SlashingInfo memory) {
        return taskSlashings[taskId];
    }
} 