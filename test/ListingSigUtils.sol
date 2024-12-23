// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../src/NftMarketplace.sol";

contract ListingSigUtils {
  bytes32 internal DOMAIN_SEPARATOR;

  constructor(bytes32 _DOMAIN_SEPARATOR) {
      DOMAIN_SEPARATOR = _DOMAIN_SEPARATOR;
  }

  // computes the hash of a listing
  function getStructHash(ListingData memory listing)
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

  // computes the hash of the fully encoded EIP-712 message for the domain, which can be used to recover the signer
  function getTypedDataHash(ListingData memory listing)
      public
      view
      returns (bytes32)
  {
      return
          keccak256(
              abi.encodePacked(
                  "\x19\x01",
                  DOMAIN_SEPARATOR,
                  getStructHash(listing)
              )
          );
  }
}
