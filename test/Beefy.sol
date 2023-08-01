// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "../src/beefy/BeefyV1.sol";

contract BeefyConsensusClientTest is Test {
    // needs a test method so that forge can detect it
    function testConsensusClient() public {}

    BeefyV1 internal beefy;

    function setUp() public virtual {
        beefy = new BeefyV1();
    }

    function VerifyV1(BeefyConsensusState memory trustedConsensusState, BeefyConsensusProof memory proof)
        public
        returns (BeefyConsensusState memory, IntermediateState[] memory)
    {
        return beefy.verifyConsensus(trustedConsensusState, proof);
    }

    function VerifyV2(bytes memory trustedConsensusState, bytes memory proof)
        public
        returns (bytes memory, IntermediateState[] memory)
    {
        return beefy.verifyConsensus(trustedConsensusState, proof);
    }

    function DecodeHeader(bytes memory encoded) public pure returns (Header memory) {
        return Codec.DecodeHeader(encoded);
    }

    function EncodeLeaf(BeefyMmrLeaf memory leaf) public pure returns (bytes memory) {
        return Codec.Encode(leaf);
    }

    function EncodeCommitment(Commitment memory commitment) public pure returns (bytes memory) {
        return Codec.Encode(commitment);
    }
}
