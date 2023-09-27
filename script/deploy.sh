if [ "$1" = "local" ]; then
    echo "Deploying locally"
    # load local .env
    source .env
    # deploy
    forge script script/Deploy.s.sol:DeployScript --rpc-url "$GOERLI_RPC_URL" --broadcast -vvvv --sender="$ADMIN"
else
    echo "Deploying to $1"
    # load prod .env
    source .env.prod
    # deploy
    forge script script/Deploy.s.sol:DeployScript --rpc-url "$1" --broadcast -vvvv --sender="$ADMIN"
    # verify
    forge script script/Deploy.s.sol:DeployScript --rpc-url "$1" --resume --verify -vvvv --sender="$ADMIN"
fi