// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {RWALaunchpad} from "../src/RWALaunchpad.sol";
import {RWAToken} from "../src/RWAToken.sol";
import {RWAConstants} from "../src/libraries/RWAConstants.sol";

contract RWALaunchpadTest is Test {
    RWALaunchpad public launchpad;

    // Test accounts
    address public owner = address(0x1);
    address public creator1 = address(0x2);
    address public creator2 = address(0x3);

    // Token parameters
    string public name = "Real Estate Token";
    string public symbol = "RET";
    string public institutionName = "Property Holdings Inc";
    string public institutionAddress = "123 Main St, New York, NY";
    string public documentURI = "ipfs://QmDocument";
    string public imageURI = "ipfs://QmImage";
    uint256 public totalRWASupply = 1000 * 10**18;
    uint256 public pricePerRWA = 100 * 10**18;
    string public description = "Tokenized real estate property in downtown area";

    function setUp() public {
        vm.prank(owner);
        launchpad = new RWALaunchpad();
    }

    function testCreateRWAToken() public {
        vm.prank(creator1);
        address tokenAddress = launchpad.createRWAToken(
            name,
            symbol,
            institutionName,
            institutionAddress,
            documentURI,
            imageURI,
            totalRWASupply,
            pricePerRWA,
            description
        );

        // Verify token was created
        assertTrue(tokenAddress != address(0));

        // Verify token properties
        RWAToken token = RWAToken(tokenAddress);
        assertEq(token.name(), name);
        assertEq(token.symbol(), symbol);
        assertEq(token.totalSupply(), totalRWASupply);
        assertEq(token.balanceOf(creator1), totalRWASupply);

        // Verify token is tracked in launchpad
        address[] memory allTokens = launchpad.getAllTokens();
        assertEq(allTokens.length, 1);
        assertEq(allTokens[0], tokenAddress);

        address[] memory creatorTokens = launchpad.getTokensByCreator(creator1);
        assertEq(creatorTokens.length, 1);
        assertEq(creatorTokens[0], tokenAddress);
    }

    function testCreateMultipleTokens() public {
        // Creator 1 creates a token
        vm.prank(creator1);
        address token1 = launchpad.createRWAToken(
            name,
            symbol,
            institutionName,
            institutionAddress,
            documentURI,
            imageURI,
            totalRWASupply,
            pricePerRWA,
            description
        );

        // Creator 2 creates a token
        vm.prank(creator2);
        address token2 = launchpad.createRWAToken(
            "Commercial Property Token",
            "CPT",
            "Commercial Holdings LLC",
            "456 Business Ave, Chicago, IL",
            "ipfs://QmDocument2",
            "ipfs://QmImage2",
            500 * 10**18,
            200 * 10**18,
            "Tokenized commercial property in business district"
        );

        // Verify tokens are tracked in launchpad
        address[] memory allTokens = launchpad.getAllTokens();
        assertEq(allTokens.length, 2);
        assertEq(allTokens[0], token1);
        assertEq(allTokens[1], token2);

        // Verify creator1's tokens
        address[] memory creator1Tokens = launchpad.getTokensByCreator(creator1);
        assertEq(creator1Tokens.length, 1);
        assertEq(creator1Tokens[0], token1);

        // Verify creator2's tokens
        address[] memory creator2Tokens = launchpad.getTokensByCreator(creator2);
        assertEq(creator2Tokens.length, 1);
        assertEq(creator2Tokens[0], token2);

        // Verify total token count
        assertEq(launchpad.getTotalTokensCount(), 2);
    }

    function testGetTokenAtIndex() public {
        // Create two tokens
        vm.prank(creator1);
        address token1 = launchpad.createRWAToken(
            name,
            symbol,
            institutionName,
            institutionAddress,
            documentURI,
            imageURI,
            totalRWASupply,
            pricePerRWA,
            description
        );

        vm.prank(creator2);
        address token2 = launchpad.createRWAToken(
            "Commercial Property Token",
            "CPT",
            "Commercial Holdings LLC",
            "456 Business Ave, Chicago, IL",
            "ipfs://QmDocument2",
            "ipfs://QmImage2",
            500 * 10**18,
            200 * 10**18,
            "Tokenized commercial property in business district"
        );

        // Test getRWATokenAtIndex
        assertEq(launchpad.getRWATokenAtIndex(0), token1);
        assertEq(launchpad.getRWATokenAtIndex(1), token2);

        // Test getCreatorTokenAtIndex
        assertEq(launchpad.getCreatorTokenAtIndex(creator1, 0), token1);
        assertEq(launchpad.getCreatorTokenAtIndex(creator2, 0), token2);
    }

    function testGetTokenAtIndexOutOfBounds() public {
        // Create a token
        vm.prank(creator1);
        launchpad.createRWAToken(
            name,
            symbol,
            institutionName,
            institutionAddress,
            documentURI,
            imageURI,
            totalRWASupply,
            pricePerRWA,
            description
        );

        // Test getRWATokenAtIndex with out of bounds index
        vm.expectRevert(RWAConstants.InvalidAmount.selector);
        launchpad.getRWATokenAtIndex(1);

        // Test getCreatorTokenAtIndex with out of bounds index
        vm.expectRevert(RWAConstants.InvalidAmount.selector);
        launchpad.getCreatorTokenAtIndex(creator1, 1);

        // Test getCreatorTokenAtIndex with non-existent creator
        vm.expectRevert(RWAConstants.InvalidAmount.selector);
        launchpad.getCreatorTokenAtIndex(creator2, 0);
    }

    function testCreateTokenWithInvalidParams() public {
        // Test with empty name
        vm.prank(creator1);
        vm.expectRevert(RWAConstants.EmptyString.selector);
        launchpad.createRWAToken(
            "",
            symbol,
            institutionName,
            institutionAddress,
            documentURI,
            imageURI,
            totalRWASupply,
            pricePerRWA,
            description
        );

        // Test with empty symbol
        vm.prank(creator1);
        vm.expectRevert(RWAConstants.EmptyString.selector);
        launchpad.createRWAToken(
            name,
            "",
            institutionName,
            institutionAddress,
            documentURI,
            imageURI,
            totalRWASupply,
            pricePerRWA,
            description
        );

        // Test with empty institution name
        vm.prank(creator1);
        vm.expectRevert(RWAConstants.EmptyString.selector);
        launchpad.createRWAToken(
            name,
            symbol,
            "",
            institutionAddress,
            documentURI,
            imageURI,
            totalRWASupply,
            pricePerRWA,
            description
        );

        // Test with zero supply
        vm.prank(creator1);
        vm.expectRevert(RWAConstants.InvalidAmount.selector);
        launchpad.createRWAToken(
            name,
            symbol,
            institutionName,
            institutionAddress,
            documentURI,
            imageURI,
            0,
            pricePerRWA,
            description
        );

        // Test with zero price
        vm.prank(creator1);
        vm.expectRevert(RWAConstants.InvalidAmount.selector);
        launchpad.createRWAToken(
            name,
            symbol,
            institutionName,
            institutionAddress,
            documentURI,
            imageURI,
            totalRWASupply,
            0,
            description
        );
    }
}
