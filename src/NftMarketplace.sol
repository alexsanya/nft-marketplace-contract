
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

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
    IERC20 tokenAddress;
    uint256 value;
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

contract NftMarketplace is ERC721Holder {
    using SafeERC20 for IERC20;

    mapping(bytes32 => uint256) nonces;

    event Settlement(address owner, ListingData listingData, BidData bidData);

    function settle(
        address owner,
        ListingData calldata listingData,
        BidData calldata bidData,
        SettlementData calldata settlementData
    ) external {
        // cheapest checks at first
        require(block.timestamp <= bidData.validUntil, "Bid is expired");
        // reposess ERC20
        bidData.tokenAddress.safeTransferFrom(bidData.buyer, address(this), bidData.value);
        // reposess NFT
        listingData.nftContract.safeTransferFrom(owner, address(this), listingData.tokenId, "");
        // check nonce
        require(nonces[settlementData.settlementSigS] == listingData.nonce, "Nonce is mismatched");
        // check signatures here
        _checkSignatures(owner, listingData, bidData, settlementData);
        // transfer ERC20 and NFT
        bidData.tokenAddress.safeTransfer(owner, bidData.value);
        listingData.nftContract.safeTransferFrom(address(this), bidData.buyer, listingData.tokenId);
        nonces[settlementData.settlementSigS] += 1;
        emit Settlement(owner, listingData, bidData);
    }

    function _checkSignatures(
        address owner,
        ListingData calldata listingData,
        BidData calldata bidData,
        SettlementData calldata settlementData
    ) internal {
        // thwor errors if signature is invalid
    }

}