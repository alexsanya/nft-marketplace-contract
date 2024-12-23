// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {NftMarketplace, ListingData, BidData, Signature} from "../src/NftMarketplace.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract TestERC20 is ERC20 {
    constructor() ERC20("Test", "TST") {
        _mint(msg.sender, 500);
        this;
    }
}

contract TestERC721 is ERC721 {
    constructor() ERC721("NFTtest", "NTST") {
        _mint(msg.sender, 1);
        this;
    }
}

contract NftMarketplaceTest is Test {
    uint256 constant OWNER_PRIVATE_KEY = 0xA11CE;
    uint256 constant BUYER_PROVATE_KEY = 150e6;

    NftMarketplace public nftMarketplace;
    TestERC20 public erc20;
    TestERC721 public erc721;
    address owner;
    address buyer;

    ListingData public listingData;
    BidData public bidData;
    Signature signature;

    function setUp() public {
        nftMarketplace = new NftMarketplace();
        // create owner account
        owner = vm.addr(OWNER_PRIVATE_KEY);
        vm.startPrank(owner);
        // create NFT
        erc721 = new TestERC721();
        // approve NFT to nftMarketplace
        erc721.setApprovalForAll(address(nftMarketplace), true);
        vm.stopPrank();
        // create byuer account
        buyer = vm.addr(BUYER_PROVATE_KEY);
        vm.startPrank(buyer);
        // create ERC20
        erc20 = new TestERC20();
        // approve ERC20 to nftMarketplace
        erc20.approve(address(nftMarketplace), erc20.balanceOf(buyer));
        vm.stopPrank();
        
        bytes32 example = keccak256(abi.encodePacked("example data"));

        signature = Signature({
            v: 5,
            r: example,
            s: example
        });

        listingData = ListingData({
            nftContract: erc721,
            tokenId: 1,
            minPriceCents: 100500,
            nonce: 0
        });
        
        bidData = BidData({
            tokenAddress: erc20,
            value: 250,
            validUntil: block.timestamp + 1 hours
        });
    }

    function test_Init() public view {
        assertEq(erc20.balanceOf(buyer), 500);
        assertEq(erc721.balanceOf(owner), 1);
        assertEq(erc721.ownerOf(1), owner);
        assertEq(erc20.allowance(buyer, address(nftMarketplace)), 500);
        assertTrue(erc721.isApprovedForAll(owner, address(nftMarketplace)));
    }

    function test_settlement_success() public {
        nftMarketplace.settle(owner, buyer, listingData, bidData, signature, signature, signature);
        assertEq(erc20.balanceOf(buyer), 250);
        assertEq(erc20.balanceOf(owner), 250);
        assertEq(erc721.balanceOf(buyer), 1);
        assertEq(erc721.ownerOf(1), buyer);
        bytes32 key = keccak256(abi.encode(owner,listingData.nftContract,listingData.tokenId));
        assertEq(nftMarketplace.nonces(key), 1);
    }
    
    function test_settlement_deadline_expired() public {
        bidData.validUntil = 0;
        vm.expectRevert("Bid is expired");
        nftMarketplace.settle(owner, buyer, listingData, bidData, signature, signature, signature);
    }

    function test_settlement_nonce_incorrect() public {
        listingData.nonce = 1;
        vm.expectRevert("Nonce is mismatched");
        nftMarketplace.settle(owner, buyer, listingData, bidData, signature, signature, signature);
    }

    function test_owner_missing_nft() public {
        vm.prank(owner);
        erc721.transferFrom(owner, address(this), 1);
        vm.expectRevert();
        nftMarketplace.settle(owner, buyer, listingData, bidData, signature, signature, signature);
    }

    function test_buyer_missing_tokens() public {
        vm.prank(buyer);
        erc20.transfer(address(this), 500);
        vm.expectRevert();
        nftMarketplace.settle(owner, buyer, listingData, bidData, signature, signature, signature);
    }

}
