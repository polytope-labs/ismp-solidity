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
    address public admin = 0x123463a4B065722E99115D6c222f267d9cABb524;
    uint256 public paraId = 2000;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        BeefyV1 c = new BeefyV1{salt: salt}(paraId);
        address consensusClient = getAddress(type(BeefyV1).creationCode, abi.encode(paraId));
        console.logAddress(consensusClient);
        assert(consensusClient == address(c));

        HandlerV1 hv1 = new HandlerV1{salt: salt}();
        address handler = getAddress(type(HandlerV1).creationCode, new bytes(0));
        console.logAddress(handler);
        assert(handler == address(hv1));

        GovernorParams memory gParams = GovernorParams(admin, address(0), paraId);
        CrossChainGovernor g = new CrossChainGovernor{salt: salt}(gParams);
        address governor = getAddress(type(CrossChainGovernor).creationCode, abi.encode(gParams));
        console.logAddress(governor);
        assert(governor == address(g));

        HostParams memory params = HostParams({
            admin: admin,
            crosschainGovernor: governor,
            handler: handler,
            // 20 mins
            defaultTimeout: 20 * 60,
            // 21 days
            unStakingPeriod: 21 * (60 * 60 * 24),
            // for this test
            challengePeriod: 0,
            consensusClient: consensusClient,
            lastUpdated: 0,
            consensusState: new bytes(0)
        });
        TestHost h = new TestHost{salt: salt}(params);
        address host = getAddress(type(TestHost).creationCode, abi.encode(params));
        console.logAddress(host);
        assert(host == address(h));

        // set the ismphost on the cross-chain governor
        g.setIsmpHost(host);

        // deploy the mock module as well
        MockModule m = new MockModule{salt: salt}(host, paraId);
        address mock = getAddress(type(MockModule).creationCode, abi.encode(host, paraId));
        console.logAddress(mock);
        assert(mock == address(m));

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
