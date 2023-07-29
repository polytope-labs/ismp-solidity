// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

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
    bytes stateMachineId;
    // height of this state machine
    uint256 height;
}

struct IntermediateState {
    // the state machine identifier
    bytes stateMachineId;
    // height of this state machine
    uint256 height;
    // state commitment
    StateCommitment commitment;
}

// Consensus client contract address and related metadata
struct Consensus {
    // consensus client contract
    address client;
    // current verified state of the consensus client;
    bytes state;
    // timestamp for when the consensus was most recently updated
    uint256 lastUpdated;
    // unstaking period
    uint256 unStakingPeriod;
    // minimum challenge period in seconds;
    uint256 challengePeriod;
}

interface IConsensusClient {
    /// Verify the consensus proof and return the new trusted consensus state and any intermediate states finalized
    /// by this consensus proof.
    function verifyConsensus(bytes memory trustedState, bytes memory proof)
        external
        pure
        returns (bytes memory, IntermediateState[] memory);
}
