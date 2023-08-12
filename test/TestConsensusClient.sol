// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../src/interfaces/IConsensusClient.sol";

/// Test consensus client, performs no verification
contract TestConsensusClient is IConsensusClient {
    function verifyConsensus(bytes memory consensusState, bytes memory proof)
        external
        returns (bytes memory, IntermediateState[] memory)
    {
        IntermediateState memory intermediate = abi.decode(proof, (IntermediateState));
        IntermediateState[] memory intermediates = new IntermediateState[](1);
        intermediates[0] = intermediate;

        return (consensusState, intermediates);
    }
}