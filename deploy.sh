#!/bin/bash
echo '====================== Contract Deploy ======================'
echo ''

# allow deploy mode
accept_mode=(dev "test" online)

# deploy contract network
declare -A accept_network=(["dev"]="" ["test"]="testnet" ["online"]="main")

mode=$1
# check mode
[[ -z "${mode}" ]] && echo "You must specify one of the following development modes: dev, test, online" && exit 1
[[ ! "${accept_mode[*]}" =~ ${mode} ]] && echo "Development mode not allowed: ${mode}" && exit 1

echo 'Get local ip address'
ip=$(ip addr | awk '/^[0-9]+: / {}; /inet.*global.*eth/ {print gensub(/(.*)\/(.*)/, "\\1", "g", $2)}')

# check ip address
[[ -z "${ip}" ]] && echo "Undefined local ip address" && exit 1

echo "Write ip: ${ip} to env file"
cp -R .env-source .env
echo -e "\nAPI_HOST=http://${ip}:6912" >>.env

echo 'Install npm package'
npm install

network=${accept_network[${mode}]}

if [[ -n "${network}" ]]; then
    echo "Deploying contract to network: ${network}"
    npx hardhat run scripts/deploy.js --network "${network}"
else
    echo "Deploying contract to network: localhost"
    npx hardhat run scripts/deploy.js
fi

echo ''
echo '====================== Deploy Success ======================'
exit 0
