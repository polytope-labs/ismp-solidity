// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../test/TestConsensusClient.sol";
import "../src/HandlerV1.sol";
import "../src/EvmHost.sol";
import "../test/TestHost.sol";
import "../src/modules/CrossChainGovernor.sol";

contract DeployScript is Script {
    address public deployer = 0x4e59b44847b379578588920cA78FbF26c0B4956C;
    bytes32 public salt = keccak256("hyperbridge");

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address admin = 0x123463a4b065722e99115d6c222f267d9cabb524;
        uint256 paraId = 2021;

        console.logBytes32(salt);

        TestConsensusClient c = new TestConsensusClient{salt: salt}();
        address consensusClient = getAddress(type(TestConsensusClient).creationCode, bytes(""));
        console.logAddress(consensusClient);

        HandlerV1 h = new HandlerV1{salt: salt}();
        address handler = getAddress(type(TestConsensusClient).creationCode, bytes(""));
        console.logAddress(handler);

        GovernorParams memory gParams = GovernorParams(admin, address(0), paraId);
        CrossChainGovernor g = new CrossChainGovernor{salt: salt}(gParams);
        address governor = getAddress(type(CrossChainGovernor).creationCode, abi.encode(gParams));
        console.logAddress(governor);

        HostParams memory params = HostParams({
            admin: admin,
            crosschainGovernor: governor,
            handler: handler,
            defaultTimeout: 5000,
            unStakingPeriod: 5000,
            // for this test
            challengePeriod: 0,
            consensusClient: consensusClient,
            lastUpdated: 0,
            consensusState: new bytes(0)
        });
        TestHost h = new TestHost{salt: salt}(params);
        address host = getAddress(type(TestHost).creationCode, abi.encode(params));
        console.logAddress(host);

        // set the ismphost on the cross-chain governor
        g.setIsmpHost(host);

        vm.stopBroadcast();
    }

    function getAddress(bytes memory code, bytes memory init) public returns (address) {
        return address(
            uint160(
                uint256(
                    keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, keccak256(abi.encodePacked(code, init))))
                )
            )
        );
    }
}
