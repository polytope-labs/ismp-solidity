// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "solidity-merkle-trees/MerklePatricia.sol";

import {StateMachineHeight} from "./IConsensusClient.sol";

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
    bytes to;
    // timestamp by which this request times out.
    uint64 timeoutTimestamp;
    // request body
    bytes body;
    // gas limit for executing this request on destination & its response (if any) on the source.
    uint64 gaslimit;
}

struct GetRequest {
    // the source state machine of this request
    bytes source;
    // the destination state machine of this request
    bytes dest;
    // request nonce
    uint64 nonce;
    // Module Id of this request origin
    bytes from;
    // timestamp by which this request times out.
    uint64 timeoutTimestamp;
    // Storage keys to read.
    bytes[] keys;
    // height at which to read destination state machine
    uint64 height;
    // gas limit for executing this request on destination & its response (if any) on the source.
    uint64 gaslimit;
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
}

// A post request as a leaf in a merkle tree
struct PostRequestLeaf {
    // The request
    PostRequest request;
    // it's merkle mountain range index
    uint256 mmrIndex;
    // it's k-index
    uint256 kIndex;
}

// A post response as a leaf in a merkle tree
struct PostResponseLeaf {
    // The response
    PostResponse response;
    // it's merkle mountain range index
    uint256 mmrIndex;
    // it's k-index
    uint256 kIndex;
}

// A merkle mountain range proof.
struct Proof {
    // height of the state machine
    StateMachineHeight height;
    // the multi-proof
    bytes32[] multiproof;
    // The total size of the mmr for this proof
    uint256 mmrSize;
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

struct PostTimeoutMessage {
    // requests which have timed-out
    PostRequest[] timeouts;
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

// An object for dispatching post requests to the IsmpDispatcher
struct DispatchPost {
    // bytes representation of the destination chain
    bytes dest;
    // the destination module
    bytes to;
    // the request body
    bytes body;
    // the timestamp at which this request should timeout
    uint64 timeoutTimestamp;
    // gas limit for executing this request on destination & its response (if any) on the source.
    uint64 gaslimit;
}

// An object for dispatching get requests to the IsmpDispatcher
struct DispatchGet {
    // bytes representation of the destination chain
    bytes dest;
    // height at which to read the state machine
    uint64 height;
    // Storage keys to read
    bytes[] keys;
    // the timestamp at which this request should timeout
    uint64 timeoutTimestamp;
    // gas limit for executing this request on destination & its response (if any) on the source.
    uint64 gaslimit;
}

interface IIsmpDispatcher {
    /**
     * @dev Dispatch a post request to the ISMP router.
     * @param request - post request
     */
    function dispatch(DispatchPost memory request) external;

    /**
     * @dev Dispatch a get request to the ISMP router.
     * @param request - get request
     */
    function dispatch(DispatchGet memory request) external;

    /**
     * @dev Provide a response to a previously received request.
     * @param response - post response
     */
    function dispatch(PostResponse memory response) external;
}

library Message {
    function hash(PostResponse memory res) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    res.request.source,
                    res.request.dest,
                    res.request.nonce,
                    res.request.timeoutTimestamp,
                    res.request.body,
                    res.request.from,
                    res.request.to,
                    res.response
                )
            );
    }

    function hash(PostRequest memory req) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    req.source,
                    req.dest,
                    req.nonce,
                    req.timeoutTimestamp,
                    req.from,
                    req.to,
                    req.body,
                    req.gaslimit
                )
            );
    }

    function hash(GetRequest memory req) internal pure returns (bytes32) {
        bytes memory keysEncoding = abi.encode(req.keys);
        return
            keccak256(
                abi.encodePacked(
                    req.source,
                    req.dest,
                    req.nonce,
                    req.height,
                    req.timeoutTimestamp,
                    req.from,
                    keysEncoding,
                    req.gaslimit
                )
            );
    }
}
