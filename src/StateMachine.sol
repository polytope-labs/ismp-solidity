// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "openzeppelin/utils/Strings.sol";

library StateMachine {
    /// The identifier for the relay chain.
    uint256 public constant RELAY_CHAIN = 0;

    // Address a state machine on the polkadot relay chain
    function polkadot(uint256 id) public returns (bytes memory) {
        return bytes(string.concat("POLKADOT-", Strings.toString(id)));
    }

    // Address a state machine on the kusama relay chain
    function kusama(uint256 id) public returns (bytes memory) {
        return bytes(string.concat("KUSAMA-", Strings.toString(id)));
    }

    // Address the ethereum "execution layer"
    function ethereum() public returns (bytes memory) {
        return bytes("ETH");
    }

    // Address the Arbitrum state machine
    function arbitrum() public returns (bytes memory) {
        return bytes("ARB");
    }

    // Address the Optimism state machine
    function optimism() public returns (bytes memory) {
        return bytes("OP");
    }

    // Address the Base state machine
    function base() public returns (bytes memory) {
        return bytes("BASE");
    }
}
