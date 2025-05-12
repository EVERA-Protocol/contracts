// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title IAVSStaking
 * @notice Interface for the AVS Staking contract
 * @dev This interface defines the functions and events for AVS staking
 */
interface IAVSStaking {
    /**
     * @notice Stakes tokens in the contract
     * @param _amount Amount of tokens to stake
     */
    function stake(uint256 _amount) external;
    
    /**
     * @notice Unstakes tokens after the lock period
     */
    function unstake() external;
    
    /**
     * @notice Claims rewards without unstaking
     */
    function claimRewards() external;
    
    /**
     * @notice Calculates pending rewards for a staker
     * @param _staker Address of the staker
     * @return rewards Pending rewards amount
     */
    function calculateRewards(address _staker) external view returns (uint256 rewards);
    
    /**
     * @notice Gets staker information
     * @param _staker Address of the staker
     * @return stakedAmount Amount of tokens staked
     * @return stakingTimestamp Timestamp when tokens were staked
     * @return lastRewardsClaim Timestamp of last rewards claim
     * @return pendingRewards Amount of pending rewards
     * @return remainingLockTime Remaining time until lock period ends
     */
    function getStakerInfo(address _staker) external view returns (
        uint256 stakedAmount,
        uint256 stakingTimestamp,
        uint256 lastRewardsClaim,
        uint256 pendingRewards,
        uint256 remainingLockTime
    );
    
    /**
     * @notice Gets the total number of assets
     * @return count Number of assets
     */
    function getAssetCount() external view returns (uint256 count);
    
    /**
     * @notice Gets the total number of stakers
     * @return count Number of stakers
     */
    function getStakerCount() external view returns (uint256 count);
    
    // Events
    /**
     * @notice Emitted when tokens are staked
     * @param user Address of the user who staked
     * @param amount Amount of tokens staked
     */
    event Staked(address indexed user, uint256 amount);
    
    /**
     * @notice Emitted when tokens are unstaked
     * @param user Address of the user who unstaked
     * @param amount Amount of tokens unstaked (including rewards)
     */
    event Unstaked(address indexed user, uint256 amount);
    
    /**
     * @notice Emitted when rewards are claimed
     * @param user Address of the user who claimed rewards
     * @param amount Amount of rewards claimed
     */
    event RewardsClaimed(address indexed user, uint256 amount);
    
    /**
     * @notice Emitted when the lock period is updated
     * @param newLockPeriod New lock period in seconds
     */
    event LockPeriodUpdated(uint256 newLockPeriod);
    
    /**
     * @notice Emitted when the APY is updated
     * @param newAPY New APY in basis points
     */
    event APYUpdated(uint256 newAPY);
    
    /**
     * @notice Emitted when an asset is added
     * @param name Asset name
     * @param assetType Asset type
     * @param yield Yield in basis points
     */
    event AssetAdded(string name, string assetType, uint256 yield);
    
    /**
     * @notice Emitted when an asset is updated
     * @param assetId ID of the asset
     * @param name Asset name
     * @param assetType Asset type
     * @param yield Yield in basis points
     * @param isActive Whether the asset is active
     */
    event AssetUpdated(uint256 indexed assetId, string name, string assetType, uint256 yield, bool isActive);
} 