// SPDX-License-Identifier: UNLICENSED
// A Sample ISMP solidity contract for unit tests

pragma solidity 0.8.17;

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

    function dispatch(PostRequest memory request) public returns (bytes32) {
        bytes32 commitment = Message.hash(request);
        DispatchPost memory post = DispatchPost({
            body: request.body,
            dest: request.dest,
            timeout: request.timeoutTimestamp,
            to: request.to,
            gaslimit: request.gaslimit
        });
        IIsmpDispatcher(_host).dispatch(post);
        return commitment;
    }

    function dispatch(GetRequest memory request) public returns (bytes32) {
        bytes32 commitment = Message.hash(request);
        DispatchGet memory get = DispatchGet({
            dest: request.dest,
            height: request.height,
            keys: request.keys,
            timeout: request.timeoutTimestamp,
            gaslimit: request.gaslimit
        });
        IIsmpDispatcher(_host).dispatch(get);
        return commitment;
    }

    function onAccept(PostRequest memory request) public onlyIsmpHost {
        emit PostReceived();
    }

    function onPostResponse(PostResponse memory response) public onlyIsmpHost {
        emit PostResponseReceived();
    }

    function onGetResponse(GetResponse memory response) public onlyIsmpHost {
        //        console.log("key: ");
        //        console.logBytes(response.values[0].key);
        //        console.log("value: ");
        //        console.logBytes(response.values[0].value);
        emit GetResponseReceived();
    }

    function onGetTimeout(GetRequest memory request) public onlyIsmpHost {
        emit GetTimeoutReceived();
    }

    function onPostTimeout(PostRequest memory request) public onlyIsmpHost {
        emit PostTimeoutReceived();
    }
}
