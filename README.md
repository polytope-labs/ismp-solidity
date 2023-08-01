# ismp-solidity

[ISMP](https://github.com/polytope-labs/ismp) implementation for both Substrate & EVM hosts.

## Interface

 - [`IConsensusClient`](./src/interfaces/IConsensusClient.sol)
   - [`BeefyV1`](./src/beefy/BeefyV1.sol)
 - [`IHandler`](./src/interfaces/IHandler.sol)
   - [`HandlerV1`](./src/HandlerV1.sol)
 - [`IIsmpDispatcher`](./src/interfaces/IIsmpDispatcher.sol)
     - [`SubstrateDispatcher`](src/SubstrateDispatcher.sol)
 - [`IIsmpHost`](./src/interfaces/IIsmpHost.sol)
   - [`EvmHost`](./src/EvmHost.sol)
 - [`IIsmpModule`](./src/interfaces/IIsmpModule.sol)
   - [`CrossChainGovernor`](./src/modules/CrossChainGovernor.sol)

## `SubstrateDispatcher`

This provides the interface that EVM contracts living on substrate chains can use to dispatch requests & responses over ISMP. This requires the `pallet-ismp` present in the runtime and the necessary precompiles from the `ismp-evm` module configured.

## `EvmHost`

The `EvmHost` contract is the core implementation of ISMP for native EVM environments. This contract will live across EVM chains allowing local contracts to interop over the ISMP network.

## License

This library is licensed under the Apache 2.0 License, Copyright (c) 2023 Polytope Labs.
