// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {StateCommitment, StateMachineHeight} from "./IConsensusClient.sol";
import {IIsmp, PostRequest, PostResponse, GetResponse, PostTimeout, GetRequest} from "./IIsmp.sol";

// The IsmpHost parameters
struct HostParams {
    // default timeout in seconds for requests.
    uint256 defaultTimeout;
    // timestamp for when the consensus was most recently updated
    uint256 lastUpdated;
    // unstaking period
    uint256 unStakingPeriod;
    // minimum challenge period in seconds;
    uint256 challengePeriod;
    // consensus client contract
    address consensusClient;
    // admin account, this only has the rights to freeze, or unfreeze the bridge
    address admin;
    // Ismp request/response handler
    address handler;
    // the authorized cross-chain governor contract
    address crosschainGovernor;
    // current verified state of the consensus client;
    bytes consensusState;
}

interface IIsmpHost is IIsmp {
    /**
     * @return the host admin
     */
    function admin() external returns (address);

    /**
     * @return the address of the DAI ERC-20 contract on this state machine
     */
    function dai() external returns (address);

    /**
     * @return the host state machine id
     */
    function host() external returns (bytes memory);

    /**
     * @return the host timestamp
     */
    function timestamp() external returns (uint256);

    /**
     * @return the `frozen` status
     */
    function frozen() external returns (bool);

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
    function consensusClient() external returns (address);

    /**
     * @return the last updated time of the consensus client
     */
    function consensusUpdateTime() external returns (uint256);

    /**
     * @return the latest state machine height
     */
    function latestStateMachineHeight() external returns (uint256);

    /**
     * @return the state of the consensus client
     */
    function consensusState() external returns (bytes memory);

    /**
     * @param commitment - commitment to the request
     * @return existence status of an incoming request commitment
     */
    function requestReceipts(bytes32 commitment) external returns (bool);

    /**
     * @param commitment - commitment to the response
     * @return existence status of an incoming response commitment
     */
    function responseReceipts(bytes32 commitment) external returns (bool);

    /**
     * @param commitment - commitment to the request
     * @return existence status of an outgoing request commitment
     */
    function requestCommitments(bytes32 commitment) external returns (bool);

    /**
     * @param commitment - commitment to the response
     * @return existence status of an outgoing response commitment
     */
    function responseCommitments(bytes32 commitment) external returns (bool);

    /**
     * @return the challenge period
     */
    function challengePeriod() external returns (uint256);

    /**
     * @return the unstaking period
     */
    function unStakingPeriod() external returns (uint256);

    /**
     * @dev Store an encoded consensus state
     * @param state new consensus state
     */
    function storeConsensusState(bytes memory state) external;

    /**
     * @dev Updates bridge params
     * @param params new bridge params
     */
    function setHostParams(HostParams memory params) external;

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
    function dispatchIncoming(GetResponse memory response) external;

    /**
     * @dev Dispatch an incoming get timeout to source module
     * @param timeout - get timeout
     */
    function dispatchIncoming(GetRequest memory timeout) external;

    /**
     * @dev Dispatch an incoming post timeout to source module
     * @param timeout - post timeout
     */
    function dispatchIncoming(PostTimeout memory timeout) external;
}
