// SPDX-License-Identifier: UNLICENSED
// A Sample ISMP solidity contract for unit tests

pragma solidity 0.8.17;

import "../src/interfaces/IIsmpModule.sol";
import "../src/interfaces/StateMachine.sol";

contract MockModule is IIsmpModule {
    event PostResponseReceived();
    event GetResponseReceived();
    event PostTimeoutReceived();
    event GetTimeoutReceived();
    event PostReceived(string message);
    event MessageDispatched();

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
    uint256 internal _paraId;

    constructor(address host, uint256 paraId) {
        _host = host;
        _paraId = paraId;
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

    function dispatchToParachain() public {
        DispatchPost memory post = DispatchPost({
            body: bytes("hello from ethereum"),
            dest: StateMachine.polkadot(_paraId),
            timeout: 60 * 60, // one hour
            to: bytes("ismp-ast"), // ismp demo pallet
            gaslimit: 0 // unnedeed, since it's a pallet
        });
        IIsmpDispatcher(_host).dispatch(post);
    }

    function onAccept(PostRequest memory request) external onlyIsmpHost {
        emit PostReceived(string(request.body));
    }

    function onPostResponse(PostResponse memory response) external onlyIsmpHost {
        emit PostResponseReceived();
    }

    function onGetResponse(GetResponse memory response) external onlyIsmpHost {
        emit GetResponseReceived();
    }

    function onGetTimeout(GetRequest memory request) external onlyIsmpHost {
        emit GetTimeoutReceived();
    }

    function onPostTimeout(PostRequest memory request) external onlyIsmpHost {
        emit PostTimeoutReceived();
    }
}
