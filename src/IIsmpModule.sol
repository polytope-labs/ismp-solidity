// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {PostRequest, PostResponse, GetResponse, GetRequest} from "./Message.sol";

interface IIsmpModule {
    /**
     * @dev Called by the IsmpHost to notify a module of a new request the module may choose to respond immediately, or in a later block
     * @param request post request
     */
    function onAccept(PostRequest memory request) external;

    /**
     * @dev Called by the IsmpHost to notify a module of a post response to a previously sent out request
     * @param response post response
     */
    function onPostResponse(PostResponse memory response) external;

    /**
     * @dev Called by the IsmpHost to notify a module of a get response to a previously sent out request
     * @param response get response
     */
    function onGetResponse(GetResponse memory response) external;

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
    function onAccept(PostRequest calldata) external virtual {
        revert("IsmpModule doesn't expect Post requests");
    }

    function onPostRequestTimeout(PostRequest memory) external virtual {
        revert("IsmpModule doesn't emit Post requests");
    }

    function onPostResponse(PostResponse memory) external virtual {
        revert("IsmpModule doesn't emit Post responses");
    }

    function onPostResponseTimeout(PostResponse memory) external virtual {
        revert("IsmpModule doesn't emit Post responses");
    }

    function onGetResponse(GetResponse memory) external virtual {
        revert("IsmpModule doesn't emit Get requests");
    }

    function onGetTimeout(GetRequest memory) external virtual {
        revert("IsmpModule doesn't emit Get requests");
    }
}
