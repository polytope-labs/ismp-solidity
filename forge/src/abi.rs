use beefy_primitives::mmr::BeefyNextAuthoritySet;
use beefy_verifier_primitives::{ConsensusMessage, ConsensusState, MmrProof};
use merkle_mountain_range::{leaf_index_to_mmr_size, leaf_index_to_pos, mmr_position_to_k_index};
use primitive_types::H256;

ethers::contract::abigen!(BeefyV1, "../out/abi/BeefyV1.abi",);

impl From<ConsensusMessage> for BeefyConsensusProof {
    fn from(message: ConsensusMessage) -> Self {
        BeefyConsensusProof {
            relay: message.mmr.into(),
            parachain: ParachainProof {
                parachains: message
                    .parachain
                    .parachains
                    .into_iter()
                    .map(|parachain| Parachain {
                        index: parachain.index.into(),
                        id: parachain.para_id.into(),
                        header: parachain.header.into(),
                    })
                    .collect(),
                proof: message
                    .parachain
                    .proof
                    .into_iter()
                    .map(|layer| {
                        layer
                            .into_iter()
                            .map(|(index, node)| Node { k_index: index.into(), node: node.into() })
                            .collect()
                    })
                    .collect(),
            },
        }
    }
}

impl From<MmrProof> for RelayChainProof {
    fn from(value: MmrProof) -> Self {
        let mmr_index = value.mmr_proof.leaf_indices[0];
        let k_index = mmr_position_to_k_index(
            vec![leaf_index_to_pos(mmr_index)],
            leaf_index_to_mmr_size(mmr_index),
        )[0]
        .1;

        RelayChainProof {
            signed_commitment: SignedCommitment {
                commitment: Commitment {
                    payload: vec![Payload {
                        id: b"mh".clone(),
                        data: value
                            .signed_commitment
                            .commitment
                            .payload
                            .get_raw(b"mh")
                            .unwrap()
                            .clone()
                            .into(),
                    }],
                    block_number: value.signed_commitment.commitment.block_number.into(),
                    validator_set_id: value.signed_commitment.commitment.validator_set_id.into(),
                },
                votes: value
                    .signed_commitment
                    .signatures
                    .into_iter()
                    .map(|a| Vote {
                        signature: a.signature.to_vec().into(),
                        authority_index: a.index.into(),
                    })
                    .collect(),
            },
            latest_mmr_leaf: BeefyMmrLeaf {
                version: 0.into(),
                parent_number: value.latest_mmr_leaf.parent_number_and_hash.0.into(),
                parent_hash: value.latest_mmr_leaf.parent_number_and_hash.1.into(),
                next_authority_set: value.latest_mmr_leaf.beefy_next_authority_set.into(),
                extra: value.latest_mmr_leaf.leaf_extra.into(),
                k_index: k_index.into(),
            },
            mmr_proof: value.mmr_proof.items.into_iter().map(Into::into).collect(),
            proof: value
                .authority_proof
                .into_iter()
                .map(|layer| {
                    layer
                        .into_iter()
                        .map(|(index, node)| Node { k_index: index.into(), node: node.into() })
                        .collect()
                })
                .collect(),
        }
    }
}

impl From<BeefyNextAuthoritySet<H256>> for AuthoritySetCommitment {
    fn from(value: BeefyNextAuthoritySet<H256>) -> Self {
        AuthoritySetCommitment {
            id: value.id.into(),
            len: value.len.into(),
            root: value.root.into(),
        }
    }
}

impl From<ConsensusState> for BeefyConsensusState {
    fn from(value: ConsensusState) -> Self {
        BeefyConsensusState {
            latest_height: value.latest_beefy_height.into(),
            beefy_activation_block: Default::default(),
            current_authority_set: value.current_authorities.into(),
            next_authority_set: value.next_authorities.into(),
        }
    }
}

impl From<BeefyConsensusState> for ConsensusState {
    fn from(value: BeefyConsensusState) -> Self {
        ConsensusState {
            latest_beefy_height: value.latest_height.as_u32(),
            mmr_root_hash: Default::default(),
            current_authorities: BeefyNextAuthoritySet {
                id: value.current_authority_set.id.as_u64(),
                len: value.current_authority_set.len.as_u32(),
                root: value.current_authority_set.root.into(),
            },
            next_authorities: BeefyNextAuthoritySet {
                id: value.next_authority_set.id.as_u64(),
                len: value.next_authority_set.len.as_u32(),
                root: value.next_authority_set.root.into(),
            },
        }
    }
}

impl From<IntermediateState> for local::IntermediateState {
    fn from(value: IntermediateState) -> Self {
        local::IntermediateState {
            height: local::StateMachineHeight {
                state_machine_id: value.state_machine_id.as_u32(),
                height: value.height.as_u32(),
            },
            commitment: local::StateCommitment {
                timestamp: value.commitment.timestamp.as_u64(),
                commitment: H256(value.commitment.state_root),
            },
        }
    }
}

pub mod local {
    use primitive_types::H256;

    #[derive(Debug)]
    pub struct StateMachineHeight {
        pub state_machine_id: u32,
        pub height: u32,
    }

    #[derive(Debug)]
    pub struct StateCommitment {
        pub timestamp: u64,
        pub commitment: H256,
    }

    #[derive(Debug)]
    pub struct IntermediateState {
        pub height: StateMachineHeight,
        pub commitment: StateCommitment,
    }
}
