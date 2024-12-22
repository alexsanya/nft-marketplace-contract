
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

struct ListingData {
    IERC721 nftContract;
    uint256 tokenId;
    uint256 minPriceCents;
    uint256 nonce;
    uint8 listingSigV;
    bytes32 listingSigR;
    bytes32 listingSigS;
}

struct BidData {
    address tokenAddress;
    address value;
    uint256 validUntil;
    address buyer;
    uint8 bidSigV;
    bytes32 bidSigR;
    bytes32 bidSigS;
}

struct SettlementData {
    uint8 settlementSigV;
    bytes32 settlementSigR;
    bytes32 settlementSigS;
}

contract NftMarketplace {
    using SafeERC20 for ERC20;

    event Settlement(address owner, ListingData listingData, BidData bidData);

    function settle(
        address owner,
        ListingData listingData,
        BidData bidData,
        SettlementData settlmentData
    ) external {
        // cheapest checks at first
        require(block.timestamp <= bidData.validUntil, "Bid is expired");
        // reposess ERC20
        safeTransferFrom(bidData.tokenAddress, bidData.buyer, address(this), bidData.value);
        // reposess NFT
        listingData.nftContract.safeTransferFrom(owner, address(this), listingData.tokenId, "");
        // check signatures here
        _checkSignatures();
        // transfer ERC20 and NFT
        safeTransfer(bidData.tokenAddress, owner, bidData.value);
        safeTransferFrom(address(this), bidData.buyer, listingData.tokenId);
        emit Settlement(owner, listingData, bidData);
    }

    function _checkSignatures(
        address owner,
        ListingData listingData,
        BidData bidData,
        SettlementData settlmentData
    ) internal {
        // thwor errors if signature is invalid
    }

}