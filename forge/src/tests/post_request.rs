use crate::{
    abi,
    forge::{execute_single, single_runner},
    runner,
};
use ethers::{
    abi::{AbiEncode, Token},
    core::types::U256,
};
use ethers::abi::Tokenizable;
use foundry_evm::Address;
use ismp::{
    host::{Ethereum, StateMachine},
    router::{Post, Request},
};
use ismp_primitives::mmr::{DataOrHash, MmrHasher};
use merkle_mountain_range::util::MemMMR;

type Mmr = MemMMR<DataOrHash<()>, MmrHasher<(), ()>>;

#[tokio::test]
async fn test_post_request_proof() {
    let mut runner = runner();
    let (mut contract, address) = single_runner(&mut runner, "PostRequestTest").await;
    let destination =
        execute_single::<Address, _>(&mut contract, address.clone(), "module", ()).unwrap();

    // create post request object
    let post = Post {
        source: StateMachine::Polkadot(2000),
        dest: StateMachine::Ethereum(Ethereum::ExecutionLayer),
        nonce: 0,
        from: address.as_bytes().to_vec(),
        to: destination.as_bytes().to_vec(),
        timeout_timestamp: 50_000,
        data: vec![],
        gas_limit: 0,
    };
    let request = Request::Post(post.clone());

    // create the mmr tree and insert it

    // create intermediate state
    let height = abi::StateMachineHeight {
        state_machine_id: U256::from(2000),
        height: U256::from(1),
    };
    let consensus_proof = abi::IntermediateState {
        state_machine_id: height.state_machine_id,
        height: height.height,
        commitment: abi::StateCommitment {
            timestamp: U256::from(20000),
            overlay_root: [0u8; 32],
            state_root: [0u8; 32],
        },
    }
    .encode();

    let message = abi::PostRequestMessage {
        proof: abi::Proof {
            height,
            multiproof: vec![],
            mmr_size: Default::default(),
        },
        requests: vec![abi::PostRequestLeaf {
            request: abi::PostRequest {
                source: post.source.to_string().as_bytes().to_vec().into(),
                dest: post.dest.to_string().as_bytes().to_vec().into(),
                nonce: post.nonce,
                from: post.from.into(),
                to: post.to.into(),
                timeout_timestamp: post.timeout_timestamp,
                body: post.data.into(),
                gaslimit: post.gas_limit,
            },
            mmr_index: Default::default(),
            k_index: Default::default(),
        }],
    };

    // execute the test
    execute_single::<(), _>(
        &mut contract,
        address.clone(),
        "PostRequestNoChallengeNoTimeout",
        (Token::Bytes(consensus_proof), message.into_token()),
    )
    .unwrap();
}
