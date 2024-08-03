// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {StateMachineHeight} from "./IConsensusClient.sol";
import {StorageValue} from "@polytope-labs/solidity-merkle-trees/Types.sol";

struct PostRequest {
	// the source state machine of this request
	bytes source;
	// the destination state machine of this request
	bytes dest;
	// request nonce
	uint64 nonce;
	// Module Id of this request origin
	bytes from;
	// destination module id
	address to;
	// timestamp by which this request times out.
	uint64 timeoutTimestamp;
	// request body
	bytes body;
}

struct GetRequest {
	// the source state machine of this request
	bytes source;
	// the destination state machine of this request
	bytes dest;
	// request nonce
	uint64 nonce;
	// Module Id of this request origin
	address from;
	// timestamp by which this request times out.
	uint64 timeoutTimestamp;
	// Storage keys to read.
	bytes[] keys;
	// height at which to read destination state machine
	uint64 height;
}

struct GetResponse {
	// The request that initiated this response
	GetRequest request;
	// storage values for get response
	StorageValue[] values;
}

struct PostResponse {
	// The request that initiated this response
	PostRequest request;
	// bytes for post response
	bytes response;
	// timestamp by which this response times out.
	uint64 timeoutTimestamp;
}

// A post request as a leaf in a merkle tree
struct PostRequestLeaf {
	// The request
	PostRequest request;
	// It's index in the mmr leaves
	uint256 index;
	// it's k-index
	uint256 kIndex;
}

// A post response as a leaf in a merkle tree
struct PostResponseLeaf {
	// The response
	PostResponse response;
	// It's index in the mmr leaves
	uint256 index;
	// it's k-index
	uint256 kIndex;
}

// A merkle mountain range proof.
struct Proof {
	// height of the state machine
	StateMachineHeight height;
	// the multi-proof
	bytes32[] multiproof;
	// The total number of leaves in the mmr for this proof.
	uint256 leafCount;
}

// A message for handling incoming requests
struct PostRequestMessage {
	// proof for the requests
	Proof proof;
	// the requests, contained in a merkle tree leaf
	PostRequestLeaf[] requests;
}

// A message for handling incoming GET responses
struct GetResponseMessage {
	// the state (merkle-patricia) proof of the get request keys
	bytes[] proof;
	// the height of the state machine proof
	StateMachineHeight height;
	// The requests that initiated this response
	GetRequest[] requests;
}

struct GetTimeoutMessage {
	// requests which have timed-out
	GetRequest[] timeouts;
}

struct PostTimeout {
	PostRequest request;
}

struct PostRequestTimeoutMessage {
	// requests which have timed-out
	PostRequest[] timeouts;
	// the height of the state machine proof
	StateMachineHeight height;
	// non-membership proof of the requests
	bytes[] proof;
}

struct PostResponseTimeoutMessage {
	// responses which have timed-out
	PostResponse[] timeouts;
	// the height of the state machine proof
	StateMachineHeight height;
	// non-membership proof of the requests
	bytes[] proof;
}

// A message for handling incoming responses
struct PostResponseMessage {
	// proof for the responses
	Proof proof;
	// the responses, contained in a merkle tree leaf
	PostResponseLeaf[] responses;
}

library Message {
	function timeout(PostRequest memory req) internal pure returns (uint64) {
		if (req.timeoutTimestamp == 0) {
			return type(uint64).max;
		} else {
			return req.timeoutTimestamp;
		}
	}

	function timeout(GetRequest memory req) internal pure returns (uint64) {
		if (req.timeoutTimestamp == 0) {
			return type(uint64).max;
		} else {
			return req.timeoutTimestamp;
		}
	}

	function timeout(PostResponse memory res) internal pure returns (uint64) {
		if (res.timeoutTimestamp == 0) {
			return type(uint64).max;
		} else {
			return res.timeoutTimestamp;
		}
	}

	function encodeRequest(PostRequest memory req) internal pure returns (bytes memory) {
		return abi.encodePacked(req.source, req.dest, req.nonce, req.timeoutTimestamp, abi.encodePacked(req.from), req.to, req.body);
	}

	function hash(PostResponse memory res) internal pure returns (bytes32) {
		return
			keccak256(bytes.concat(encodeRequest(res.request), abi.encodePacked(res.response, res.timeoutTimestamp)));
	}

	function hash(PostRequest memory req) internal pure returns (bytes32) {
		return keccak256(encodeRequest(req));
	}

	function hash(GetRequest memory req) internal pure returns (bytes32) {
		bytes memory keysEncoding = bytes("");
		uint256 len = req.keys.length;
		for (uint256 i = 0; i < len; i++) {
			keysEncoding = bytes.concat(keysEncoding, req.keys[i]);
		}

		return
			keccak256(
				abi.encodePacked(
					req.source,
					req.dest,
					req.nonce,
					req.height,
					req.timeoutTimestamp,
					abi.encodePacked(req.from),
					keysEncoding
				)
			);
	}

	function hash(GetResponse memory res) internal pure returns (bytes32) {
		return hash(res.request);
	}
}
