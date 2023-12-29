// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "openzeppelin/utils/Strings.sol";

library StateMachine {
    /// The identifier for the relay chain.
    uint256 public constant RELAY_CHAIN = 0;

    // Address a state machine on the polkadot relay chain
    function polkadot(uint256 id) public pure returns (bytes memory) {
        return bytes(string.concat("POLKADOT-", Strings.toString(id)));
    }

    // Address a state machine on the kusama relay chain
    function kusama(uint256 id) public pure returns (bytes memory) {
        return bytes(string.concat("KUSAMA-", Strings.toString(id)));
    }

    // Address the ethereum "execution layer"
    function ethereum() public pure returns (bytes memory) {
        return bytes("ETHE");
    }

    // Address the Arbitrum state machine
    function arbitrum() public pure returns (bytes memory) {
        return bytes("ARBI");
    }

    // Address the Optimism state machine
    function optimism() public pure returns (bytes memory) {
        return bytes("OPTI");
    }

    // Address the Base state machine
    function base() public pure returns (bytes memory) {
        return bytes("BASE");
    }

    // Address the Polygon POS state machine
    function polygon() public pure returns (bytes memory) {
        return bytes("POLY");
    }

    // Address the Binance smart chain state machine
    function bsc() public pure returns (bytes memory) {
        return bytes("BSC");
    }
}
