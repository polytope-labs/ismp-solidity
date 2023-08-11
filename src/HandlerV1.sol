// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "solidity-merkle-trees/MerkleMountainRange.sol";
import "solidity-merkle-trees/MerklePatricia.sol";
import "openzeppelin/utils/Context.sol";

import "./interfaces/IConsensusClient.sol";
import "./interfaces/IHandler.sol";
import "./interfaces/IIsmpHost.sol";
import "./interfaces/IIsmpDispatcher.sol";

contract HandlerV1 is IHandler, Context {
    using Bytes for bytes;

    modifier notFrozen(IIsmpHost host) {
        require(!host.frozen(), "IHandler: frozen");
        _;
    }

    /**
     * @dev Handle incoming consensus messages
     * @param host - Ismp host
     * @param proof - consensus proof
     */
    function handleConsensus(IIsmpHost host, bytes memory proof) external notFrozen(host) {
        require(
            (host.timestamp() - host.consensusUpdateTime()) > host.challengePeriod(),
            "IHandler: still in challenge period"
        );

        // not today, time traveling validators
        require(
            (host.timestamp() - host.consensusUpdateTime()) < host.unStakingPeriod() || _msgSender() == host.admin(),
            "IHandler: still in challenge period"
        );

        (bytes memory verifiedState, IntermediateState[] memory intermediates) =
            IConsensusClient(host.consensusClient()).verifyConsensus(host.consensusState(), proof);
        host.storeConsensusState(verifiedState);
        host.storeConsensusUpdateTime(host.timestamp());

        uint256 commitmentsLen = intermediates.length;
        for (uint256 i = 0; i < commitmentsLen; i++) {
            IntermediateState memory intermediate = intermediates[i];
            StateMachineHeight memory stateMachineHeight =
                StateMachineHeight({stateMachineId: intermediate.stateMachineId, height: intermediate.height});
            host.storeStateMachineCommitment(stateMachineHeight, intermediate.commitment);
            host.storeStateMachineCommitmentUpdateTime(stateMachineHeight, host.timestamp());
        }
    }

    /**
     * @dev check request proofs, message delay and timeouts, then dispatch post requests to modules
     * @param host - Ismp host
     * @param request - batch post requests
     */
    function handlePostRequests(IIsmpHost host, PostRequestMessage memory request) external notFrozen(host) {
        uint256 delay = host.timestamp() - host.stateMachineCommitmentUpdateTime(request.proof.height);
        require(delay > host.challengePeriod(), "IHandler: still in challenge period");

        uint256 requestsLen = request.requests.length;
        MmrLeaf[] memory leaves = new MmrLeaf[](requestsLen);

        for (uint256 i = 0; i < requestsLen; i++) {
            PostRequestLeaf memory leaf = request.requests[i];

            require(leaf.request.dest.equals(host.host()), "IHandler: Invalid request destination");
            require(leaf.request.timeoutTimestamp < host.timestamp(), "IHandler: Request timed out");

            bytes32 commitment = Message.hash(leaf.request);
            require(!host.requestReceipts(commitment), "IHandler: Duplicate request");

            uint256 mmrPos = MerkleMountainRange.leafIndexToPos(uint64(leaf.mmrIndex));
            leaves[i] = MmrLeaf(leaf.kIndex, mmrPos, commitment);
        }

        bytes32 root = host.stateMachineCommitment(request.proof.height).overlayRoot;

        require(root != bytes32(0), "IHandler: Proof height not found!");
//                require(
//                    MerkleMountainRange.VerifyProof(root, request.proof.multiproof, leaves, request.proof.mmrSize),
//                    "IHandler: Invalid request proofs"
//                );

        for (uint256 i = 0; i < requestsLen; i++) {
            PostRequestLeaf memory leaf = request.requests[i];
            host.dispatchIncoming(leaf.request);
        }
    }

    /**
     * @dev check response proofs, message delay and timeouts, then dispatch post responses to modules
     * @param host - Ismp host
     * @param response - batch post responses
     */
    function handlePostResponses(IIsmpHost host, PostResponseMessage memory response) external notFrozen(host) {
        uint256 delay = host.timestamp() - host.stateMachineCommitmentUpdateTime(response.proof.height);
        require(delay > host.challengePeriod(), "IHandler: still in challenge period");

        uint256 responsesLength = response.responses.length;
        MmrLeaf[] memory leaves = new MmrLeaf[](responsesLength);

        for (uint256 i = 0; i < responsesLength; i++) {
            PostResponseLeaf memory leaf = response.responses[i];
            require(leaf.response.request.source.equals(host.host()), "IHandler: Invalid response destination");

            bytes32 requestCommitment = Message.hash(leaf.response.request);
            require(host.requestCommitments(requestCommitment), "IHandler: Unknown request");

            bytes32 responseCommitment = Message.hash(leaf.response);
            require(!host.responseCommitments(responseCommitment), "IHandler: Duplicate Post response");

            uint256 mmrPos = MerkleMountainRange.leafIndexToPos(uint64(leaf.mmrIndex));
            leaves[i] = MmrLeaf(leaf.kIndex, mmrPos, responseCommitment);
        }

        bytes32 root = host.stateMachineCommitment(response.proof.height).overlayRoot;

        require(root != bytes32(0), "IHandler: Proof height not found!");
//        require(
//            MerkleMountainRange.VerifyProof(root, response.proof.multiproof, leaves, response.proof.mmrSize),
//            "IHandler: Invalid response proofs"
//        );

        for (uint256 i = 0; i < responsesLength; i++) {
            PostResponseLeaf memory leaf = response.responses[i];
            host.dispatchIncoming(leaf.response);
        }
    }

    /**
     * @dev check response proofs, message delay and timeouts, then dispatch get responses to modules
     * @param host - Ismp host
     * @param message - batch get responses
     */
    function handleGetResponses(IIsmpHost host, GetResponseMessage memory message) external {
        uint256 delay = host.timestamp() - host.stateMachineCommitmentUpdateTime(message.height);
        require(delay > host.challengePeriod(), "IHandler: still in challenge period");

        StateCommitment memory stateCommitment = host.stateMachineCommitment(message.height);
        bytes32 root = stateCommitment.stateRoot;
        require(root != bytes32(0), "IHandler: Proof height not found!");

        uint256 responsesLength = message.requests.length;
        bytes[] memory proof = message.proof;

        for (uint256 i = 0; i < responsesLength; i++) {
            GetRequest memory request = message.requests[i];
            require(request.source.equals(host.host()), "IHandler: Invalid GET response destination");

            bytes32 requestCommitment = Message.hash(request);
            require(host.requestCommitments(requestCommitment), "IHandler: Unknown GET request");
            require(request.timeoutTimestamp < host.timestamp(), "IHandler: GET request timed out");

            StorageValue[] memory values =
                MerklePatricia.ReadChildProofCheck(root, proof, request.keys, bytes.concat(requestCommitment));
            GetResponse memory response = GetResponse({request: request, values: values});
            require(!host.responseCommitments(Message.hash(response)), "IHandler: Duplicate GET response");
            host.dispatchIncoming(response);
        }
    }

    /**
     * @dev check timeout proofs then dispatch to modules
     * @param host - Ismp host
     * @param message - batch post request timeouts
     */
    function handlePostTimeouts(IIsmpHost host, PostTimeoutMessage memory message) external {
        // fetch the state commitment
        StateCommitment memory state = host.stateMachineCommitment(message.height);
        uint256 timeoutsLength = message.timeouts.length;

        for (uint256 i = 0; i < timeoutsLength; i++) {
            PostRequest memory request = message.timeouts[i];
            require(state.timestamp > request.timeoutTimestamp, "Request not timed out");

            bytes32 requestCommitment = Message.hash(request);
            require(host.requestCommitments(requestCommitment), "IHandler: Unknown request");

            bytes[] memory keys = new bytes[](1);
            keys[i] = abi.encodePacked(requestCommitment);

//            StorageValue memory entry = MerklePatricia.VerifySubstrateProof(state.stateRoot, keys, message.proof)[0];
//            require(entry.value.equals(new bytes(0)), "IHandler: Invalid non-membership proof");

            host.dispatchIncoming(PostTimeout(request));
        }
    }

    /**
     * @dev dispatch to modules
     * @param host - Ismp host
     * @param message - batch get request timeouts
     */
    function handleGetTimeouts(IIsmpHost host, GetTimeoutMessage memory message) external {
        uint256 timeoutsLength = message.timeouts.length;

        for (uint256 i = 0; i < timeoutsLength; i++) {
            GetRequest memory request = message.timeouts[i];
            bytes32 requestCommitment = Message.hash(request);
            require(host.requestCommitments(requestCommitment), "IHandler: Unknown request");

            require(host.timestamp() > request.timeoutTimestamp, "IHandler: GET request not timed out");
            host.dispatchIncoming(request);
        }
    }
}
