// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "solidity-merkle-trees/MerkleMountainRange.sol";
import "openzeppelin/utils/introspection/IERC165.sol";
import "openzeppelin/utils/Context.sol";
import "openzeppelin/utils/math/Math.sol";

import "./consensus/Schema.sol";
import "./consensus/Beefy.sol";
import "./interfaces/IISMPModule.sol";
import "./interfaces/IIsmpHost.sol";
import "./interfaces/IHandler.sol";

struct HostParams {
    // default timeout in seconds for requests.
    uint256 defaultTimeout;
    // admin account, this only has the rights to freeze, or unfreeze the bridge
    address admin;
    // Ismp request/response handler
    IHandler handler;
    // the authorized cross-chain governor contract
    IIsmpModule crosschainGovernor;
}

/// Ismp implementation for Evm hosts
abstract contract EvmHost is IIsmpHost, Context {
    // commitment of all outgoing requests
    mapping(bytes32 => bool) private _requestCommitments;

    // commitment of all incoming requests
    mapping(bytes32 => bool) private _requestReceipts;

    // commitment of all incoming responses
    mapping(bytes32 => bool) private _responseCommitments;

    // commitment of all outgoing responses
    mapping(bytes32 => bool) private _responseReceipts;

    // (stateMachineId => (blockHeight => StateCommitment))
    mapping(uint256 => mapping(uint256 => StateCommitment)) private _stateCommitments;

    // (stateMachineId => (blockHeight => timestamp))
    mapping(uint256 => mapping(uint256 => uint256)) private _stateCommitmentsUpdateTime;

    // Parameters for the host
    HostParams private _hostParams;

    // consensus client address and metadata,
    Consensus private _consensus;

    // monotonically increasing nonce for outgoing requests
    uint256 private _nonce;

    // emergency shutdown button, only the admin can do this
    bool private _frozen;

    event PostResponseEvent(
        bytes source,
        bytes dest,
        bytes from,
        bytes to,
        uint256 indexed nonce,
        uint256 timeoutTimestamp,
        bytes data,
        // response
        bytes response
    );

    event PostRequestEvent(
        bytes source, bytes dest, bytes from, bytes to, uint256 indexed nonce, uint256 timeoutTimestamp, bytes data
    );

    event GetRequestEvent(bytes source, bytes dest, bytes from, uint256 indexed nonce, uint256 timeoutTimestamp);

    modifier onlyAdmin() {
        require(_msgSender() == _admin, "ISMP_HOST: Only admin");
        _;
    }

    modifier onlyHandler() {
        require(_msgSender() == address(_handler), "ISMP_HOST: Only handler");
        _;
    }

    modifier onlyGovernance() {
        require(_msgSender() == _hostParams.crosschainGovernor, "ISMP_HOST: Only governor contract");
        _;
    }

    constructor(HostParams params, Consensus memory initial) {
        _consensus = initial;
        _bridgeParams = params;
    }

    /**
     * @return the host admin
     */
    function admin() external returns (address) {
        return _hostParams.admin;
    }

    /**
     * @return the host state machine id
     */
    function host() public virtual returns (bytes memory);

    /**
     * @return the host timestamp
     */
    function hostTimestamp() public view returns (uint256) {
        return block.timestamp;
    }

    /**
     * @return the `frozen` status
     */
    function frozen() public view returns (bool) {
        return _frozen;
    }

    /**
     * @param height - state machine height
     * @return the state commitment at `height`
     */
    function stateMachineCommitment(StateMachineHeight memory height) external returns (StateCommitment memory) {
        return _stateCommitments[height.stateMachineId][height.height];
    }

    /**
     * @param height - state machine height
     * @return the state machine update time at `height`
     */
    function stateMachineUpdateTime(StateMachineHeight memory height) external returns (uint256) {
        return _stateCommitmentsUpdateTime[height.stateMachineId][height.height];
    }

    /**
     * @dev Should return a handle to the consensus client based on the id
     * @return the consensus client contract
     */
    function consensusClient() external returns (address) {
        return _consensus.client;
    }

    /**
     * @return the last updated time of the consensus client
     */
    function consensusUpdateTime() external returns (uint256) {
        return _consensus.lastUpdated;
    }

    /**
     * @return the state of the consensus client
     */
    function consensusState() external returns (bytes memory) {
        return _consensus.state;
    }

    /**
     * @param commitment - commitment to the request
     * @return existence status of an incoming request commitment
     */
    function requestReceipts(bytes32 commitment) external returns (bool) {
        return _requestReceipts[commitment];
    }

    /**
     * @param commitment - commitment to the response
     * @return existence status of an incoming response commitment
     */
    function responseReceipts(bytes32 commitment) external returns (bool) {
        return _responseReceipts[commitment];
    }

    /**
     * @param commitment - commitment to the request
     * @return existence status of an outgoing request commitment
     */
    function requestCommitments(bytes32 commitment) external returns (bool) {
        return _requestCommitments[commitment];
    }

    /**
     * @param commitment - commitment to the response
     * @return existence status of an outgoing response commitment
     */
    function responseCommitments(bytes32 commitment) external returns (bool) {
        return _responseCommitments[commitment];
    }

    /**
     * @return the challenge period
     */
    function challengePeriod() external returns (uint256) {
        return _consensus.challengePeriod;
    }

    /**
     * @dev Updates bridge params
     * @param params new bridge params
     */
    function setBridgeParams(BridgeParams memory params) external onlyGovernance {
        _consensus.challengePeriod = params.challengePeriod;
        _consensus.client = params.consensus;
        _consensus.unStakingPeriod = params.unstakingPeriod;

        _hostParams.admin = params.admin;
        _hostParams.defaultTimeout = params.defaultTimeout;
        _hostParams.handler = IHandler(params.handler);
    }

    /**
     * @dev Store an encoded consensus state
     */
    function storeConsensusState(bytes memory state) external onlyHandler {
        _consensus.state = state;
    }

    /**
     * @dev Store the timestamp when the consensus client was updated
     */
    function storeConsensusUpdateTime(uint256 timestamp) external onlyHandler {
        _consensus.lastUpdated = timestamp;
    }

    /**
     * @dev Store the commitment at `state height`
     */
    function storeStateMachineCommitment(StateMachineHeight memory height, StateCommitment memory commitment)
        external
        onlyHandler
    {
        _stateCommitments[height.stateMachineId][height.height] = commitment;
    }

    /**
     * @dev Store the timestamp when the state machine was updated
     */
    function storeStateMachineCommitmentUpdateTime(StateMachineHeight memory height, uint256 timestamp)
        external
        onlyHandler
    {
        _stateCommitmentsUpdateTime[height.stateMachineId][height.height] = timestamp;
    }

    /**
     * @dev set the new state of the bridge
     * @param newState new state
     */
    function setFrozenState(bool newState) public onlyAdmin {
        _frozen = newState;
    }

    /**
     * @return the unstaking period
     */
    function unStakingPeriod() public returns (uint256) {
        return _consensus.unStakingPeriod;
    }

    /**
     * @dev Dispatch an incoming post request to destination module
     * @param request - post request
     */
    function dispatchIncoming(PostRequest memory request) external onlyHandler {
        address destination = _bytesToAddress(request.to);
        require(IERC165(destination).supportsInterface(type(IIsmpModule).interfaceId), "ISMP_HOST: Invalid module");
        IIsmpModule(destination).onAccept(request);

        bytes32 commitment = Message.hash(request);
        _requestReceipts[commitment] = true;
    }

    /**
     * @dev Dispatch an incoming post response to source module
     * @param response - post response
     */
    function dispatchIncoming(PostResponse memory response) external onlyHandler {
        address origin = _bytesToAddress(response.request.from);
        require(IERC165(origin).supportsInterface(type(IIsmpModule).interfaceId), "ISMP_HOST: Invalid module");
        IIsmpModule(origin).onPostResponse(response);

        bytes32 commitment = Message.hash(response);
        _responseReceipts[commitment] = true;
    }

    /**
     * @dev Dispatch an incoming get response to source module
     * @param response - get response
     */
    function dispatchIncoming(GetResponse memory response) external onlyHandler {
        address origin = _bytesToAddress(response.request.from);
        require(IERC165(origin).supportsInterface(type(IIsmpModule).interfaceId), "ISMP_HOST: Invalid module");
        IIsmpModule(origin).onGetResponse(response);

        bytes32 commitment = Message.Hash(response);
        _responseCommitments[commitment] = true;
    }

    /**
     * @dev Dispatch an incoming get timeout to source module
     * @param request - get request
     */
    function dispatchIncoming(GetRequest memory request) external onlyHandler {
        address origin = _bytesToAddress(request.from);
        require(IERC165(origin).supportsInterface(type(IIsmpModule).interfaceId), "ISMP_HOST: Invalid module");
        IIsmpModule(origin).onGetTimeout(request);

        // Delete Commitment
        bytes32 commitment = Message.hash(request);
        delete _responseReceipts[commitment];
    }

    /**
     * @dev Dispatch an incoming post timeout to source module
     * @param timeout - post timeout
     */
    function dispatchIncoming(PostTimeout memory timeout) external onlyHandler {
        PostRequest memory request = timeout.request;
        address origin = _bytesToAddress(request.from);
        require(IERC165(origin).supportsInterface(type(IIsmpModule).interfaceId), "ISMP_HOST: Invalid module");
        IIsmpModule(origin).onPostTimeout(request);

        // Delete Commitment
        bytes32 commitment = Message.hash(request);
        delete _responseReceipts[commitment];
    }

    /**
     * @dev Dispatch a post request to the hyperbridge
     * @param request - post dispatch request
     */
    function dispatch(DispatchPost memory request) external {
        require(IERC165(_msgSender()).supportsInterface(type(IIsmpModule).interfaceId), "Cannot dispatch request");
        uint64 timeout = uint64(Math.max(_DEFAULT_TIMEOUT, request.timeoutTimestamp));
        PostRequest memory _request = PostRequest(
            host(),
            request.destChain,
            uint64(_nextNonce()),
            request.from,
            request.to,
            timeout,
            request.body,
            request.gaslimit
        );
        // make the commitment
        bytes32 commitment = Message.hash(_request);
        _requestCommitments[commitment] = true;

        emit PostRequestEvent(
            _request.source,
            _request.dest,
            _request.from,
            abi.encodePacked(_request.to),
            _request.nonce,
            _request.timeoutTimestamp,
            _request.body
            );
    }

    /**
     * @dev Dispatch a get request to the hyperbridge
     * @param request - get dispatch request
     */
    function dispatch(DispatchGet memory request) external {
        require(IERC165(_msgSender()).supportsInterface(type(IIsmpModule).interfaceId), "Cannot dispatch request");
        uint64 timeout = uint64(Math.max(_DEFAULT_TIMEOUT, request.timeoutTimestamp));
        GetRequest memory _request = GetRequest(
            host(),
            request.destChain,
            uint64(_nextNonce()),
            request.from,
            timeout,
            request.keys,
            request.height,
            request.gaslimit
        );

        // make the commitment
        bytes32 commitment = Message.hash(_request);
        _requestCommitments[commitment] = true;

        emit GetRequestEvent(_request.source, _request.dest, _request.from, _request.nonce, _request.timeoutTimestamp);
    }

    /**
     * @dev Dispatch a response to the hyperbridge
     * @param response - post response
     */
    function dispatch(PostResponse memory response) external {
        require(IERC165(_msgSender()).supportsInterface(type(IIsmpModule).interfaceId), "ISMP_HOST: invalid module");
        bytes32 receipt = Message.hash(response.request);
        require(_requestReceipts[receipt], "ISMP_HOST: unknown request");

        bytes32 commitment = Message.hash(response);
        _responseCommitments[commitment] = true;

        emit PostResponseEvent(
            response.request.source,
            response.request.dest,
            response.request.from,
            abi.encodePacked(response.request.to),
            response.request.nonce,
            response.request.timeoutTimestamp,
            response.request.body,
            response.response
            );
    }

    /**
     * @dev Get next available nonce for outgoing requests.
     */
    function _nextNonce() private returns (uint256) {
        unchecked {
            ++_nonce;
        }

        return _nonce;
    }

    /**
     * @dev Converts bytes to address.
     * @param _bytes bytes value to be converted
     * @return addr returns the address
     */
    function _bytesToAddress(bytes memory _bytes) private pure returns (address addr) {
        require(_bytes.length >= 20, "Invalid address length");
        assembly {
            addr := mload(add(_bytes, 20))
        }
    }
}
