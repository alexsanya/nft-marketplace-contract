// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Proxy {
    address private immutable owner;
    address private immutable implementation;
    address private immutable nftMarketplace;
    bytes private settleCalldata;

    constructor(address _implementation, address _nftMarketplace) {
        owner = msg.sender;
        nftMarketplace = _nftMarketplace;
        implementation = _implementation;
    }

    function setSettleCalldata(bytes memory _settleCalldata) external {
        settleCalldata = _settleCalldata;
    }

    function transferFrom(address from, address to, uint256 tokenId) external {
        if (msg.sender == nftMarketplace) {
            (bool success,) = nftMarketplace.call(settleCalldata);
            if (!success) {
                _delegate(implementation);
            }
        } else {
            _delegate(implementation);
        }
    }

    fallback() external payable {
        _fallback();
    }

    receive() external payable {
        _fallback();
    }

    // Internal fallback() to call in both fallback() & receive()
    function _fallback() private {
        _delegate(implementation);
    }

    // Internal _delegate to access return data from delegatecall
    function _delegate(address _impl) private {
        // copied from openzeppelin transparent upgradeable proxy docs
        assembly {
            let ptr := mload(0x40)

            // (1) copy incoming call data
            calldatacopy(ptr, 0, calldatasize())

            // (2) forward call to logic contract
            let result := call(gas(), _impl, callvalue(), ptr, calldatasize(), 0, 0)
            let size := returndatasize()

            // (3) retrieve return data
            returndatacopy(ptr, 0, size)

            // (4) forward return data back to caller
            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
}
