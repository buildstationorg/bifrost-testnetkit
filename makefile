-include .env

build:
	forge build

test-all:
	forge test -vvvv

deploy-mainnet:
	forge script script/Deploy.s.sol --rpc-url ${BASE_RPC} --account dev --sender ${SENDER} --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY} -vvvv

deploy-testnet:
	forge script script/Deploy.s.sol --rpc-url ${BASE_SEPOLIA_RPC} --account dev --sender ${SENDER} --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY} -vvvv

deploy-all-contracts-on-all-networks:
	forge script script/DeployAllContracts.s.sol --slow --multi --broadcast --account dev --sender ${SENDER} --verify -vvvv

setup-all-contracts-on-all-networks:
	forge script script/SetupAllContracts.s.sol --slow --multi --broadcast --account dev --sender ${SENDER} -vvvv

interact:
	forge script script/Interactions.s.sol --rpc-url ${BASE_SEPOLIA_RPC} --account dev --sender ${SENDER} --broadcast -vvvv

verify-contract:
	forge verify-contract --chain-id ${CHAIN_ID} --num-of-optimizations 200 --watch --constructor-args $(cast abi-encode "constructor(address)" ${OWNER_ADDRESS}) --etherscan-api-key ${ETHERSCAN_API_KEY} --compiler-version v0.8.28+commit.7893614a ${CONTRACT_ADDRESS} src/L2Slpx/L2Slpx.sol:L2Slpx