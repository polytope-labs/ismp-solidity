// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {PostRequest, PostResponse, GetResponse, GetRequest} from "./Message.sol";
import {DispatchPost, DispatchPostResponse, DispatchGet} from "./IDispatcher.sol";
import {IIsmpHost} from "./IIsmpHost.sol";

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
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
			IERC20(IIsmpHost(hostAddr).feeToken()).approve(hostAddr, type(uint256).max);
		}
	}

	// @dev Returns the `IsmpHost` address for the current chain.
	// The `IsmpHost` is an immutable contract that will never change.
	function host() public view returns (address h) {
		assembly {
			switch chainid()
			// Ethereum Sepolia
			case 11155111 {
				h := 0x27B0c6960B792a8dCb01F0652bDE48015cd5f23e
			}
			// Arbitrum Sepolia
			case 421614 {
				h := 0xfd7E2b2ad0b29Ec817dC7d406881b225B81dbFCf
			}
			// Optimism Sepolia
			case 11155420 {
				h := 0x30e3af1747B155F37F935E0EC995De5EA4e67586
			}
			// Base Sepolia
			case 84532 {
				h := 0x0D7037bd9CEAEF25e5215f808d309ADD0A65Cdb9
			}
			// Binance Smart Chain Testnet
			case 97 {
				h := 0x4cB0f5750f6fE14d4B86acA6fe126943bdA3c8c4
			}
			// Gnosis Chiado Testnet
			case 10200 {
				h := 0x11EB87c745D97a4Fa8Aec805359837459d240d1b
			}
		}
	}

	// @dev returns the quoted fee for a dispatch
	function quote(DispatchPost memory post) public view returns (uint256) {
		return post.fee + (post.body.length * IIsmpHost(host()).perByteFee());
	}

	// @dev returns the quoted fee for a dispatch
	function quote(DispatchPostResponse memory res) public view returns (uint256) {
		return res.fee + (res.response.length * IIsmpHost(host()).perByteFee());
	}

	// @dev returns the quoted fee for a dispatch
	function quote(DispatchGet memory get) public view returns (uint256) {
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
