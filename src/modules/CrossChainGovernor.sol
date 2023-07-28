// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "solidity-merkle-trees/trie/Bytes.sol";

import "../interfaces/IIsmpModule.sol";
import "../interfaces/IIsmpHost.sol";
import "../StateMachine.sol";


contract CrossChainGovernor is IIsmpModule {

    using Bytes for bytes;

    address private _host;
    uint256 private _paraId;

    modifier onlyIsmpHost() {
        require(msg.sender == _host, "CrossChainGovernance: Invalid caller");
        _;
    }

    constructor (address host, uint256 paraId){
        _host = host;
        _paraId = paraId;
    }

    function onAccept(PostRequest memory request) external onlyIsmpHost {
        require(request.source.equals(StateMachine.polkadot(_paraId)), "Unauthorized request");
        (
            address admin,
            address consensus,
            address handler,
            uint256 challengePeriod,
            uint256 unstakingPeriod,
            uint256 defaultTimeout
        ) = abi.decode(request.body, (address, address, address, uint256, uint256, uint256));

        BridgeParams memory params =
            BridgeParams(admin, consensus, handler, challengePeriod, unstakingPeriod, defaultTimeout);

        IIsmpHost(_host).setBridgeParams(params);
    }

    function onPostResponse(PostResponse memory response) external {
        revert("Module doesn't emit requests");
    }

    function onGetResponse(GetResponse memory response) external {
        revert("Module doesn't emit requests");
    }

    function onPostTimeout(PostRequest memory request) external {
        revert("Module doesn't emit requests");
    }

    function onGetTimeout(GetRequest memory request) external {
        revert("Module doesn't emit requests");
    }
}
