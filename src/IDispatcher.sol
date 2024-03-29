// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {StateMachineHeight} from "./IConsensusClient.sol";
import {PostRequest} from "./Message.sol";

// An object for dispatching post requests to the IsmpDispatcher
struct DispatchPost {
    // bytes representation of the destination state machine
    bytes dest;
    // the destination module
    bytes to;
    // the request body
    bytes body;
    // timeout for this request in seconds
    uint64 timeout;
    // the amount put up to be paid to the relayer, this is in $DAI and charged to tx.origin
    uint256 fee;
    // who pays for this request?
    address payer;
}

// An object for dispatching get requests to the IsmpDispatcher
struct DispatchGet {
    // bytes representation of the destination state machine
    bytes dest;
    // height at which to read the state machine
    uint64 height;
    // Storage keys to read
    bytes[] keys;
    // timeout for this request in seconds
    uint64 timeout;
    // the amount put up to be paid to the relayer, this is in $DAI and charged to tx.origin
    uint256 fee;
    // who pays for this request?
    address payer;
}

struct DispatchPostResponse {
    // The request that initiated this response
    PostRequest request;
    // bytes for post response
    bytes response;
    // timeout for this response in seconds
    uint64 timeout;
    // the amount put up to be paid to the relayer, this is in $DAI and charged to tx.origin
    uint256 fee;
    // who pays for this request?
    address payer;
}

// The core ISMP API, IIsmpModules use this interface to send outgoing get/post requests & responses
interface IDispatcher {
    /**
     * @dev Dispatch a post request to the ISMP router.
     * @param request - post request
     */
    function dispatch(DispatchPost memory request) external;

    /**
     * @dev Dispatch a GET request to the ISMP router.
     * @param request - get request
     */
    function dispatch(DispatchGet memory request) external;

    /**
     * @dev Provide a response to a previously received request.
     * @param response - post response
     */
    function dispatch(DispatchPostResponse memory response) external;
}
