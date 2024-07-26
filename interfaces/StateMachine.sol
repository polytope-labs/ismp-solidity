// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {Strings} from "openzeppelin/utils/Strings.sol";

library StateMachine {
	/// @notice The identifier for the relay chain.
	uint256 public constant RELAY_CHAIN = 0;

	// @notice Address a state machine on the polkadot relay chain
	function polkadot(uint256 id) internal pure returns (bytes memory) {
		return bytes(string.concat("POLKADOT-", Strings.toString(id)));
	}

	// @notice Address a state machine on the kusama relay chain
	function kusama(uint256 id) internal pure returns (bytes memory) {
		return bytes(string.concat("KUSAMA-", Strings.toString(id)));
	}

	// @notice Address the ethereum "execution layer"
	function ethereum() internal pure returns (bytes memory) {
		return bytes("ETH-EXEC");
	}

	// @notice Address the Polygon POS state machine
	function polygon() internal pure returns (bytes memory) {
		return bytes("POLY");
	}

	// @notice Address the Binance smart chain state machine
	function bsc() internal pure returns (bytes memory) {
		return bytes("BSC");
	}

	// @notice Address the Arbitrum state machine
	function arbitrum() internal pure returns (bytes memory) {
		return bytes("ETH-ARBI");
	}

	// @notice Address the Optimism state machine
	function optimism() internal pure returns (bytes memory) {
		return bytes("ETH-OPTI");
	}

	// @notice Address the Base state machine
	function base() internal pure returns (bytes memory) {
		return bytes("ETH-BASE");
	}

	// @notice Address the Blast state machine
	function blast() internal pure returns (bytes memory) {
		return bytes("ETH-BLST");
	}

	// @notice Address the Mantle machine
	function mantle() internal pure returns (bytes memory) {
		return bytes("ETH-MNTL");
	}

	// @notice Address the Manta machine
	function manta() internal pure returns (bytes memory) {
		return bytes("ETH-MNTA");
	}

	// @notice Address the Build on Bitcoin machine
	function bob() internal pure returns (bytes memory) {
		return bytes("ETH-BOB");
	}
}
