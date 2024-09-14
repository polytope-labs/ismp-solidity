// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

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

	// @notice Address an evm state machine
	function evm(uint chainid) internal pure returns (bytes memory) {
		return bytes(string.concat("EVM-", Strings.toString(chainid)));
	}
}
