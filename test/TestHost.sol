// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../src/EvmHost.sol";
import "../src/interfaces/StateMachine.sol";

contract TestHost is EvmHost {
    constructor(HostParams memory params) EvmHost(params) {}

    function host() public override returns (bytes memory) {
        return StateMachine.ethereum();
    }
}

interface Hevm {
    // Set block.timestamp (newTimestamp)
    function warp(uint256) external;
}
