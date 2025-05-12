// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title YieldDistributionSystem
 * @dev Contract for managing yield distribution to token holders
 */
contract YieldDistributionSystem is ReentrancyGuard, Ownable {
    // ========== STATE VARIABLES ==========

    // Contract pause state
    bool public paused;

    // Total yield available for distribution
    uint256 public totalYield;

    // Timestamp of the last snapshot
    uint256 public lastSnapshotTimestamp;

    // Flag to check if snapshot is active
    bool public snapshotActive;

    // Mapping of distribution ID to total distribution amount
    mapping(uint256 => uint256) public distributions;

    // Mapping of distribution ID to whether it's completed
    mapping(uint256 => bool) public distributionCompleted;

    // Current distribution ID
    uint256 public currentDistributionId;

    // Mapping of holder address to their balance at snapshot time
    mapping(address => uint256) public snapshotBalances;

    // Array of all holder addresses in the snapshot
    address[] public snapshotHolders;

    // Total token supply at snapshot time
    uint256 public totalSnapshotSupply;

    // Mapping of distribution ID to holder address to claimed status
    mapping(uint256 => mapping(address => bool)) public hasClaimed;

    // Mapping of distribution ID to holder address to yield amount
    mapping(uint256 => mapping(address => uint256)) public yieldAmounts;

    // Token contract address
    IERC20 public tokenContract;

    // Yield sources tracking
    struct YieldSource {
        string name;
        uint256 amount;
        uint256 timestamp;
    }

    // Array of yield sources
    YieldSource[] public yieldSources;

    // ========== EVENTS ==========

    event SnapshotTaken(uint256 timestamp, uint256 totalSupply, uint256 holdersCount);
    event SnapshotValidated(uint256 timestamp);
    event YieldDeposited(string source, uint256 amount);
    event YieldWithdrawn(address to, uint256 amount);
    event YieldDistributionCreated(uint256 distributionId, uint256 amount);
    event YieldClaimed(address holder, uint256 distributionId, uint256 amount);
    event Paused(address account);
    event Unpaused(address account);

    // ========== MODIFIERS ==========

    modifier snapshotNotActive() {
        require(!snapshotActive, "Snapshot is currently active");
        _;
    }

    modifier snapshotIsActive() {
        require(snapshotActive, "No active snapshot");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    // ========== CONSTRUCTOR ==========

    constructor(address _tokenContract) Ownable(msg.sender) {
        tokenContract = IERC20(_tokenContract);
        currentDistributionId = 1;
        paused = false;
    }

    // ========== SNAPSHOT FUNCTIONS ==========

    /**
     * @dev Takes a snapshot of all token holders and their balances
     */
    function takeHolderSnapshot() external onlyOwner snapshotNotActive whenNotPaused {
        // Delete previous snapshot data
        if (snapshotHolders.length > 0) {
            for (uint256 i = 0; i < snapshotHolders.length; i++) {
                snapshotBalances[snapshotHolders[i]] = 0;
            }
            delete snapshotHolders;
        }

        // Set snapshot as active until validation
        snapshotActive = true;
        lastSnapshotTimestamp = block.timestamp;

        // Total supply needs to be retrieved from token contract
        totalSnapshotSupply = tokenContract.totalSupply();

        emit SnapshotTaken(lastSnapshotTimestamp, totalSnapshotSupply, 0);
    }

    /**
     * @dev Adds holders to the current snapshot
     * @param holders Array of holder addresses
     * @param balances Array of holder balances
     */
    function addHoldersToSnapshot(address[] calldata holders, uint256[] calldata balances)
        external
        onlyOwner
        snapshotIsActive
        whenNotPaused
    {
        require(holders.length == balances.length, "Arrays length mismatch");
        require(holders.length > 0, "Empty arrays not allowed");

        for (uint256 i = 0; i < holders.length; i++) {
            require(holders[i] != address(0), "Zero address not allowed");

            if (snapshotBalances[holders[i]] == 0) {
                snapshotHolders.push(holders[i]);
            }
            snapshotBalances[holders[i]] = balances[i];
        }
    }

    /**
     * @dev Validates the current snapshot and makes it ready for distribution
     */
    function validateSnapshot() external onlyOwner snapshotIsActive whenNotPaused {
        require(snapshotHolders.length > 0, "No holders in snapshot");

        // Verify that the sum of all balances equals the total supply
        uint256 totalBalances = 0;
        for (uint256 i = 0; i < snapshotHolders.length; i++) {
            totalBalances += snapshotBalances[snapshotHolders[i]];
        }

        require(totalBalances == totalSnapshotSupply, "Total balances do not match total supply");

        // Snapshot is now valid and no longer active (for modification)
        snapshotActive = false;

        emit SnapshotValidated(lastSnapshotTimestamp);
    }

    // ========== YIELD MANAGEMENT FUNCTIONS ==========

    /**
     * @dev Deposits yield from a specific source
     * @param source Name of the yield source
     */
    function depositYield(string calldata source) external payable onlyOwner whenNotPaused {
        require(msg.value > 0, "Must deposit some yield");
        require(bytes(source).length > 0, "Source name cannot be empty");

        totalYield += msg.value;

        // Track the yield source
        yieldSources.push(YieldSource({name: source, amount: msg.value, timestamp: block.timestamp}));

        emit YieldDeposited(source, msg.value);
    }

    /**
     * @dev Withdraws yield from reserve (for admin use)
     * @param amount Amount to withdraw
     * @param to Address to send the yield to
     */
    function withdrawYieldReserve(uint256 amount, address payable to) external onlyOwner nonReentrant whenNotPaused {
        require(amount <= totalYield, "Not enough yield in reserve");
        require(amount > 0, "Amount must be greater than zero");
        require(to != address(0), "Cannot withdraw to zero address");

        totalYield -= amount;

        // Transfer ETH using a safer pattern
        (bool success,) = to.call{value: amount}("");
        require(success, "ETH transfer failed");

        emit YieldWithdrawn(to, amount);
    }

    // ========== DISTRIBUTION FUNCTIONS ==========

    /**
     * @dev Calculates yield for all holders based on the snapshot
     * @param distributionAmount Total amount to distribute
     */
    function calculateYield(uint256 distributionAmount) external onlyOwner snapshotNotActive whenNotPaused {
        require(snapshotHolders.length > 0, "No snapshot data available");
        require(distributionAmount <= totalYield, "Not enough yield for distribution");
        require(!snapshotActive, "Cannot calculate during active snapshot");
        require(distributionAmount > 0, "Distribution amount must be greater than zero");

        // Create a new distribution
        distributions[currentDistributionId] = distributionAmount;

        // Calculate each holder's share
        uint256 totalDistributed = 0;

        for (uint256 i = 0; i < snapshotHolders.length; i++) {
            address holder = snapshotHolders[i];
            uint256 holderBalance = snapshotBalances[holder];

            // Calculate pro-rata share
            uint256 holderYield = (holderBalance * distributionAmount) / totalSnapshotSupply;

            // Store the yield amount for claiming
            yieldAmounts[currentDistributionId][holder] = holderYield;
            totalDistributed += holderYield;
        }

        // Handle any dust amounts due to division
        if (totalDistributed < distributionAmount) {
            // Add the dust to the first holder with non-zero balance
            for (uint256 i = 0; i < snapshotHolders.length; i++) {
                if (snapshotBalances[snapshotHolders[i]] > 0) {
                    yieldAmounts[currentDistributionId][snapshotHolders[i]] += (distributionAmount - totalDistributed);
                    break;
                }
            }
        }

        // Reserve the distribution amount
        totalYield -= distributionAmount;

        emit YieldDistributionCreated(currentDistributionId, distributionAmount);

        // Increment distribution ID for next time
        currentDistributionId++;
    }

    /**
     * @dev Distributes yield automatically to all holders (push model)
     * @param distributionId ID of the distribution to process
     */
    function distributeYield(uint256 distributionId) external onlyOwner nonReentrant whenNotPaused {
        require(distributions[distributionId] > 0, "Distribution does not exist");
        require(!distributionCompleted[distributionId], "Distribution already completed");

        uint256 distributedAmount = 0;
        uint256 failedTransfers = 0;

        // Send yield to each holder
        for (uint256 i = 0; i < snapshotHolders.length; i++) {
            address holder = snapshotHolders[i];
            uint256 amount = yieldAmounts[distributionId][holder];

            if (amount > 0 && !hasClaimed[distributionId][holder]) {
                hasClaimed[distributionId][holder] = true;

                // Use a safer transfer method
                (bool success,) = payable(holder).call{value: amount}("");

                if (success) {
                    distributedAmount += amount;
                    emit YieldClaimed(holder, distributionId, amount);
                } else {
                    // If transfer fails, mark as not claimed and track failure
                    hasClaimed[distributionId][holder] = false;
                    failedTransfers++;
                }
            }
        }

        // Mark as complete even if some transfers failed
        // Admin can retry for the failed transfers
        if (failedTransfers == 0) {
            distributionCompleted[distributionId] = true;
        }
    }

    /**
     * @dev Allows a holder to claim their yield (pull model)
     * @param distributionId ID of the distribution to claim from
     */
    function claimYield(uint256 distributionId) external nonReentrant whenNotPaused {
        require(distributions[distributionId] > 0, "Distribution does not exist");
        require(!hasClaimed[distributionId][msg.sender], "Already claimed for this distribution");

        uint256 amount = yieldAmounts[distributionId][msg.sender];
        require(amount > 0, "No yield to claim");

        // Use CEI pattern (Checks-Effects-Interactions)
        hasClaimed[distributionId][msg.sender] = true;

        // Use a safer transfer method
        (bool success,) = payable(msg.sender).call{value: amount}("");
        require(success, "ETH transfer failed");

        emit YieldClaimed(msg.sender, distributionId, amount);
    }

    // ========== QUERY FUNCTIONS ==========

    /**
     * @dev Gets the claimable yield for a holder across all distributions
     * @param holder Address of the holder
     */
    function getClaimableYield(address holder) external view returns (uint256) {
        uint256 claimable = 0;

        for (uint256 id = 1; id < currentDistributionId; id++) {
            if (!hasClaimed[id][holder] && yieldAmounts[id][holder] > 0) {
                claimable += yieldAmounts[id][holder];
            }
        }

        return claimable;
    }

    /**
     * @dev Gets the count of yield sources
     */
    function getYieldSourcesCount() external view returns (uint256) {
        return yieldSources.length;
    }

    /**
     * @dev Gets the count of holders in the snapshot
     */
    function getSnapshotHoldersCount() external view returns (uint256) {
        return snapshotHolders.length;
    }

    /**
     * @dev Gets the count of holders in the snapshot
     */
    function getSnapshotHolders() external view returns (address[] memory) {
        return snapshotHolders;
    }

    /**
     * @dev Checks if an address is in the snapshot
     * @param _address The address to check
     * @return True if the address is in the snapshot, false otherwise
     */
    function isInSnapshot(address _address) external view returns (bool) {
        for (uint256 i = 0; i < snapshotHolders.length; i++) {
            if (snapshotHolders[i] == _address) {
                return true;
            }
        }
        return false;
    }

    // ========== ADMIN FUNCTIONS ==========

    /**
     * @dev Sets a new token contract
     * @param newTokenContract Address of the new token contract
     */
    function setTokenContract(address newTokenContract) external onlyOwner {
        require(newTokenContract != address(0), "New token contract cannot be zero address");
        tokenContract = IERC20(newTokenContract);
    }

    /**
     * @dev Pause contract functions
     */
    function pause() external onlyOwner {
        require(!paused, "Contract already paused");
        paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Unpause contract functions
     */
    function unpause() external onlyOwner {
        require(paused, "Contract not paused");
        paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @dev Emergency function to recover any accidentally sent ERC20 tokens
     * @param tokenAddress Address of the token to recover
     * @param to Address to send the tokens to
     * @param amount Amount to recover
     */
    function recoverERC20(address tokenAddress, address to, uint256 amount) external onlyOwner {
        require(tokenAddress != address(0), "Cannot recover from zero address");
        require(to != address(0), "Cannot recover to zero address");
        require(amount > 0, "Amount must be greater than zero");

        IERC20(tokenAddress).transfer(to, amount);
    }

    // ========== RECEIVE FUNCTION ==========

    receive() external payable {
        // Auto-add to yield when ETH is sent directly to contract
        totalYield += msg.value;

        emit YieldDeposited("direct_deposit", msg.value);
    }
}
