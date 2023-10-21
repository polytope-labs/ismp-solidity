// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./IIsmpHost.sol";
import "./IIsmp.sol";

interface IHandler {
    /**
     * @dev Handle incoming consensus messages
     * @param host - Ismp host
     * @param proof - consensus proof
     */
    function handleConsensus(IIsmpHost host, bytes memory proof) external;

    /**
     * @dev check request proofs, message delay and timeouts, then dispatch post requests to modules
     * @param host - Ismp host
     * @param request - batch post requests
     */
    function handlePostRequests(IIsmpHost host, PostRequestMessage memory request) external;

    /**
     * @dev check response proofs, message delay and timeouts, then dispatch post responses to modules
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
    function handlePostTimeouts(IIsmpHost host, PostTimeoutMessage memory message) external;

    /**
     * @dev dispatch to modules
     * @param host - Ismp host
     * @param message - batch get request timeouts
     */
    function handleGetTimeouts(IIsmpHost host, GetTimeoutMessage memory message) external;
}
