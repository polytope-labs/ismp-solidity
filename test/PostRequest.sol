// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "../src/beefy/BeefyV1.sol";
import "./TestConsensusClient.sol";
import "../src/EvmHost.sol";
import "./TestHost.sol";
import {MockModule} from "./MockModule.sol";
import "../src/HandlerV1.sol";

interface Hevm {
    // Set block.timestamp (newTimestamp)
    function warp(uint256) external;
}

contract PostRequestTest is Test {
    // needs a test method so that forge can detect it
    function testPost() public {}

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
            defaultTimeout: 5000,
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

    function PostRequestNoChallengeNoTimeout(bytes memory consensusProof, PostRequestMessage memory message) public {
        handler.handleConsensus(host, consensusProof);
        vm.warp(5000);
        handler.handlePostRequests(host, message);
    }
}
