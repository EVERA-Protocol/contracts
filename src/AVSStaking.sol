// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

import "./interfaces/IAVSStaking.sol";

/**
 * @title AVSStaking
 * @notice Contract for staking EVRA tokens in the AVS Eigenlayer system
 * @dev Allows users to stake tokens and earn rewards based on staking duration
 */
contract AVSStaking is IAVSStaking, ReentrancyGuard, Ownable, Pausable {
    using SafeERC20 for IERC20;

    // ========== STATE VARIABLES ==========

    // EVRA token contract
    IERC20 public immutable evraToken;

    // Minimum staking period (in seconds) - default 30 days
    uint256 public lockPeriod = 30 days;

    // Annual percentage yield (APY) in basis points (8.5% = 850)
    uint256 public apy = 850;

    // Maximum APY allowed (50% = 5000 basis points)
    uint256 public constant MAX_APY = 5000;

    // Total amount of tokens staked in the platform
    uint256 public totalStaked;

    // Staker information
    struct StakerInfo {
        uint256 stakedAmount; // Amount of tokens staked
        uint256 stakingTimestamp; // When the tokens were staked
        uint256 lastRewardsClaim; // Last time rewards were claimed
        bool isActive; // Whether the stake is active
    }

    // Mapping of staker address to their staking info
    mapping(address => StakerInfo) public stakers;

    // Array of all staker addresses
    address[] public stakerAddresses;

    // Mapping to track if an address is in the stakerAddresses array
    mapping(address => bool) private isStaker;

    // Asset information
    struct AssetInfo {
        string name; // Asset name
        string assetType; // Asset type (e.g., "Credit", "Real Estate")
        uint256 yield; // Yield in basis points
        bool isActive; // Whether the asset is active
    }

    // Array of available assets
    AssetInfo[] public assets;

    // ========== CONSTRUCTOR ==========

    /**
     * @notice Creates a new AVS Staking contract
     * @param _evraToken Address of the EVRA token contract
     */
    constructor(address _evraToken) Ownable(msg.sender) {
        require(_evraToken != address(0), "Zero address not allowed");
        evraToken = IERC20(_evraToken);

        // Add initial assets based on the UI
        _addAsset("SME Credit Pool", "Credit", 950); // 9.5%
        _addAsset("Jakarta Office Complex", "Real Estate", 850); // 8.5%
        _addAsset("Bali Luxury Resort", "Real Estate", 780); // 7.8%
    }

    // ========== STAKING FUNCTIONS ==========

    /**
     * @notice Stakes tokens in the contract
     * @param _amount Amount of tokens to stake
     */
    function stake(uint256 _amount) external override nonReentrant whenNotPaused {
        require(_amount > 0, "Cannot stake 0 tokens");

        // Transfer tokens from user to contract
        evraToken.safeTransferFrom(msg.sender, address(this), _amount);

        // Update staker information
        if (!isStaker[msg.sender]) {
            stakerAddresses.push(msg.sender);
            isStaker[msg.sender] = true;
            stakers[msg.sender] = StakerInfo({
                stakedAmount: _amount,
                stakingTimestamp: block.timestamp,
                lastRewardsClaim: block.timestamp,
                isActive: true
            });
        } else {
            // If existing staker, update their info
            StakerInfo storage staker = stakers[msg.sender];

            // If they had pending rewards, calculate and add them to the staked amount
            if (staker.isActive && staker.stakedAmount > 0) {
                uint256 pendingRewards = calculateRewards(msg.sender);
                staker.stakedAmount += _amount + pendingRewards;
            } else {
                staker.stakedAmount += _amount;
            }

            staker.stakingTimestamp = block.timestamp;
            staker.lastRewardsClaim = block.timestamp;
            staker.isActive = true;
        }

        // Update total staked amount
        totalStaked += _amount;

        emit Staked(msg.sender, _amount);
    }

    /**
     * @notice Unstakes tokens after the lock period
     */
    function unstake() external override nonReentrant {
        StakerInfo storage staker = stakers[msg.sender];
        require(staker.isActive, "No active stake found");
        require(staker.stakedAmount > 0, "No tokens staked");
        require(block.timestamp >= staker.stakingTimestamp + lockPeriod, "Lock period not yet completed");

        // Calculate rewards
        uint256 rewards = calculateRewards(msg.sender);
        uint256 amountToUnstake = staker.stakedAmount;
        uint256 totalAmount = amountToUnstake + rewards;

        // Reset staker info before transfer to prevent reentrancy
        staker.stakedAmount = 0;
        staker.isActive = false;

        // Update total staked
        totalStaked -= amountToUnstake;

        // Transfer tokens back to user
        evraToken.safeTransfer(msg.sender, totalAmount);

        emit Unstaked(msg.sender, totalAmount);
        emit RewardsClaimed(msg.sender, rewards);
    }

    /**
     * @notice Claims rewards without unstaking
     */
    function claimRewards() external override nonReentrant whenNotPaused {
        StakerInfo storage staker = stakers[msg.sender];
        require(staker.isActive, "No active stake found");
        require(staker.stakedAmount > 0, "No tokens staked");

        // Calculate rewards
        uint256 rewards = calculateRewards(msg.sender);
        require(rewards > 0, "No rewards to claim");

        // Update last claim time before transfer to prevent reentrancy
        staker.lastRewardsClaim = block.timestamp;

        // Transfer rewards to user
        evraToken.safeTransfer(msg.sender, rewards);

        emit RewardsClaimed(msg.sender, rewards);
    }

    /**
     * @notice Calculates pending rewards for a staker
     * @param _staker Address of the staker
     * @return rewards Pending rewards amount
     */
    function calculateRewards(address _staker) public view override returns (uint256 rewards) {
        StakerInfo storage staker = stakers[_staker];
        if (!staker.isActive || staker.stakedAmount == 0) {
            return 0;
        }

        // Calculate time since last claim in seconds
        uint256 timeElapsed = block.timestamp - staker.lastRewardsClaim;

        // Avoid potential overflow by checking for extreme values
        if (timeElapsed == 0 || staker.stakedAmount > type(uint256).max / apy) {
            return 0;
        }

        // Calculate rewards: stakedAmount * APY * timeElapsed / (365 days * 10000)
        // APY is in basis points (e.g., 850 = 8.5%)
        rewards = (staker.stakedAmount * apy * timeElapsed) / (365 days * 10000);

        return rewards;
    }

    /**
     * @notice Gets staker information
     * @param _staker Address of the staker
     * @return stakedAmount Amount of tokens staked
     * @return stakingTimestamp Timestamp when tokens were staked
     * @return lastRewardsClaim Timestamp of last rewards claim
     * @return pendingRewards Amount of pending rewards
     * @return remainingLockTime Remaining time until lock period ends
     */
    function getStakerInfo(address _staker)
        external
        view
        override
        returns (
            uint256 stakedAmount,
            uint256 stakingTimestamp,
            uint256 lastRewardsClaim,
            uint256 pendingRewards,
            uint256 remainingLockTime
        )
    {
        StakerInfo storage staker = stakers[_staker];

        uint256 remaining = 0;
        if (staker.isActive && block.timestamp < staker.stakingTimestamp + lockPeriod) {
            remaining = staker.stakingTimestamp + lockPeriod - block.timestamp;
        }

        return (
            staker.stakedAmount, staker.stakingTimestamp, staker.lastRewardsClaim, calculateRewards(_staker), remaining
        );
    }

    // ========== ASSET MANAGEMENT FUNCTIONS ==========

    /**
     * @notice Adds a new asset to the platform (internal)
     * @param _name Asset name
     * @param _assetType Asset type
     * @param _yield Yield in basis points
     */
    function _addAsset(string memory _name, string memory _assetType, uint256 _yield) internal {
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(bytes(_assetType).length > 0, "Asset type cannot be empty");
        require(_yield <= MAX_APY, "Yield exceeds maximum allowed");

        assets.push(AssetInfo({name: _name, assetType: _assetType, yield: _yield, isActive: true}));

        emit AssetAdded(_name, _assetType, _yield);
    }

    /**
     * @notice Adds a new asset to the platform (admin only)
     * @param _name Asset name
     * @param _assetType Asset type
     * @param _yield Yield in basis points
     */
    function addAsset(string memory _name, string memory _assetType, uint256 _yield) external onlyOwner {
        _addAsset(_name, _assetType, _yield);
    }

    /**
     * @notice Updates an existing asset
     * @param _assetId Asset ID
     * @param _name Asset name
     * @param _assetType Asset type
     * @param _yield Yield in basis points
     * @param _isActive Whether the asset is active
     */
    function updateAsset(
        uint256 _assetId,
        string memory _name,
        string memory _assetType,
        uint256 _yield,
        bool _isActive
    ) external onlyOwner {
        require(_assetId < assets.length, "Invalid asset ID");
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(bytes(_assetType).length > 0, "Asset type cannot be empty");
        require(_yield <= MAX_APY, "Yield exceeds maximum allowed");

        AssetInfo storage asset = assets[_assetId];
        asset.name = _name;
        asset.assetType = _assetType;
        asset.yield = _yield;
        asset.isActive = _isActive;

        emit AssetUpdated(_assetId, _name, _assetType, _yield, _isActive);
    }

    /**
     * @notice Gets the total number of assets
     * @return count Number of assets
     */
    function getAssetCount() external view override returns (uint256 count) {
        return assets.length;
    }

    // ========== ADMIN FUNCTIONS ==========

    /**
     * @notice Updates the lock period
     * @param _newLockPeriod New lock period in seconds
     */
    function updateLockPeriod(uint256 _newLockPeriod) external onlyOwner {
        require(_newLockPeriod > 0, "Lock period cannot be zero");
        lockPeriod = _newLockPeriod;
        emit LockPeriodUpdated(_newLockPeriod);
    }

    /**
     * @notice Updates the APY
     * @param _newAPY New APY in basis points
     */
    function updateAPY(uint256 _newAPY) external onlyOwner {
        require(_newAPY <= MAX_APY, "APY exceeds maximum allowed");
        apy = _newAPY;
        emit APYUpdated(_newAPY);
    }

    /**
     * @notice Pauses the contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Gets the total number of stakers
     * @return count Number of stakers
     */
    function getStakerCount() external view override returns (uint256 count) {
        return stakerAddresses.length;
    }

    /**
     * @notice Emergency function to recover tokens sent to the contract by mistake
     * @param _token Token address
     * @param _amount Amount to recover
     */
    function recoverERC20(address _token, uint256 _amount) external onlyOwner {
        require(_token != address(evraToken), "Cannot withdraw staked tokens");
        IERC20(_token).safeTransfer(owner(), _amount);
    }
}
