// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../src/EvmHost.sol";
import "../src/interfaces/StateMachine.sol";

contract TestHost is EvmHost {
    function host() external override returns (bytes memory) {
        return StateMachine.ethereum();
    }
}
