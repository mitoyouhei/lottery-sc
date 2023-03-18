#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
NO_COLOR='\033[0m'

# TODO: reinstall the source

# target networks
declare -a ARRAY_NAME_HERE=(mumbai goerli)
#declare -a ARRAY_NAME_HERE=(ganache)

# deploy script in loop
for network in "${ARRAY_NAME_HERE[@]}"
do
    echo -e "######### ${GREEN} network $network deploy start ${NO_COLOR} #########"
    hardhat run scripts/deploy.js --network $network || exit 1
    echo -e "######### ${GREEN} network $network deploy succeed ${NO_COLOR} #########"
done

echo -e "Deploy contract to ALL network ${GREEN}SUCCEED${NO_COLOR}"
