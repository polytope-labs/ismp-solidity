// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {PostRequest, PostResponse, GetResponse, GetRequest} from "./Message.sol";
import {DispatchPost, DispatchPostResponse, DispatchGet} from "./IDispatcher.sol";
import {IIsmpHost} from "./IIsmpHost.sol";
import {Context} from "openzeppelin/utils/Context.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";

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
	using SafeERC20 for IERC20;

	// @notice Chain is not supported
	error UnsupportedChain();

	// @notice Call was not expected
	error UnexpectedCall();

	// @notice Account is unauthorized
	error UnauthorizedAccount();

	// @dev restricts caller to the local `IsmpHost`
	modifier onlyHost() {
		if (msg.sender != host()) revert UnauthorizedAccount();
		_;
	}

	constructor() {
		// approve the host infintely
		IERC20(IIsmpHost(host()).feeToken()).safeIncreaseAllowance(host(), type(uint256).max);
	}

	// @dev Returns the `IsmpHost` address for the current chain.
	// The `IsmpHost` is an immutable contract that will never change.
	function host() public view returns (address h) {
		assembly {
			switch chainid()
			// Ethereum Sepolia
			case 11155111 {
				h := 0xF1c7a386325B7D22025D7542b28Ee881Cdf107b3
			}
			// Arbitrum Sepolia
			case 421614 {
				h := 0x286e1FE1c323EE626bE802b13a5184b588eD14Cb
			}
			// Optimism Sepolia
			case 11155420 {
				h := 0x625c531a56DB772CC36313d0A0114956aD8b56c2
			}
			// Base Sepolia
			case 84532 {
				h := 0xae9f490EE05588fDD857A078cFC1f5f30ae7185f
			}
			// Binance Smart Chain Testnet
			case 97 {
				h := 0xeB8977EDCdA5FaBDcDdEB39861Df25E8821a9e9b
			}
		}

		if (h == address(0)) revert UnsupportedChain();
	}

	// @dev returns the quoted fee for a dispatch
	function quote(DispatchPost memory post) internal view returns (uint256) {
		return post.body.length * IIsmpHost(host()).perByteFee();
	}

	// @dev returns the quoted fee for a dispatch
	function quote(DispatchPostResponse memory res) internal view returns (uint256) {
		return res.response.length * IIsmpHost(host()).perByteFee();
	}

	// @dev returns the quoted fee for a dispatch
	function quote(DispatchGet memory get) internal view returns (uint256) {
		return get.fee + (get.context.length * IIsmpHost(host()).perByteFee());
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
