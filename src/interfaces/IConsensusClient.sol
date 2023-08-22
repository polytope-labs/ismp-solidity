// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "solidity-merkle-trees/MerklePatricia.sol";

// The state commiment identifies a commiment to some intermediate state in the state machine.
// This contains some metadata about the state machine like it's own timestamp at the time of this commitment.
struct StateCommitment {
    // This timestamp is useful for handling request timeouts.
    uint256 timestamp;
    // merkle mountain range commitment to all ismp requests & response.
    bytes32 overlayRoot;
    // state root for processing timeouts.
    bytes32 stateRoot;
}

// Identifies some state machine height. We allow for a state machine identifier here
// as some consensus clients may track multiple, concurrent state machines.
struct StateMachineHeight {
    // the state machine identifier
    uint256 stateMachineId;
    // height of this state machine
    uint256 height;
}

struct IntermediateState {
    // the state machine identifier
    uint256 stateMachineId;
    // height of this state machine
    uint256 height;
    // state commitment
    StateCommitment commitment;
}

interface IConsensusClient {
    /// Verify the consensus proof and return the new trusted consensus state and any intermediate states finalized
    /// by this consensus proof.
    function verifyConsensus(bytes memory trustedState, bytes memory proof)
        external
        returns (bytes memory, IntermediateState memory);
}
