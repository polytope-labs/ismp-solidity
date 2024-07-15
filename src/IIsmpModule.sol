// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {PostRequest, PostResponse, GetResponse, GetRequest} from "./Message.sol";

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
     * @dev Called by the IsmpHost to notify a module of a new request the module may choose to respond immediately, or in a later block
     * @param incoming post request
     */
    function onAccept(IncomingPostRequest memory incoming) external;

    /**
     * @dev Called by the IsmpHost to notify a module of a post response to a previously sent out request
     * @param incoming post response
     */
    function onPostResponse(IncomingPostResponse memory incoming) external;

    /**
     * @dev Called by the IsmpHost to notify a module of a get response to a previously sent out request
     * @param incoming get response
     */
    function onGetResponse(IncomingGetResponse memory incoming) external;

    /**
     * @dev Called by the IsmpHost to notify a module of post requests that were previously sent but have now timed-out
     * @param request post request
     */
    function onPostRequestTimeout(PostRequest memory request) external;

    /**
     * @dev Called by the IsmpHost to notify a module of post requests that were previously sent but have now timed-out
     * @param request post request
     */
    function onPostResponseTimeout(PostResponse memory request) external;

    /**
     * @dev Called by the IsmpHost to notify a module of get requests that were previously sent but have now timed-out
     * @param request get request
     */
    function onGetTimeout(GetRequest memory request) external;
}

/// Abstract contract to make implementing `IIsmpModule` easier.
abstract contract BaseIsmpModule is IIsmpModule {
    // Chain is not supported
    error UnsupportedChain();

    // Call was not expected
    error UnexpectedCall();

    // Account is unauthorized
    error UnauthorizedAccount();

    modifier onlyHost() {
        if (msg.sender != host()) revert UnauthorizedAccount();
        _;
    }

    // Returns the IsmpHost address for the current chain. The IsmpHost is an immutable
    // contract that will never change.
    function hostAddr() internal view returns (address h) {
        assembly {
            switch chainid()
            // Ethereum Sepolia
            case 11155111 { h := 0xbDFa473d7E483e088348e071480B624A248b2fC4 }
            // Arbitrum Sepolia
            case 421614 { h := 0xC98976841a69Ce52d4D17B286A1698963E847982 }
            // Optimism Sepolia
            case 11155420 { h := 0x0D811D581D615AA44A36aa638825403F9b434E18 }
            // Base Sepolia
            case 84532 { h := 0x7FaBb96851517583eA7df7d6e9Dd28afc2fA38f5 }
            // Binance Smart Chain Testnet
            case 97 { h := 0xE6bd95737DD35Fd0e5f134771A832405671f06e9 }
        }

        if (h == address(0)) revert UnsupportedChain();
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
