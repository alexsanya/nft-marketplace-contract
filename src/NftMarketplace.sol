
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

struct ListingData {
    IERC721 nftContract;
    uint256 tokenId;
    uint256 minPriceCents;
    uint256 nonce;
}

struct BidData {
    IERC20 tokenAddress;
    uint256 value;
    uint256 validUntil;
}

struct Signature {
    uint8 v;
    bytes32 r;
    bytes32 s;
}

contract NftMarketplace {
    using SafeERC20 for IERC20;

    // we need this storage to prevent re-play attack
    mapping(bytes32 => uint256) public nonces;

    event Settlement(address owner, ListingData listingData, BidData bidData);

    function settle(
        address owner,
        address buyer,
        ListingData calldata listingData,
        BidData calldata bidData,
        Signature calldata listingSig,
        Signature calldata bidSig,
        Signature calldata settlementSig
    ) external {
        // cheapest checks at first
        require(block.timestamp <= bidData.validUntil, "Bid is expired");
        // reposess ERC20
        bidData.tokenAddress.safeTransferFrom(buyer, address(this), bidData.value);
        // reposess NFT
        // no need safeTransferFrom cause I know the recepient is this contract
        listingData.nftContract.transferFrom(owner, address(this), listingData.tokenId);
        // check nonce
        bytes32 key = keccak256(abi.encode(owner,listingData.nftContract,listingData.tokenId));
        require(nonces[key] == listingData.nonce, "Nonce is mismatched");
        // check signatures here
        _verifySignatures(owner, buyer, listingData, bidData, listingSig, bidSig, settlementSig);
        // transfer ERC20 and NFT
        bidData.tokenAddress.safeTransfer(owner, bidData.value);
        //no need safeTransferFrom cause I know the recepient is EOA
        listingData.nftContract.transferFrom(address(this), buyer, listingData.tokenId);
        nonces[key] += 1;
        emit Settlement(owner, listingData, bidData);
    }

    function _verifySignatures(
        address owner,
        address buyer,
        ListingData calldata listingData,
        BidData calldata bidData,
        Signature calldata listingSig,
        Signature calldata bidSig,
        Signature calldata settlementSig
    ) pure internal {
        // throw errors if signature is invalid
        // check settlementData signature
        bytes32 listingHash = keccak256(abi.encode(listingData.nftContract,listingData.tokenId,listingData.nonce,listingData.minPriceCents));
        // check that listingHash signed by owner address
        require(
            _checkMessageIsSignedBy(listingHash, owner, listingSig.v, listingSig.r, listingSig.s),
            "Listing signature is invalid"
        );
        bytes32 bidHash = keccak256(abi.encode(bidData.tokenAddress, bidData.value, bidData.validUntil, listingHash));
        // check that bidDataHash signed by owner address
        require(
            _checkMessageIsSignedBy(bidHash, buyer, bidSig.v, bidSig.r, bidSig.s),
            "Bid signature is invalid"
        );
        // check settlement signed by owner
        require(
            _checkMessageIsSignedBy(bidHash, owner, settlementSig.v, settlementSig.r, settlementSig.s),
            "Settlement signature is invalid"
        );
    }

    function _checkMessageIsSignedBy (
        bytes32 data,
        address signer,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) pure internal returns (bool) {
        return signer == ecrecover(data, v, r, s);
    }

}