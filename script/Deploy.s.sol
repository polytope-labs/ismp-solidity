// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/HandlerV1.sol";
import "../src/EvmHost.sol";
import "../test/TestHost.sol";
import "../test/MockModule.sol";
import "../src/modules/CrossChainGovernor.sol";
import "../src/beefy/BeefyV1.sol";

contract DeployScript is Script {
    address public deployer = 0x4e59b44847b379578588920cA78FbF26c0B4956C;
    bytes32 public salt = 0xc023405e9aa0e9ea794732e4076a4f5baca75496cfc2179e94829661ba6396d8;

    function run() external {
        address admin = vm.envAddress("ADMIN");
        uint256 paraId = vm.envUint("PARA_ID");
        bytes32 privateKey = vm.envBytes32("PRIVATE_KEY");
        vm.startBroadcast(uint256(privateKey));

        // consensus client
        BeefyV1 consensusClient = new BeefyV1{salt: salt}(paraId);
        // handler
        HandlerV1 handler = new HandlerV1{salt: salt}();
        // cross-chain governor
        GovernorParams memory gParams = GovernorParams({admin: admin, host: address(0), paraId: paraId});
        CrossChainGovernor governor = new CrossChainGovernor{salt: salt}(gParams);
        // EvmHost
        HostParams memory params = HostParams({
            admin: admin,
            crosschainGovernor: address(governor),
            handler: address(handler),
            // 20 mins
            defaultTimeout: 20 * 60,
            // 21 days
            unStakingPeriod: 21 * (60 * 60 * 24),
            // for this test
            challengePeriod: 0,
            consensusClient: address(consensusClient),
            lastUpdated: 0,
            consensusState: new bytes(0)
        });
        TestHost host = new TestHost{salt: salt}(params);
        // set the ismphost on the cross-chain governor
        governor.setIsmpHost(address(host));
        // deploy the mock module as well
        MockModule m = new MockModule{salt: salt}(address(host));

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
