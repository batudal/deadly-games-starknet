### NOTE: ALL ADDRS FOR GOERLI TESTNET

### setup
export TOKEN_ADDRESS=0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7
export STARKNET_NETWORK=alpha-goerli

### activate env --- this breaks bash script?
conda activate pathfinder

### new account?
export STARKNET_WALLET=starkware.starknet.wallets.open_zeppelin.OpenZeppelinAccount 
starknet deploy_account --account=takezo --network alpha-goerli

### takezo(argent acc)
export TAKEZO=0x01bF3178B7211a85Dc67FAA1ca32429f26cF8bc69083032560Dd51B9fF53Ce10

### deploy all
protostar -p testnet deploy ./build/deadly_games.json --inputs ${TAKEZO} --account takezo
export DEADLY_GAMES_ADDRESS=0x05818b90785b9b1961b2c8eb82047c7e6bf9df0791a6defdba3619f8e46d7ce5

protostar -p testnet deploy ./build/karma.json --inputs 0x4B61726D6120546F6B656E 0x4B41524D41 18 ${DEADLY_GAMES_ADDRESS}
export KARMA_ADDRESS=0x0009a6601ba77e128b7fd6da3d29c36d254136fc0bde4421447056fa0426633e

protostar -p testnet deploy ./build/greed.json --inputs ${DEADLY_GAMES_ADDRESS}
export GREED_ADDRESS=0x05b0dc3a40b9c4aafcadf841ef59e5eee9a1f142b9d24055222156da0f9ed054

protostar -p testnet deploy ./build/greed_mark.json --inputs 0x4772656564204D61726B 0x474D41524B ${GREED_ADDRESS}
export GREED_MARK_ADDRESS=0x02907a0ba0fdcc5c7cb910ded8d13d66658dbeea7086d78a0c476ed2aa907e2a

protostar -p testnet deploy ./build/xoroshiro.json --inputs 42 ${GREED_ADDRESS}
export XOROSHIRO_ADDRESS=0x02916684d6b9555f20931399e50d1cb59ba7e2f8a877865a8fe74a0454acb8f8

### initialization
starknet invoke \
    --network alpha-goerli \
    --address ${GREED_ADDRESS} \
    --abi ./build/greed_abi.json \
    --function set_addresses \
    --inputs ${TOKEN_ADDRESS} ${DEADLY_GAMES_ADDRESS} ${KARMA_ADDRESS} ${XOROSHIRO_ADDRESS} ${GREED_MARK_ADDRESS} \
    --wallet starkware.starknet.wallets.open_zeppelin.OpenZeppelinAccount

starknet invoke \
    --network alpha-goerli \
    --address ${DEADLY_GAMES_ADDRESS} \
    --abi ./build/deadly_games_abi.json \
    --function set_karma_address \
    --inputs ${KARMA_ADDRESS} \
    --wallet starkware.starknet.wallets.open_zeppelin.OpenZeppelinAccount

starknet invoke \
    --network alpha-goerli \
    --address ${DEADLY_GAMES_ADDRESS} \
    --abi ./build/deadly_games_abi.json \
    --function add_game \
    --inputs 0x4772656564 0x74616B657A305F6F ${GREED_ADDRESS} \
    --wallet starkware.starknet.wallets.open_zeppelin.OpenZeppelinAccount

starknet invoke \
    --network alpha-goerli \
    --address ${DEADLY_GAMES_ADDRESS} \
    --abi ./build/deadly_games_abi.json \
    --function activate_game \
    --inputs 1 \
    --wallet starkware.starknet.wallets.open_zeppelin.OpenZeppelinAccount

starknet invoke \
    --network alpha-goerli \
    --address ${GREED_ADDRESS} \
    --abi ./build/greed_abi.json \
    --function greed \
    --inputs 1 \
    --wallet starkware.starknet.wallets.open_zeppelin.OpenZeppelinAccount \
    --account takezo