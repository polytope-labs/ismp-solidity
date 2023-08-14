// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./IIsmpDispatcher.sol";

interface IIsmpModule {
    /**
     * @dev Called by the local ISMP router on a module, to notify module of a new request the module may choose to respond immediately, or in a later block
     * @param request post request
     */
    function onAccept(PostRequest memory request) external;

    /**
     * @dev Called by the router on a module, to notify module of a post response to a previously sent out request
     * @param response post response
     */
    function onPostResponse(PostResponse memory response) external;

    /**
     * @dev Called by the router on a module, to notify module of a get response to a previously sent out request
     * @param response get response
     */
    function onGetResponse(GetResponse memory response) external;

    /**
     * @dev Called by the router on a module, to notify module of post requests that were previously sent but have now timed-out
     * @param request post request
     */
    function onPostTimeout(PostRequest memory request) external;

    /**
     * @dev Called by the router on a module, to notify module of get requests that were previously sent but have now timed-out
     * @param request get request
     */
    function onGetTimeout(GetRequest memory request) external;
}
