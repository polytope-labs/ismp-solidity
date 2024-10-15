// Copyright (C) Polytope Labs Ltd.
// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// 	http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
pragma solidity ^0.8.17;

import {PostRequest, PostResponse, GetResponse, GetRequest} from "./Message.sol";
import {DispatchPost, DispatchPostResponse, DispatchGet, IDispatcher} from "./IDispatcher.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct IncomingPostRequest {
	// The Post request
	PostRequest request;
	// Relayer responsible for delivering the request
	address relayer;
}

struct IncomingPostResponse {
	// The Post response
	PostResponse response;
	// Relayer responsible for delivering the response
	address relayer;
}

struct IncomingGetResponse {
	// The Get response
	GetResponse response;
	// Relayer responsible for delivering the response
	address relayer;
}

interface IIsmpModule {
	/**
	 * @dev Called by the `IsmpHost` to notify a module of a new request the module may choose to respond immediately, or in a later block
	 * @param incoming post request
	 */
	function onAccept(IncomingPostRequest memory incoming) external;

	/**
	 * @dev Called by the `IsmpHost` to notify a module of a post response to a previously sent out request
	 * @param incoming post response
	 */
	function onPostResponse(IncomingPostResponse memory incoming) external;

	/**
	 * @dev Called by the `IsmpHost` to notify a module of a get response to a previously sent out request
	 * @param incoming get response
	 */
	function onGetResponse(IncomingGetResponse memory incoming) external;

	/**
	 * @dev Called by the `IsmpHost` to notify a module of post requests that were previously sent but have now timed-out
	 * @param request post request
	 */
	function onPostRequestTimeout(PostRequest memory request) external;

	/**
	 * @dev Called by the `IsmpHost` to notify a module of post requests that were previously sent but have now timed-out
	 * @param request post request
	 */
	function onPostResponseTimeout(PostResponse memory request) external;

	/**
	 * @dev Called by the `IsmpHost` to notify a module of get requests that were previously sent but have now timed-out
	 * @param request get request
	 */
	function onGetTimeout(GetRequest memory request) external;
}

// @notice Abstract contract to make implementing `IIsmpModule` easier.
abstract contract BaseIsmpModule is IIsmpModule {
	// @notice Call was not expected
	error UnexpectedCall();

	// @notice Account is unauthorized
	error UnauthorizedCall();

	// @dev restricts caller to the local `IsmpHost`
	modifier onlyHost() {
		if (msg.sender != host()) revert UnauthorizedCall();
		_;
	}

	constructor() {
		address hostAddr = host();
		if (hostAddr != address(0)) {
			// approve the host infintely
			IERC20(IDispatcher(hostAddr).feeToken()).approve(hostAddr, type(uint256).max);
		}
	}

	// @dev Returns the `IsmpHost` address for the current chain.
	// The `IsmpHost` is an immutable contract that will never change.
	function host() public view returns (address h) {
		assembly {
			switch chainid()
			// Ethereum Sepolia
			case 11155111 {
				h := 0x2EdB74C269948b60ec1000040E104cef0eABaae8
			}
			// Arbitrum Sepolia
			case 421614 {
				h := 0x3435bD7e5895356535459D6087D1eB982DAd90e7
			}
			// Optimism Sepolia
			case 11155420 {
				h := 0x6d51b678836d8060d980605d2999eF211809f3C2
			}
			// Base Sepolia
			case 84532 {
				h := 0xD198c01839dd4843918617AfD1e4DDf44Cc3BB4a
			}
			// Binance Smart Chain Testnet
			case 97 {
				h := 0x8Aa0Dea6D675d785A882967Bf38183f6117C09b7
			}
			// Gnosis Chiado Testnet
			case 10200 {
				h := 0x58A41B89F4871725E5D898d98eF4BF917601c5eB
			}
		}
	}

	// @dev returns the quoted fee for a dispatch
	function quote(DispatchPost memory post) public view returns (uint256) {
		return post.fee + (post.body.length * IDispatcher(host()).perByteFee(post.dest));
	}

	// @dev returns the quoted fee for a dispatch
	function quote(DispatchPostResponse memory res) public view returns (uint256) {
		return res.fee + (res.response.length * IDispatcher(host()).perByteFee(res.request.source));
	}

	function onAccept(IncomingPostRequest calldata) external virtual onlyHost {
		revert UnexpectedCall();
	}

	function onPostRequestTimeout(PostRequest memory) external virtual onlyHost {
		revert UnexpectedCall();
	}

	function onPostResponse(IncomingPostResponse memory) external virtual onlyHost {
		revert UnexpectedCall();
	}

	function onPostResponseTimeout(PostResponse memory) external virtual onlyHost {
		revert UnexpectedCall();
	}

	function onGetResponse(IncomingGetResponse memory) external virtual onlyHost {
		revert UnexpectedCall();
	}

	function onGetTimeout(GetRequest memory) external virtual onlyHost {
		revert UnexpectedCall();
	}
}
