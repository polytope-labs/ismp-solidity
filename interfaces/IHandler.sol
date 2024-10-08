// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IIsmpHost} from "./IIsmpHost.sol";
import {
	PostRequestMessage,
	PostResponseMessage,
	GetResponseMessage,
	PostRequestTimeoutMessage,
	PostResponseTimeoutMessage,
	GetTimeoutMessage
} from "./Message.sol";

/*
 * @title The Ismp Handler
 * @author Polytope Labs (hello@polytope.technology)
 *
 * @notice The IHandler interface serves as the entry point for ISMP datagrams, i.e consensus, requests & response messages.
 */
interface IHandler {
	/**
	 * @dev Handle an incoming consensus message. This uses the IConsensusClient contract registered on the host to perform the consensus message verification.
	 * @param host - Ismp host
	 * @param proof - consensus proof
	 */
	function handleConsensus(IIsmpHost host, bytes memory proof) external;

	/**
	 * @dev Handles incoming POST requests, check request proofs, message delay and timeouts, then dispatch POST requests to the apropriate contracts.
	 * @param host - Ismp host
	 * @param request - batch post requests
	 */
	function handlePostRequests(IIsmpHost host, PostRequestMessage memory request) external;

	/**
	 * @dev Handles incoming POST responses, check response proofs, message delay and timeouts, then dispatch POST responses to the apropriate contracts.
	 * @param host - Ismp host
	 * @param response - batch post responses
	 */
	function handlePostResponses(IIsmpHost host, PostResponseMessage memory response) external;

	/**
	 * @dev check response proofs, message delay and timeouts, then dispatch get responses to modules
	 * @param host - Ismp host
	 * @param message - batch get responses
	 */
	function handleGetResponses(IIsmpHost host, GetResponseMessage memory message) external;

	/**
	 * @dev check timeout proofs then dispatch to modules
	 * @param host - Ismp host
	 * @param message - batch post request timeouts
	 */
	function handlePostRequestTimeouts(IIsmpHost host, PostRequestTimeoutMessage memory message) external;

	/**
	 * @dev check timeout proofs then dispatch to modules
	 * @param host - Ismp host
	 * @param message - batch post response timeouts
	 */
	function handlePostResponseTimeouts(IIsmpHost host, PostResponseTimeoutMessage memory message) external;

	/**
	 * @dev dispatch to modules
	 * @param host - Ismp host
	 * @param message - batch get request timeouts
	 */
	function handleGetRequestTimeouts(IIsmpHost host, GetTimeoutMessage memory message) external;
}
