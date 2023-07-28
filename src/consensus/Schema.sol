// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Schema.sol";
import "solidity-merkle-trees/MerkleMultiProof.sol";

struct BeefyConsensusState {
    /// block number for the latest mmr_root_hash
    uint256 latestHeight;
    /// timestamp for the latest height
    uint256 latestTimestamp;
    /// Block height when the client was frozen due to a byzantine attack
    uint256 frozenHeight;
    /// Parachain heads root.
    bytes32 latestHeadsRoot;
    /// Block number that the beefy protocol was activated on the relay chain.
    /// This should be the first block in the merkle-mountain-range tree.
    uint256 beefyActivationBlock;
    /// authorities for the current round
    AuthoritySetCommitment currentAuthoritySet;
    /// authorities for the next round
    AuthoritySetCommitment nextAuthoritySet;
}

struct AuthoritySetCommitment {
    /// Id of the set.
    uint256 id;
    /// Number of validators in the set.
    uint256 len;
    /// Merkle Root Hash built from BEEFY AuthorityIds.
    bytes32 root;
}

struct Payload {
    bytes2 id;
    bytes data;
}

struct Commitment {
    Payload[] payload;
    uint256 blockNumber;
    uint256 validatorSetId;
}

struct Vote {
    bytes signature;
    uint256 authorityIndex;
}

struct SignedCommitment {
    Commitment commitment;
    Vote[] votes;
}

struct BeefyMmrLeaf {
    uint256 version;
    uint256 parentNumber;
    bytes32 parentHash;
    AuthoritySetCommitment nextAuthoritySet;
    bytes32 extra;
    uint256 kIndex;
}

struct PartialBeefyMmrLeaf {
    uint256 version;
    uint256 parentNumber;
    bytes32 parentHash;
    AuthoritySetCommitment nextAuthoritySet;
}

struct RelayChainProof {
    /// Signed commitment
    SignedCommitment signedCommitment;
    /// Latest leaf added to mmr
    BeefyMmrLeaf latestMmrLeaf;
    /// Proof for the latest mmr leaf
    bytes32[] mmrProof;
    /// Proof for authorities in current/next session
    Node[][] proof;
}

struct Parachain {
    /// k-index for latestHeadsRoot
    uint256 index;
    /// Parachain Id
    uint256 id;
    /// SCALE encoded header
    bytes header;
}

struct ParachainProof {
    Parachain[] parachains;
    Node[][] proof;
}

struct BeefyConsensusProof {
    RelayChainProof relay;
    ParachainProof parachain;
}

struct DigestItem {
    bytes4 consensusId;
    bytes data;
}

struct Digest {
    bool isPreRuntime;
    DigestItem preruntime;
    bool isConsensus;
    DigestItem consensus;
    bool isSeal;
    DigestItem seal;
    bool isOther;
    bytes other;
    bool isRuntimeEnvironmentUpdated;
}

struct Header {
    bytes32 parentHash;
    uint256 number;
    bytes32 stateRoot;
    bytes32 extrinsicRoot;
    Digest[] digests;
}
