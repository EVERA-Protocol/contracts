// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./AVSStaking.sol";
import "./interfaces/IAVSStakingFactory.sol";

/**
 * @title AVSStakingFactory
 * @notice Factory contract for deploying AVSStaking contracts
 * @dev Creates and manages AVSStaking contracts for different tokens
 */
contract AVSStakingFactory is IAVSStakingFactory, Ownable {
    // Array of all deployed staking contracts
    address[] public stakingContracts;

    // Mapping from token address to staking contract address
    mapping(address => address) public tokenToStakingContract;

    /**
     * @notice Creates a new AVSStakingFactory
     */
    constructor() Ownable(msg.sender) {}

    /**
     * @notice Deploys a new AVSStaking contract for a token
     * @param _token Address of the token to stake
     * @return stakingContract Address of the deployed staking contract
     */
    function deployStakingContract(address _token) external override onlyOwner returns (address stakingContract) {
        require(_token != address(0), "Token cannot be zero address");
        require(tokenToStakingContract[_token] == address(0), "Staking contract already exists for this token");

        // Deploy new staking contract
        AVSStaking newStakingContract = new AVSStaking(_token);

        // Transfer ownership to the factory owner
        newStakingContract.transferOwnership(owner());

        // Store the contract address
        stakingContract = address(newStakingContract);
        stakingContracts.push(stakingContract);
        tokenToStakingContract[_token] = stakingContract;

        emit StakingContractDeployed(_token, stakingContract);

        return stakingContract;
    }

    /**
     * @notice Gets the number of deployed staking contracts
     * @return count Number of deployed staking contracts
     */
    function getStakingContractCount() external view override returns (uint256 count) {
        return stakingContracts.length;
    }

    /**
     * @notice Gets the staking contract for a token
     * @param _token Address of the token
     * @return stakingContract Address of the staking contract
     */
    function getStakingContract(address _token) external view override returns (address stakingContract) {
        return tokenToStakingContract[_token];
    }
}
