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
    function onAccept(IncomingPostRequest calldata) external virtual {
        revert("IsmpModule doesn't expect Post requests");
    }

    function onPostRequestTimeout(PostRequest memory) external virtual {
        revert("IsmpModule doesn't emit Post requests");
    }

    function onPostResponse(IncomingPostResponse memory) external virtual {
        revert("IsmpModule doesn't emit Post responses");
    }

    function onPostResponseTimeout(PostResponse memory) external virtual {
        revert("IsmpModule doesn't emit Post responses");
    }

    function onGetResponse(IncomingGetResponse memory) external virtual {
        revert("IsmpModule doesn't emit Get requests");
    }

    function onGetTimeout(GetRequest memory) external virtual {
        revert("IsmpModule doesn't emit Get requests");
    }
}
