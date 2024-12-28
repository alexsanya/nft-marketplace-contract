
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
    IERC20 tokenContract;
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

    string public constant name = "NFT Marketplace";
    string public constant version = "1";
    bytes32 public immutable DOMAIN_SEPARATOR;

    // we need this storage to prevent re-play attack
    mapping(bytes32 => uint256) public nonces;

    event Settlement(address owner, address buyer, ListingData listingData, BidData bidData);

    constructor(uint256 chainId) {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                chainId,
                address(this)
            )
        );
    }

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
        // check signatures here
        _verifySignatures(owner, buyer, listingData, bidData, listingSig, bidSig, settlementSig);
        // check nonce
        bytes32 key = keccak256(abi.encode(owner,listingData.nftContract,listingData.tokenId));
        require(nonces[key] == listingData.nonce, "Nonce is mismatched");
        // reposess ERC20
        bidData.tokenContract.safeTransferFrom(buyer, address(this), bidData.value);
        // reposess NFT
        // no need safeTransferFrom cause I know the recepient is this contract
        listingData.nftContract.transferFrom(owner, address(this), listingData.tokenId);
        // transfer ERC20 to owner
        bidData.tokenContract.safeTransfer(owner, bidData.value);
        //no need safeTransferFrom cause I know the recepient is EOA
        listingData.nftContract.transferFrom(address(this), buyer, listingData.tokenId);
        nonces[key] += 1;
        emit Settlement(owner, buyer, listingData, bidData);
    }

    function _verifySignatures(
        address owner,
        address buyer,
        ListingData calldata listingData,
        BidData calldata bidData,
        Signature calldata listingSig,
        Signature calldata bidSig,
        Signature calldata settlementSig
    ) view internal {
        // throw errors if signature is invalid
        // check settlementData signature
        bytes32 listingHash = _getTypedDataHash(_getListingHash(listingData));
        // check that listingHash signed by owner address
        require(
            _checkMessageIsSignedBy(listingHash, owner, listingSig.v, listingSig.r, listingSig.s),
            "Listing signature is invalid"
        );
        bytes32 bidHash = _getTypedDataHash(_getBidHash(bidData, listingHash));
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

    function _getListingHash(ListingData memory listing)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    keccak256("Listing(address nftContract,uint256 tokenId,uint256 minPriceCents,uint256 nonce)"),
                    listing.nftContract,
                    listing.tokenId,
                    listing.minPriceCents,
                    listing.nonce
                )
            );
    }

    
    function _getBidHash(BidData memory bid, bytes32 listingHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    keccak256("Bid(address tokenContract,uint256 value,uint256 validUntil,bytes32 listingHash)"),
                    bid.tokenContract,
                    bid.value,
                    bid.validUntil,
                    listingHash
                )
            );
    }

    function _getTypedDataHash(bytes32 data) internal view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    data
                )
            );
    }



}