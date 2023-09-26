// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "forge-std/Test.sol";

import "../src/beefy/BeefyV1.sol";
import "./TestConsensusClient.sol";
import "../src/EvmHost.sol";
import "./TestHost.sol";
import {MockModule} from "./MockModule.sol";
import "../src/HandlerV1.sol";

contract PostTimeoutTest is Test {
    // needs a test method so that forge can detect it
    function testPostTimeout() public {}

    IConsensusClient internal consensusClient;
    EvmHost internal host;
    HandlerV1 internal handler;
    address internal testModule;

    function setUp() public virtual {
        consensusClient = new TestConsensusClient();
        handler = new HandlerV1();

        HostParams memory params = HostParams({
            admin: address(0),
            crosschainGovernor: address(0),
            handler: address(handler),
            defaultTimeout: 0,
            unStakingPeriod: 5000,
            // for this test
            challengePeriod: 0,
            consensusClient: address(consensusClient),
            lastUpdated: 0,
            consensusState: new bytes(0)
        });
        host = new TestHost(params);

        MockModule test = new MockModule(address(host));
        testModule = address(test);
    }

    function module() public view returns (address) {
        return testModule;
    }

    function PostTimeoutNoChallenge(
        bytes memory consensusProof,
        PostRequest memory request,
        PostTimeoutMessage memory message
    ) public {
        MockModule(testModule).dispatch(request);
        handler.handleConsensus(host, consensusProof);
        vm.warp(5000);
        handler.handlePostTimeouts(host, message);
    }
}
