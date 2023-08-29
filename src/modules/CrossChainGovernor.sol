// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "solidity-merkle-trees/trie/Bytes.sol";

import "../interfaces/IIsmpModule.sol";
import "../interfaces/IIsmpHost.sol";
import "../interfaces/StateMachine.sol";

contract CrossChainGovernor is IIsmpModule {
    using Bytes for bytes;

    address private _admin;
    address private _host;
    uint256 private _paraId;

    modifier onlyIsmpHost() {
        require(msg.sender == _host, "CrossChainGovernor: Invalid caller");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == _host, "CrossChainGovernor: Invalid caller");
        _;
    }

    constructor(address admin, uint256 paraId) {
        _admin = admin;
        _paraId = paraId;
    }

    // This function can only be called once by the admin to set the IsmpHost.
    // This exists to seal the cyclic dependency between this contract & the ismp host.
    function setIsmpHost(address host) public onlyAdmin {
        _host = host;
        _admin = address(0);
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

    function onPostResponse(PostResponse memory response) external pure {
        revert("Module doesn't emit requests");
    }

    function onGetResponse(GetResponse memory response) external pure {
        revert("Module doesn't emit requests");
    }

    function onPostTimeout(PostRequest memory request) external pure {
        revert("Module doesn't emit requests");
    }

    function onGetTimeout(GetRequest memory request) external pure {
        revert("Module doesn't emit requests");
    }
}
