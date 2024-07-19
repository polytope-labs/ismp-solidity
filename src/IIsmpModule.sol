// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {PostRequest, PostResponse, GetResponse, GetRequest} from "./Message.sol";
import {DispatchPost, DispatchPostResponse} from "./IDispatcher.sol";
import {IIsmpHost} from "./IIsmpHost.sol";

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
    // @notice Chain is not supported
    error UnsupportedChain();

    // @notice Call was not expected
    error UnexpectedCall();

    // @notice Account is unauthorized
    error UnauthorizedAccount();

    // @dev restricts caller to the local `IsmpHost`
    modifier onlyHost() {
        if (msg.sender != hostAddr()) revert UnauthorizedAccount();
        _;
    }

    // @dev Returns the `IsmpHost` address for the current chain.
    // The `IsmpHost` is an immutable contract that will never change.
    function hostAddr() internal view returns (address h) {
        assembly {
            switch chainid()
            // Ethereum Sepolia
            case 11155111 { h := 0xF0be651F382cd794aaB1b83584aA458B756bd4cF }
            // Arbitrum Sepolia
            case 421614 { h := 0x7da46FB3b77B34eF6eCf055915ACb1D46565fB41 }
            // Optimism Sepolia
            case 11155420 { h := 0x8Ac39DfC1F2616e5e19B93420C6d008a8a8EE65f }
            // Base Sepolia
            case 84532 { h := 0xf8Dba4EB00621c57787634F8dEBDDb188BC7238E }
            // Binance Smart Chain Testnet
            case 97 { h := 0xa3F07C94A7E6cD9367a2E0C0F4247eB2AC467C86 }
        }

        if (h == address(0)) revert UnsupportedChain();
    }

    // @dev returns the quoted fee for a dispatch
    function quoteFee(DispatchPost memory post) internal view returns (uint256) {
    	return post.body.length * IIsmpHost(hostAddr()).perByteFee();
    }

    // @dev returns the quoted fee for a dispatch
    function quoteFee(DispatchPostResponse memory res) internal view returns (uint256) {
    	return res.response.length * IIsmpHost(hostAddr()).perByteFee();
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
