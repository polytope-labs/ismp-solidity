// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {Strings} from "openzeppelin/utils/Strings.sol";

library StateMachine {
    /// The identifier for the relay chain.
    uint256 public constant RELAY_CHAIN = 0;

    // Address a state machine on the polkadot relay chain
    function polkadot(uint256 id) internal pure returns (bytes memory) {
        return bytes(string.concat("POLKADOT-", Strings.toString(id)));
    }

    // Address a state machine on the kusama relay chain
    function kusama(uint256 id) internal pure returns (bytes memory) {
        return bytes(string.concat("KUSAMA-", Strings.toString(id)));
    }

    // Address the ethereum "execution layer"
    function ethereum() internal pure returns (bytes memory) {
        return bytes("ETHE");
    }

    // Address the Arbitrum state machine
    function arbitrum() internal pure returns (bytes memory) {
        return bytes("ARBI");
    }

    // Address the Optimism state machine
    function optimism() internal pure returns (bytes memory) {
        return bytes("OPTI");
    }

    // Address the Base state machine
    function base() internal pure returns (bytes memory) {
        return bytes("BASE");
    }

    // Address the Polygon POS state machine
    function polygon() internal pure returns (bytes memory) {
        return bytes("POLY");
    }

    // Address the Binance smart chain state machine
    function bsc() internal pure returns (bytes memory) {
        return bytes("BSC");
    }

    // Address the Blast state machine
    function blast() internal pure returns (bytes memory) {
        return bytes("BLST");
    }

    // Address the Mantle machine
    function mantle() internal pure returns (bytes memory) {
        return bytes("MNTL");
    }

    // Address the Manta machine
    function manta() internal pure returns (bytes memory) {
        return bytes("MNTA");
    }

    // Address the Build on Bitcoin machine
    function bob() internal pure returns (bytes memory) {
        return bytes("BOB");
    }
}
