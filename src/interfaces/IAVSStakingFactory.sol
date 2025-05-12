// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title IAVSStakingFactory
 * @notice Interface for the AVS Staking Factory contract
 * @dev This interface defines the functions and events for deploying and managing AVS staking contracts
 */
interface IAVSStakingFactory {
    /**
     * @notice Deploys a new AVSStaking contract for a token
     * @param _token Address of the token to stake
     * @return stakingContract Address of the deployed staking contract
     */
    function deployStakingContract(address _token) external returns (address stakingContract);
    
    /**
     * @notice Gets the number of deployed staking contracts
     * @return count Number of deployed staking contracts
     */
    function getStakingContractCount() external view returns (uint256 count);
    
    /**
     * @notice Gets the staking contract for a token
     * @param _token Address of the token
     * @return stakingContract Address of the staking contract
     */
    function getStakingContract(address _token) external view returns (address stakingContract);
    
    /**
     * @notice Emitted when a new staking contract is deployed
     * @param token Address of the token
     * @param stakingContract Address of the staking contract
     */
    event StakingContractDeployed(address indexed token, address indexed stakingContract);
} 