// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {RWAToken} from "../src/RWAToken.sol";
import {RWAConstants} from "../src/libraries/RWAConstants.sol";

contract RWATokenTest is Test {
    RWAToken public token;

    // Test accounts
    address public owner = address(0x1);
    address public user1 = address(0x2);
    address public user2 = address(0x3);

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
        vm.startPrank(owner);
        token = new RWAToken(
            name,
            symbol,
            institutionName,
            institutionAddress,
            documentURI,
            imageURI,
            totalRWASupply,
            pricePerRWA,
            description,
            owner
        );
        vm.stopPrank();
    }

    function testInitialState() public {
        // Check basic token properties
        assertEq(token.name(), name);
        assertEq(token.symbol(), symbol);
        assertEq(token.totalSupply(), totalRWASupply);
        assertEq(token.balanceOf(owner), totalRWASupply);

        // Check metadata
        (
            string memory _institutionName,
            string memory _institutionAddress,
            string memory _documentURI,
            string memory _imageURI,
            uint256 _totalRWASupply,
            uint256 _pricePerRWA,
            string memory _description
        ) = token.getMetadata();

        assertEq(_institutionName, institutionName);
        assertEq(_institutionAddress, institutionAddress);
        assertEq(_documentURI, documentURI);
        assertEq(_imageURI, imageURI);
        assertEq(_totalRWASupply, totalRWASupply);
        assertEq(_pricePerRWA, pricePerRWA);
        assertEq(_description, description);

        // KYC functionality removed as Evera is a permissionless platform
    }

    function testUpdatePrice() public {
        uint256 newPrice = 200 * 10**18;

        vm.prank(owner);
        token.updatePrice(newPrice);

        (,,,,, uint256 _pricePerRWA,) = token.getMetadata();
        assertEq(_pricePerRWA, newPrice);
    }

    function testUpdatePriceNotOwner() public {
        uint256 newPrice = 200 * 10**18;

        vm.prank(user1);
        vm.expectRevert();
        token.updatePrice(newPrice);
    }

    function testUpdatePriceZero() public {
        vm.prank(owner);
        vm.expectRevert(RWAConstants.InvalidAmount.selector);
        token.updatePrice(0);
    }

    function testUpdateDocumentURI() public {
        string memory newDocumentURI = "ipfs://QmNewDocument";

        vm.prank(owner);
        token.updateDocumentURI(newDocumentURI);

        (,, string memory _documentURI,,,,) = token.getMetadata();
        assertEq(_documentURI, newDocumentURI);
    }

    function testUpdateImageURI() public {
        string memory newImageURI = "ipfs://QmNewImage";

        vm.prank(owner);
        token.updateImageURI(newImageURI);

        (,,, string memory _imageURI,,,) = token.getMetadata();
        assertEq(_imageURI, newImageURI);
    }

    function testPauseUnpause() public {
        vm.startPrank(owner);

        // Test pause
        token.pause();

        // Try to transfer while paused
        vm.expectRevert();
        token.transfer(user1, 100);

        // Test unpause
        token.unpause();

        // Transfer should work now
        token.transfer(user1, 100);
        assertEq(token.balanceOf(user1), 100);

        vm.stopPrank();
    }

    // KYC-related tests removed as Evera is a permissionless platform

    function testBurn() public {
        vm.startPrank(owner);

        uint256 initialSupply = token.totalSupply();
        uint256 burnAmount = 100;

        token.burn(burnAmount);

        assertEq(token.totalSupply(), initialSupply - burnAmount);
        assertEq(token.balanceOf(owner), initialSupply - burnAmount);

        vm.stopPrank();
    }

    function testBurnFrom() public {
        vm.startPrank(owner);

        // Transfer to user1
        token.transfer(user1, 100);
        assertEq(token.balanceOf(user1), 100);

        vm.stopPrank();

        // Approve owner to spend user1's tokens
        vm.prank(user1);
        token.approve(owner, 50);

        // Owner burns from user1
        vm.prank(owner);
        token.burnFrom(user1, 50);

        assertEq(token.balanceOf(user1), 50);
    }

    function testTransferBetweenUsers() public {
        // Create a token
        vm.startPrank(owner);
        RWAToken newToken = new RWAToken(
            name,
            symbol,
            institutionName,
            institutionAddress,
            documentURI,
            imageURI,
            totalRWASupply,
            pricePerRWA,
            description,
            owner
        );

        // Transfer should work for any user (permissionless)
        newToken.transfer(user1, 100);
        assertEq(newToken.balanceOf(user1), 100);

        vm.stopPrank();

        // Transfer from user1 to user2 should work (permissionless)
        vm.prank(user1);
        newToken.transfer(user2, 50);
        assertEq(newToken.balanceOf(user1), 50);
        assertEq(newToken.balanceOf(user2), 50);
    }
}
