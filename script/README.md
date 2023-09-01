# How to deploy

Ensure you have a local beacon chain testnet running, see [polytope-labs/eth-pos-devnet](https://github.com/polytope-labs/eth-pos-devnet).

Fill out an `.env` file at the root of this repo with the given contents.

```dotenv
GOERLI_RPC_URL=ws://127.0.0.1:8545
PRIVATE_KEY=2e0834786285daccd064ca17f1654f67b4aef298acbb82cef9ec422fb4975622
ETHERSCAN_API_KEY=
```

The given private key is for the prefunded `0x123463a4B065722E99115D6c222f267d9cABb524` account in the devnet.

Run the command below to deploy

```shell
forge script script/Deploy.s.sol:DeployScript --rpc-url http://127.0.0.1:8545 --broadcast  --sender=0x123463a4b065722e99115d6c222f267d9cabb524
```