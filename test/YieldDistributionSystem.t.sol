// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/yieldDistributionSystem.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Simple ERC20 token for testing with exact supply
contract ExactSupplyToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("Mock Token", "MOCK") {
        _mint(msg.sender, initialSupply);
    }
}

contract YieldDistributionSystemTest is Test {
    YieldDistributionSystem public yieldSystem;
    ExactSupplyToken public token;

    address public admin;
    address public user1;
    address public user2;
    address public user3;

    uint256 public user1Balance = 500 * 10 ** 18;
    uint256 public user2Balance = 300 * 10 ** 18;
    uint256 public user3Balance = 200 * 10 ** 18;
    uint256 public totalSupply = 1000 * 10 ** 18; // Exactly matches the sum of user balances

    function setUp() public {
        // Setup accounts
        admin = address(this);
        user1 = address(0x1);
        user2 = address(0x2);
        user3 = address(0x3);

        // Deploy token with exactly the right supply
        token = new ExactSupplyToken(totalSupply);

        // Transfer tokens to users
        token.transfer(user1, user1Balance);
        token.transfer(user2, user2Balance);
        token.transfer(user3, user3Balance);

        // Deploy the yield distribution system
        yieldSystem = new YieldDistributionSystem(address(token));

        // Fund the admin with ETH for yield deposits
        vm.deal(admin, 100 ether);
    }

    function testDeployment() public {
        // Verify initial state
        assertEq(address(yieldSystem.tokenContract()), address(token));
        assertEq(yieldSystem.paused(), false);
        assertEq(yieldSystem.currentDistributionId(), 1);
        assertEq(yieldSystem.totalYield(), 0);
    }

    function testTakeSnapshot() public {
        // Take a snapshot
        yieldSystem.takeHolderSnapshot();

        // Verify snapshot state
        assertTrue(yieldSystem.snapshotActive());
        assertEq(yieldSystem.totalSnapshotSupply(), totalSupply);

        // Add holders to snapshot
        address[] memory holders = new address[](3);
        holders[0] = user1;
        holders[1] = user2;
        holders[2] = user3;

        uint256[] memory balances = new uint256[](3);
        balances[0] = user1Balance;
        balances[1] = user2Balance;
        balances[2] = user3Balance;

        yieldSystem.addHoldersToSnapshot(holders, balances);

        // Validate snapshot
        yieldSystem.validateSnapshot();

        // Verify snapshot is no longer active
        assertFalse(yieldSystem.snapshotActive());

        // Verify holder count and balances
        assertEq(yieldSystem.getSnapshotHoldersCount(), 3);
        assertEq(yieldSystem.snapshotBalances(user1), user1Balance);
        assertEq(yieldSystem.snapshotBalances(user2), user2Balance);
        assertEq(yieldSystem.snapshotBalances(user3), user3Balance);
    }

    function testDepositYield() public {
        // Deposit yield
        uint256 depositAmount = 10 ether;
        yieldSystem.depositYield{value: depositAmount}("Test Source");

        // Verify yield deposit
        assertEq(yieldSystem.totalYield(), depositAmount);
        assertEq(yieldSystem.getYieldSourcesCount(), 1);

        // Check source details
        (string memory name, uint256 amount,) = yieldSystem.yieldSources(0);
        assertEq(name, "Test Source");
        assertEq(amount, depositAmount);
    }

    function testCalculateYield() public {
        // Setup for yield calculation
        testTakeSnapshot();

        // Deposit yield
        uint256 depositAmount = 10 ether;
        yieldSystem.depositYield{value: depositAmount}("Test Source");

        // Calculate yield for distribution
        yieldSystem.calculateYield(depositAmount);

        // Verify distribution created
        assertEq(yieldSystem.distributions(1), depositAmount);
        assertEq(yieldSystem.totalYield(), 0); // Yield is now reserved for distribution

        // Verify yield amounts calculated correctly
        uint256 expectedUser1Yield = (user1Balance * depositAmount) / totalSupply;
        uint256 expectedUser2Yield = (user2Balance * depositAmount) / totalSupply;
        uint256 expectedUser3Yield = (user3Balance * depositAmount) / totalSupply;

        assertEq(yieldSystem.yieldAmounts(1, user1), expectedUser1Yield);
        assertEq(yieldSystem.yieldAmounts(1, user2), expectedUser2Yield);
        assertEq(yieldSystem.yieldAmounts(1, user3), expectedUser3Yield);

        // Verify current distribution ID incremented
        assertEq(yieldSystem.currentDistributionId(), 2);
    }

    function testDistributeYield() public {
        // Setup for distribution
        testCalculateYield();

        // Record initial balances
        uint256 user1InitialBalance = user1.balance;
        uint256 user2InitialBalance = user2.balance;
        uint256 user3InitialBalance = user3.balance;

        // Distribute yield
        yieldSystem.distributeYield(1);

        // Verify distribution status
        assertTrue(yieldSystem.distributionCompleted(1));

        // Verify users received their yield
        uint256 user1YieldAmount = yieldSystem.yieldAmounts(1, user1);
        uint256 user2YieldAmount = yieldSystem.yieldAmounts(1, user2);
        uint256 user3YieldAmount = yieldSystem.yieldAmounts(1, user3);

        assertEq(user1.balance, user1InitialBalance + user1YieldAmount);
        assertEq(user2.balance, user2InitialBalance + user2YieldAmount);
        assertEq(user3.balance, user3InitialBalance + user3YieldAmount);

        // Verify claimed status
        assertTrue(yieldSystem.hasClaimed(1, user1));
        assertTrue(yieldSystem.hasClaimed(1, user2));
        assertTrue(yieldSystem.hasClaimed(1, user3));
    }

    function testClaimYield() public {
        // Setup for claiming
        testCalculateYield();

        // Record initial balance for user1
        uint256 user1InitialBalance = user1.balance;

        // Claim yield for user1
        vm.prank(user1);
        yieldSystem.claimYield(1);

        // Verify user1 received their yield
        uint256 user1YieldAmount = yieldSystem.yieldAmounts(1, user1);
        assertEq(user1.balance, user1InitialBalance + user1YieldAmount);

        // Verify claimed status
        assertTrue(yieldSystem.hasClaimed(1, user1));

        // Verify others haven't claimed
        assertFalse(yieldSystem.hasClaimed(1, user2));
        assertFalse(yieldSystem.hasClaimed(1, user3));
    }

    function testGetClaimableYield() public {
        // Setup for checking claimable yield
        testCalculateYield();

        // Check claimable yield for user1
        uint256 user1ClaimableYield = yieldSystem.getClaimableYield(user1);
        uint256 user1YieldAmount = yieldSystem.yieldAmounts(1, user1);

        assertEq(user1ClaimableYield, user1YieldAmount);

        // User1 claims yield
        vm.prank(user1);
        yieldSystem.claimYield(1);

        // Verify claimable yield is now zero
        assertEq(yieldSystem.getClaimableYield(user1), 0);
    }

    function testGetSnapshotHolders() public {
        // Setup snapshot
        testTakeSnapshot();

        // Get snapshot holders
        address[] memory holders = yieldSystem.getSnapshotHolders();

        // Verify holders array
        assertEq(holders.length, 3);
        assertTrue(isAddressInArray(holders, user1));
        assertTrue(isAddressInArray(holders, user2));
        assertTrue(isAddressInArray(holders, user3));
    }

    function testIsInSnapshot() public {
        // Setup snapshot
        testTakeSnapshot();

        // Check if addresses are in snapshot
        address[] memory holders = yieldSystem.getSnapshotHolders();

        // Manual check for addresses
        bool user1Found = isAddressInArray(holders, user1);
        bool randomAddressFound = isAddressInArray(holders, address(0x1234));

        assertTrue(user1Found);
        assertFalse(randomAddressFound);
    }

    function testPauseUnpause() public {
        // Test pause functionality
        yieldSystem.pause();
        assertTrue(yieldSystem.paused());

        // Try to take snapshot while paused (should revert)
        vm.expectRevert("Contract is paused");
        yieldSystem.takeHolderSnapshot();

        // Unpause
        yieldSystem.unpause();
        assertFalse(yieldSystem.paused());

        // Should work now
        yieldSystem.takeHolderSnapshot();
        assertTrue(yieldSystem.snapshotActive());
    }

    // Helper function to check if an address is in an array
    function isAddressInArray(address[] memory array, address addr) internal pure returns (bool) {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == addr) {
                return true;
            }
        }
        return false;
    }
}
