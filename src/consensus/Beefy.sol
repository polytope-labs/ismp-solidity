// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

//import "../ISMP.sol";
import "./Codec.sol";
import "./Schema.sol";

import "solidity-merkle-trees/MerkleMultiProof.sol";
import "solidity-merkle-trees/MerkleMountainRange.sol";
import "solidity-merkle-trees/MerklePatricia.sol";
import "solidity-merkle-trees/trie/substrate/ScaleCodec.sol";
import "solidity-merkle-trees/trie/Bytes.sol";
import "openzeppelin/utils/cryptography/ECDSA.sol";
import "openzeppelin/utils/cryptography/MerkleProof.sol";
import "openzeppelin/utils/Strings.sol";
import "../interfaces/IConsensusClient.sol";

struct ConsensusMessage {
    BeefyConsensusProof proof;
}

library BeefyConsensusClient {
    /// Slot duration in milliseconds
    uint256 public constant SLOT_DURATION = 12000;
    /// The PayloadId for the mmr root.
    bytes2 public constant MMR_ROOT_PAYLOAD_ID = bytes2("mh");
    /// ChainId for ethereum
    bytes4 public constant ISMP_CONSENSUS_ID = bytes4("ISMP");
    /// ConsensusID for aura
    bytes4 public constant AURA_CONSENSUS_ID = bytes4("aura");

    /// Verify the consensus proof and return the new trusted consensus state and any intermediate states finalized
    /// by this consensus proof.
    function verifyConsensus(BeefyConsensusState memory trustedState, BeefyConsensusProof memory proof)
        internal
        pure
        returns (BeefyConsensusState memory, IntermediateState[] memory)
    {
        require(trustedState.frozenHeight == 0, "Consensus client is frozen");

        // verify mmr root proofs
        trustedState = verifyMmrUpdateProof(trustedState, proof.relay);

        // verify intermediate state commitment proofs
        IntermediateState[] memory intermediate = verifyParachainHeaderProof(trustedState, proof.parachain);

        return (trustedState, intermediate);
    }

    /// Verifies a new Mmmr root update, the relay chain accumulates its blocks into a merkle mountain range tree
    /// which light clients can use as a source for log_2(n) ancestry proofs. This new mmr root hash is signed by
    /// the relay chain authority set and we can verify the membership of the authorities who signed this new root
    /// using a merkle multi proof and a merkle commitment to the total authorities.
    function verifyMmrUpdateProof(BeefyConsensusState memory trustedState, RelayChainProof memory relayProof)
        internal
        pure
        returns (BeefyConsensusState memory)
    {
        uint256 signatures_length = relayProof.signedCommitment.votes.length;
        uint256 latestHeight = relayProof.signedCommitment.commitment.blockNumber;

        require(latestHeight > trustedState.latestHeight, "consensus clients only accept proofs for new headers");
        require(
            checkParticipationThreshold(signatures_length, trustedState.currentAuthoritySet.len)
                || checkParticipationThreshold(signatures_length, trustedState.nextAuthoritySet.len),
            "Super majority threshold not reached"
        );

        Commitment memory commitment = relayProof.signedCommitment.commitment;

        require(
            commitment.validatorSetId == trustedState.currentAuthoritySet.id
                || commitment.validatorSetId == trustedState.nextAuthoritySet.id,
            "Unknown authority set"
        );

        bool is_current_authorities = commitment.validatorSetId == trustedState.currentAuthoritySet.id;

        uint256 payload_len = commitment.payload.length;
        bytes32 mmrRoot;

        for (uint256 i = 0; i < payload_len; i++) {
            if (commitment.payload[i].id == MMR_ROOT_PAYLOAD_ID && commitment.payload[i].data.length == 32) {
                mmrRoot = Bytes.toBytes32(commitment.payload[i].data);
            }
        }

        require(mmrRoot != bytes32(0), "Mmr root hash not found");

        bytes32 commitment_hash = keccak256(Codec.Encode(commitment));
        Node[] memory authorities = new Node[](signatures_length);

        // verify authorities' votes
        for (uint256 i = 0; i < signatures_length; i++) {
            Vote memory vote = relayProof.signedCommitment.votes[i];
            address authority = ECDSA.recover(commitment_hash, vote.signature);
            authorities[i] = Node(vote.authorityIndex, keccak256(abi.encodePacked(authority)));
        }

        // check authorities proof
        if (is_current_authorities) {
            require(
                relayProof.proof.length == MerkleMultiProof.TreeHeight(trustedState.currentAuthoritySet.len),
                "Invalid current authorities proof height"
            );
            require(
                MerkleMultiProof.VerifyProofSorted(trustedState.currentAuthoritySet.root, relayProof.proof, authorities),
                "Invalid current authorities proof"
            );
        } else {
            require(
                relayProof.proof.length == MerkleMultiProof.TreeHeight(trustedState.nextAuthoritySet.len),
                "Invalid next authorities proof height"
            );
            require(
                MerkleMultiProof.VerifyProofSorted(trustedState.nextAuthoritySet.root, relayProof.proof, authorities),
                "Invalid next authorities proof"
            );
        }

        verifyMmrLeaf(trustedState, relayProof, mmrRoot);

        if (!is_current_authorities || trustedState.nextAuthoritySet.id != relayProof.latestMmrLeaf.nextAuthoritySet.id)
        {
            trustedState.currentAuthoritySet = trustedState.nextAuthoritySet;
            trustedState.nextAuthoritySet = relayProof.latestMmrLeaf.nextAuthoritySet;
        }

        trustedState.latestHeight = latestHeight;
        trustedState.latestHeadsRoot = relayProof.latestMmrLeaf.extra;

        return trustedState;
    }

    /// Stack too deep, sigh solidity
    function verifyMmrLeaf(BeefyConsensusState memory trustedState, RelayChainProof memory relay, bytes32 mmrRoot)
        internal
        pure
    {
        bytes32 leafHash = keccak256(Codec.Encode(relay.latestMmrLeaf));
        uint256 leafIndex = leafIndex(trustedState.beefyActivationBlock, relay.latestMmrLeaf.parentNumber);
        uint256 mmrSize = MerkleMountainRange.leafIndexToMmrSize(uint64(leafIndex));
        uint256 leafPos = MerkleMountainRange.leafIndexToPos(uint64(leafIndex));

        MmrLeaf[] memory leaves = new MmrLeaf[](1);
        leaves[0] = MmrLeaf(relay.latestMmrLeaf.kIndex, leafPos, leafHash);

        require(MerkleMountainRange.VerifyProof(mmrRoot, relay.mmrProof, leaves, mmrSize), "Invalid Mmr Proof");
    }

    /// Verifies that some parachain header has been finalized, given the current trusted consensus state.
    function verifyParachainHeaderProof(BeefyConsensusState memory trustedState, ParachainProof memory proof)
        internal
        pure
        returns (IntermediateState[] memory)
    {
        uint256 headerLen = proof.parachains.length;
        IntermediateState[] memory intermediates = new IntermediateState[](headerLen);
        Node[] memory leaves = new Node[](headerLen);

        for (uint256 i = 0; i < headerLen; i++) {
            Parachain memory para = proof.parachains[i];
            Header memory header = Codec.DecodeHeader(para.header);
            require(header.number != 0, "Genesis block should not be included");
            // extract verified metadata from header
            bytes32 commitment;
            uint256 timestamp;
            for (uint256 j = 0; j < header.digests.length; j++) {
                if (header.digests[j].isConsensus && header.digests[j].consensus.consensusId == ISMP_CONSENSUS_ID) {
                    commitment = Bytes.toBytes32(header.digests[j].consensus.data);
                }

                if (header.digests[j].isPreRuntime && header.digests[j].preruntime.consensusId == AURA_CONSENSUS_ID) {
                    uint256 slot = ScaleCodec.decodeUint256(header.digests[j].preruntime.data);
                    timestamp = slot * SLOT_DURATION;
                }
            }
            // require(commitment != bytes32(0), "Request commitment not found!");
            require(timestamp != 0, "Request commitment not found!");

            leaves[i] = Node(
                para.index,
                keccak256(bytes.concat(ScaleCodec.encode32(uint32(para.id)), ScaleCodec.encodeBytes(para.header)))
            );

            intermediates[i] =
                IntermediateState(para.id, header.number, StateCommitment(timestamp, commitment, header.stateRoot));
        }

        require(
            MerkleMultiProof.VerifyProofSorted(trustedState.latestHeadsRoot, proof.proof, leaves),
            "Invalid parachains heads proof"
        );

        return intermediates;
    }

    /// Calculates the mmr leaf index for a block whose parent number is given.
    function leafIndex(uint256 activationBlock, uint256 parentNumber) internal pure returns (uint256) {
        if (activationBlock == 0) {
            return parentNumber;
        } else {
            return activationBlock - (parentNumber + 2);
        }
    }

    /// Check for supermajority participation.
    function checkParticipationThreshold(uint256 len, uint256 total) internal pure returns (bool) {
        return len >= ((2 * total) / 3) + 1;
    }
}
