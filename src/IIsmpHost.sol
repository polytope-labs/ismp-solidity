// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {StateCommitment, StateMachineHeight} from "./IConsensusClient.sol";
import {IDispatcher} from "./IDispatcher.sol";
import {PostRequest, PostResponse, GetResponse, PostTimeout, GetRequest} from "./Message.sol";

// Some metadata about the request
struct FeeMetadata {
    // the relayer fee
    uint256 fee;
    // user who initiated the request
    address sender;
}

struct ResponseReceipt {
    // commitment of the response object
    bytes32 responseCommitment;
    // address of the relayer responsible for this response delivery
    address relayer;
}

interface IIsmpHost is IDispatcher {
    /**
     * @return the host admin
     */
    function admin() external returns (address);

    /**
     * @return the address of the DAI ERC-20 contract on this state machine
     */
    function dai() external view returns (address);

    /**
     * @return the per-byte fee for outgoing requests.
     */
    function perByteFee() external view returns (uint256);

    /**
     * @return the host state machine id
     */
    function host() external view returns (bytes memory);

    /**
     * @return the host timestamp
     */
    function timestamp() external view returns (uint256);

    /**
     * @return the `frozen` status
     */
    function frozen() external view returns (bool);

    /**
     * @param height - state machine height
     * @return the state commitment at `height`
     */
    function stateMachineCommitment(StateMachineHeight memory height) external returns (StateCommitment memory);

    /**
     * @param height - state machine height
     * @return the state machine commitment update time at `height`
     */
    function stateMachineCommitmentUpdateTime(StateMachineHeight memory height) external returns (uint256);

    /**
     * @dev Should return a handle to the consensus client based on the id
     * @return the consensus client contract
     */
    function consensusClient() external view returns (address);

    /**
     * @return the last updated time of the consensus client
     */
    function consensusUpdateTime() external view returns (uint256);

    /**
     * @return the latest state machine height
     */
    function latestStateMachineHeight() external view returns (uint256);

    /**
     * @return the state of the consensus client
     */
    function consensusState() external view returns (bytes memory);

    /**
     * @param commitment - commitment to the request
     * @return relayer address
     */
    function requestReceipts(bytes32 commitment) external view returns (address);

    /**
     * @param commitment - commitment to the request of the response
     * @return response receipt
     */
    function responseReceipts(bytes32 commitment) external view returns (ResponseReceipt memory);

    /**
     * @param commitment - commitment to the request
     * @return existence status of an outgoing request commitment
     */
    function requestCommitments(bytes32 commitment) external view returns (FeeMetadata memory);

    /**
     * @param commitment - commitment to the response
     * @return existence status of an outgoing response commitment
     */
    function responseCommitments(bytes32 commitment) external view returns (FeeMetadata memory);

    /**
     * @return the challenge period
     */
    function challengePeriod() external view returns (uint256);

    /**
     * @return the unstaking period
     */
    function unStakingPeriod() external view returns (uint256);

    /**
     * @dev Store an encoded consensus state
     * @param state new consensus state
     */
    function storeConsensusState(bytes memory state) external;

    /**
     * @dev Store the timestamp when the consensus client was updated
     * @param timestamp - new timestamp
     */
    function storeConsensusUpdateTime(uint256 timestamp) external;

    /**
     * @dev Store the latest state machine height
     * @param height State Machine Height
     */
    function storeLatestStateMachineHeight(uint256 height) external;

    /**
     * @dev Store the commitment at `state height`
     * @param height state machine height
     * @param commitment state commitment
     */
    function storeStateMachineCommitment(StateMachineHeight memory height, StateCommitment memory commitment)
        external;

    /**
     * @dev Store the timestamp when the state machine was updated
     * @param height state machine height
     * @param timestamp new timestamp
     */
    function storeStateMachineCommitmentUpdateTime(StateMachineHeight memory height, uint256 timestamp) external;

    /**
     * @dev Dispatch an incoming request to destination module
     * @param request - post request
     */
    function dispatchIncoming(PostRequest memory request) external;

    /**
     * @dev Dispatch an incoming post response to source module
     * @param response - post response
     */
    function dispatchIncoming(PostResponse memory response) external;

    /**
     * @dev Dispatch an incoming get response to source module
     * @param response - get response
     */
    function dispatchIncoming(GetResponse memory response, FeeMetadata memory meta) external;

    /**
     * @dev Dispatch an incoming get timeout to source module
     * @param timeout - timed-out get request
     */
    function dispatchIncoming(GetRequest memory timeout, FeeMetadata memory meta, bytes32 commitment) external;

    /**
     * @dev Dispatch an incoming post timeout to source module
     * @param timeout - timed-out post request
     */
    function dispatchIncoming(PostRequest memory timeout, FeeMetadata memory meta, bytes32 commitment) external;

    /**
     * @dev Dispatch an incoming post response timeout to source module
     * @param timeout - timed-out post response
     */
    function dispatchIncoming(PostResponse memory timeout, FeeMetadata memory meta, bytes32 commitment) external;
}
