// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {StateMachineHeight} from "./IConsensusClient.sol";
import {PostRequest} from "./Message.sol";

// @notice An object for dispatching post requests to the Hyperbridge
struct DispatchPost {
	// bytes representation of the destination state machine
	bytes dest;
	// the destination module
	bytes to;
	// the request body
	bytes body;
	// timeout for this request in seconds
	uint64 timeout;
	// the amount put up to be paid to the relayer,
	// this is charged in `IIsmpHost.feeToken` to `msg.sender`
	uint256 fee;
	// who pays for this request?
	address payer;
}

// @notice An object for dispatching get requests to the Hyperbridge
struct DispatchGet {
	// bytes representation of the destination state machine
	bytes dest;
	// height at which to read the state machine
	uint64 height;
	// storage keys to read
	bytes[] keys;
	// timeout for this request in seconds
	uint64 timeout;
	// Hyperbridge protocol fees for processing this request.
	uint256 fee;
}

struct DispatchPostResponse {
	// The request that initiated this response
	PostRequest request;
	// bytes for post response
	bytes response;
	// timeout for this response in seconds
	uint64 timeout;
	// the amount put up to be paid to the relayer,
	// this is charged in `IIsmpHost.feeToken` to `msg.sender`
	uint256 fee;
	// who pays for this request?
	address payer;
}

/*
 * @title The Ismp Dispatcher
 * @author Polytope Labs (hello@polytope.technology)
 *
 * @notice The IHandler interface serves as the entry point for ISMP datagrams, i.e consensus, requests & response messages.
 */
interface IDispatcher {
	/**
	 * @dev Dispatch a POST request to Hyperbridge
	 *
	 * @notice Payment for the request can either be made with the native token or the IIsmpHost.feeToken.
	 * If native tokens are supplied, it will perform a swap under the hood using the local uniswap router.
	 * Will revert if enough native tokens are not provided.
	 *
	 * If no native tokens are provided then it will try to collect payment from the calling contract in
	 * the IIsmpHost.feeToken.
	 *
	 * @param request - post request
	 * @return commitment - the request commitment
	 */
	function dispatch(DispatchPost memory request) external payable returns (bytes32 commitment);

	/**
	 * @dev Dispatch a GET request to Hyperbridge
	 *
	 * @notice Payment for the request can either be made with the native token or the IIsmpHost.feeToken.
	 * If native tokens are supplied, it will perform a swap under the hood using the local uniswap router.
	 * Will revert if enough native tokens are not provided.
	 *
	 * If no native tokens are provided then it will try to collect payment from the calling contract in
	 * the IIsmpHost.feeToken.
	 *
	 * @param request - get request
	 * @return commitment - the request commitment
	 */
	function dispatch(DispatchGet memory request) external payable returns (bytes32 commitment);

	/**
	 * @dev Dispatch a POST response to Hyperbridge
	 *
	 * @notice Payment for the request can either be made with the native token or the IIsmpHost.feeToken.
	 * If native tokens are supplied, it will perform a swap under the hood using the local uniswap router.
	 * Will revert if enough native tokens are not provided.
	 *
	 * If no native tokens are provided then it will try to collect payment from the calling contract in
	 * the IIsmpHost.feeToken.
	 *
	 * @param response - post response
	 * @return commitment - the request commitment
	 */
	function dispatch(DispatchPostResponse memory response) external payable returns (bytes32 commitment);

	/**
	 * @dev Increase the relayer fee for a previously dispatched request.
	 * This is provided for use only on pending requests, such that when they timeout,
	 * the user can recover the entire relayer fee.
	 *
	 * @notice Payment can either be made with the native token or the IIsmpHost.feeToken.
	 * If native tokens are supplied, it will perform a swap under the hood using the local uniswap router.
	 * Will revert if enough native tokens are not provided.
	 *
	 * If no native tokens are provided then it will try to collect payment from the calling contract in
	 * the IIsmpHost.feeToken.
	 *
	 * If called on an already delivered request, these funds will be seen as a donation to the hyperbridge protocol.
	 * @param commitment - The request commitment
	 * @param amount - The amount provided in `IIsmpHost.feeToken()`
	 */
	function fundRequest(bytes32 commitment, uint256 amount) external payable;

	/**
	 * @dev Increase the relayer fee for a previously dispatched response.
	 * This is provided for use only on pending responses, such that when they timeout,
	 * the user can recover the entire relayer fee.
	 *
	 * @notice Payment can either be made with the native token or the IIsmpHost.feeToken.
	 * If native tokens are supplied, it will perform a swap under the hood using the local uniswap router.
	 * Will revert if enough native tokens are not provided.
	 *
	 * If no native tokens are provided then it will try to collect payment from the calling contract in
	 * the IIsmpHost.feeToken.
	 *
	 * If called on an already delivered response, these funds will be seen as a donation to the hyperbridge protocol.
	 * @param commitment - The response commitment
	 * @param amount - The amount to be provided in `IIsmpHost.feeToken()`
	 */
	function fundResponse(bytes32 commitment, uint256 amount) external payable;
}
