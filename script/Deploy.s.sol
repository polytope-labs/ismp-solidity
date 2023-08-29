// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../test/TestConsensusClient.sol";
import "../src/HandlerV1.sol";
import "../src/EvmHost.sol";
import "../test/TestHost.sol";
import "../src/modules/CrossChainGovernor.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address admin = 0x4242424242424242424242424242424242424242;
        uint256 paraId = 2021;

        bytes32 salt = keccak256("hyperbridge");
        console.logBytes32(salt);

        TestConsensusClient consensusClient = new TestConsensusClient{salt: salt}();
        console.logAddress(address(consensusClient));

        HandlerV1 handler = new HandlerV1{salt: salt}();
        console.logAddress(address(handler));

        CrossChainGovernor governor = new CrossChainGovernor{salt: salt}(admin, paraId);
        console.logAddress(address(governor));

        HostParams memory params = HostParams({
            admin: admin,
            crosschainGovernor: address(governor),
            handler: address(handler),
            defaultTimeout: 5000,
            unStakingPeriod: 5000,
        // for this test
            challengePeriod: 0,
            consensusClient: address(consensusClient),
            lastUpdated: 0,
            consensusState: new bytes(0)
        });
        TestHost host = new TestHost{salt: salt}(params);
        console.logAddress(address(host));

        vm.stopBroadcast();
    }
}


