// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "../src/beefy/BeefyV1.sol";
import "./TestConsensusClient.sol";
import "../src/EvmHost.sol";
import "./TestHost.sol";
import "../src/HandlerV1.sol";

contract PostRequestTest is Test {
    // needs a test method so that forge can detect it
    function testPost() public {}

    IConsensusClient internal consensusClient;
    EvmHost internal host;

    function setUp() public virtual {
        consensusClient = new TestConsensusClient();
        HandlerV1 handler = new HandlerV1();
        HostParams memory params = HostParams({
            admin: address(0),
            crosschainGovernor: address(0),
            handler: handler,
            defaultTimeout: 5000,
            unStakingPeriod: 5000,
            // for this test
            challengePeriod: 0,
            client: consensusClient,
            lastUpdated: 0,
            consensusState: bytes(0)
        });
        host = new TestHost(params);
    }
}
