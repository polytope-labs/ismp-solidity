source .env.prod
# deploy
forge script script/Deploy.s.sol:DeployScript --rpc-url goerli --broadcast --verify -vvvv --sender=$ADMIN
# verify
forge script script/Deploy.s.sol:DeployScript --rpc-url goerli --resume --verify -vvvv --sender=$ADMIN
