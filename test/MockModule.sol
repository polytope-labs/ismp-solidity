// SPDX-License-Identifier: UNLICENSED
// A Sample ISMP solidity contract for unit tests

pragma solidity ^0.8.2;

import "../src/interfaces/IIsmpModule.sol";

contract MockModule is IIsmpModule {
    event PostResponseReceived();
    event GetResponseReceived();
    event PostTimeoutReceived();
    event GetTimeoutReceived();
    event PostReceived();

    error NotIsmpHost();
    error ExecutionFailed();

    // restricts call to `IIsmpHost`
    modifier onlyIsmpHost() {
        if (msg.sender != _host) {
            revert NotIsmpHost();
        }
        _;
    }

    address internal _host;

    constructor(address host) {
        _host = host;
    }

    function dispatchPost(PostRequest memory request) public returns (bytes32) {
        bytes32 commitment = Message.hash(request);
        DispatchPost memory dispatchPost = DispatchPost({
            body: request.body,
            dest: request.dest,
            timeout: request.timeoutTimestamp,
            to: request.to,
            gaslimit: request.gaslimit
        });
        IIsmpDispatcher(_host).dispatch(dispatchPost);
        return commitment;
    }

    function onAccept(PostRequest memory request) public onlyIsmpHost {
        emit PostReceived();
    }

    function onPostResponse(PostResponse memory response) public onlyIsmpHost {
        emit PostResponseReceived();
    }

    function onGetResponse(GetResponse memory response) public onlyIsmpHost {
        emit GetResponseReceived();
    }

    function onGetTimeout(GetRequest memory request) public onlyIsmpHost {
        emit GetTimeoutReceived();
    }

    function onPostTimeout(PostRequest memory request) public onlyIsmpHost {
        emit PostTimeoutReceived();
    }
}
