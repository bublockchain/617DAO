#!/bin/bash

# Deploy contracts
source .env
echo "Deploying contracts..."

# Check for ETHERSCAN_API_KEY
if [ -z "$ETHERSCAN_API_KEY" ]; then
    echo "ETHERSCAN_API_KEY not found in environment."
    read -p "Please enter your Etherscan API key: " ETHERSCAN_API_KEY
    export ETHERSCAN_API_KEY
fi

# Fetch chain ID from RPC URL
CHAIN_ID=$(curl -s -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' $RPC_URL | jq -r '.result')
CHAIN_ID_DEC=$((16#${CHAIN_ID#0x}))
echo "Detected Chain ID: $CHAIN_ID_DEC"

forge script script/Deploy.s.sol:Deploy --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast 

# Check if the deployment was successful
if [ $? -ne 0 ]; then
    echo "Transaction failed. User may not have enough funds."
    exit 1
fi

# Extract contract addresses from the latest run JSON file
LATEST_RUN_FILE=$(ls -t broadcast/Deploy.s.sol/$CHAIN_ID_DEC/run-*.json | head -n 1)
DAO_ADDRESS=$(jq -r '.transactions[0].contractAddress' "$LATEST_RUN_FILE")
FAUCET_ADDRESS=$(jq -r '.transactions[1].contractAddress' "$LATEST_RUN_FILE")

# Verify contracts
echo "Verifying contracts..."
forge verify-contract $DAO_ADDRESS DAO --chain-id $CHAIN_ID_DEC 
forge verify-contract $FAUCET_ADDRESS Faucet --chain-id $CHAIN_ID_DEC 

# Update contractConfig.ts
echo "Updating contractConfig.ts..."
cat > client/src/contractConfig.ts << EOL
export const contractAddresses = {
  DAO: '$DAO_ADDRESS',
  Faucet: '$FAUCET_ADDRESS',
};
EOL

echo "Deployment and update complete!"
echo "DAO address: $DAO_ADDRESS"
echo "Faucet address: $FAUCET_ADDRESS"