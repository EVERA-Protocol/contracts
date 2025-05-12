// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/YieldDistributionSystemFactory.sol";
import "../src/YieldDistributionSystem.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Simple ERC20 token for testing
contract TestToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("Test Token", "TEST") {
        _mint(msg.sender, initialSupply);
    }
}

contract YieldDistributionSystemFactoryTest is Test {
    YieldDistributionSystemFactory public factory;
    TestToken public token1;
    TestToken public token2;
    address public admin;
    address public user1;

    uint256 public constant INITIAL_SUPPLY = 1000 * 10 ** 18;

    function setUp() public {
        // Setup accounts
        admin = address(this);
        user1 = address(0x1);

        // Deploy test tokens
        token1 = new TestToken(INITIAL_SUPPLY);
        token2 = new TestToken(INITIAL_SUPPLY);

        // Deploy factory
        factory = new YieldDistributionSystemFactory();

        // Give user1 some ETH for transactions
        vm.deal(user1, 100 ether);
    }

    function testDeployment() public {
        // Verify initial state
        assertEq(factory.getYieldSystemCount(), 0);

        // Verify empty array
        address[] memory systems = factory.getAllYieldSystems();
        assertEq(systems.length, 0);
    }

    function testCreateYieldSystem() public {
        // Create a yield system for token1
        address payable yieldSystemAddress = payable(factory.createYieldSystem(address(token1)));

        // Verify state updates
        assertEq(factory.getYieldSystemCount(), 1);
        assertEq(factory.getYieldSystem(address(token1)), yieldSystemAddress);

        // Verify all systems array
        address[] memory systems = factory.getAllYieldSystems();
        assertEq(systems.length, 1);
        assertEq(systems[0], yieldSystemAddress);

        // Verify the deployed yield system's properties
        YieldDistributionSystem yieldSystem = YieldDistributionSystem(yieldSystemAddress);
        assertEq(address(yieldSystem.tokenContract()), address(token1));
        assertEq(yieldSystem.owner(), admin);
    }

    function testCreateMultipleYieldSystems() public {
        // Create yield systems for both tokens
        address payable yieldSystem1 = payable(factory.createYieldSystem(address(token1)));
        address payable yieldSystem2 = payable(factory.createYieldSystem(address(token2)));

        // Verify state updates
        assertEq(factory.getYieldSystemCount(), 2);
        assertEq(factory.getYieldSystem(address(token1)), yieldSystem1);
        assertEq(factory.getYieldSystem(address(token2)), yieldSystem2);

        // Verify all systems array
        address[] memory systems = factory.getAllYieldSystems();
        assertEq(systems.length, 2);
        assertEq(systems[0], yieldSystem1);
        assertEq(systems[1], yieldSystem2);
    }

    function testPreventDuplicateYieldSystem() public {
        // Create a yield system for token1
        factory.createYieldSystem(address(token1));

        // Trying to create another for the same token should fail
        vm.expectRevert("Yield system already exists for token");
        factory.createYieldSystem(address(token1));
    }

    function testPreventZeroAddress() public {
        // Trying to create a yield system for zero address should fail
        vm.expectRevert("Invalid token address");
        factory.createYieldSystem(address(0));
    }

    function testOwnershipTransfer() public {
        // Create a yield system as admin
        vm.prank(user1);
        address payable yieldSystemAddress = payable(factory.createYieldSystem(address(token1)));

        // Verify the ownership was transferred to user1
        YieldDistributionSystem yieldSystem = YieldDistributionSystem(yieldSystemAddress);
        assertEq(yieldSystem.owner(), user1);
    }
}
