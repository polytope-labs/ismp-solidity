// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "../src/consensus/Beefy.sol";

contract BeefyConsensusClientTest is Test {
    // needs a test method so that forge can detect it
    function testConsensusClient() public {}

    function VerifyV1(BeefyConsensusState memory trustedConsensusState, BeefyConsensusProof memory proof)
        public
        returns (BeefyConsensusState memory, IntermediateState[] memory)
    {
        return BeefyConsensusClient.verifyConsensus(trustedConsensusState, proof);
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
