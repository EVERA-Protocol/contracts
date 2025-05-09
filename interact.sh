#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
RPC_URL="http://localhost:8545"
PRIVATE_KEY=""
BROADCAST=false
ACTION="query"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --rpc-url)
      RPC_URL="$2"
      shift 2
      ;;
    --private-key)
      PRIVATE_KEY="$2"
      shift 2
      ;;
    --broadcast)
      BROADCAST=true
      shift
      ;;
    --network)
      case "$2" in
        local)
          RPC_URL="http://localhost:8545"
          ;;
        sepolia)
          RPC_URL="https://sepolia.infura.io/v3/${INFURA_API_KEY}"
          ;;
        goerli)
          RPC_URL="https://goerli.infura.io/v3/${INFURA_API_KEY}"
          ;;
        mainnet)
          RPC_URL="https://mainnet.infura.io/v3/${INFURA_API_KEY}"
          ;;
        polygon)
          RPC_URL="https://polygon-mainnet.infura.io/v3/${INFURA_API_KEY}"
          ;;
        mumbai)
          RPC_URL="https://polygon-mumbai.infura.io/v3/${INFURA_API_KEY}"
          ;;
        *)
          echo "Unknown network: $2"
          exit 1
          ;;
      esac
      shift 2
      ;;
    --action)
      ACTION="$2"
      shift 2
      ;;
    --token-name)
      export TOKEN_NAME="$2"
      shift 2
      ;;
    --token-symbol)
      export TOKEN_SYMBOL="$2"
      shift 2
      ;;
    --institution-name)
      export INSTITUTION_NAME="$2"
      shift 2
      ;;
    --institution-address)
      export INSTITUTION_ADDRESS="$2"
      shift 2
      ;;
    --document-uri)
      export DOCUMENT_URI="$2"
      shift 2
      ;;
    --image-uri)
      export IMAGE_URI="$2"
      shift 2
      ;;
    --total-supply)
      export TOTAL_SUPPLY="$2"
      shift 2
      ;;
    --price)
      export PRICE="$2"
      shift 2
      ;;
    --description)
      export DESCRIPTION="$2"
      shift 2
      ;;
    --require-kyc)
      export REQUIRE_KYC="$2"
      shift 2
      ;;
    --user-address)
      export USER_ADDRESS="$2"
      shift 2
      ;;
    --new-price)
      export NEW_PRICE="$2"
      shift 2
      ;;
    --help)
      echo "Usage: ./interact.sh [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --rpc-url URL              RPC URL to use (default: http://localhost:8545)"
      echo "  --private-key KEY          Private key to use for transactions"
      echo "  --broadcast                Broadcast transactions to the network"
      echo "  --network NETWORK          Use predefined network (local, sepolia, goerli, mainnet, polygon, mumbai)"
      echo "  --action ACTION            Action to perform (query, create-token, approve-kyc, update-price, pause, unpause)"
      echo ""
      echo "For create-token action:"
      echo "  --token-name NAME          Name of the token"
      echo "  --token-symbol SYMBOL      Symbol of the token"
      echo "  --institution-name NAME    Name of the institution"
      echo "  --institution-address ADDR Address of the institution"
      echo "  --document-uri URI         Document URI"
      echo "  --image-uri URI            Image URI"
      echo "  --total-supply AMOUNT      Total supply of tokens"
      echo "  --price AMOUNT             Price per token"
      echo "  --description DESC         Description of the token"
      echo "  --require-kyc BOOL         Whether KYC is required (true/false)"
      echo ""
      echo "For approve-kyc action:"
      echo "  --user-address ADDR        Address to approve for KYC"
      echo ""
      echo "For update-price action:"
      echo "  --new-price AMOUNT         New price per token"
      echo ""
      echo "  --help                     Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Check if INFURA_API_KEY is set when using a public network
if [[ $RPC_URL == *"infura.io"* && -z "${INFURA_API_KEY}" ]]; then
  echo -e "${YELLOW}Warning: INFURA_API_KEY environment variable is not set.${NC}"
  echo -e "${YELLOW}Set it with: export INFURA_API_KEY=your_infura_api_key${NC}"
  exit 1
fi

# Set PRIVATE_KEY environment variable if provided
if [[ -n "$PRIVATE_KEY" ]]; then
  export PRIVATE_KEY
fi

# Set ACTION environment variable
export ACTION="$ACTION"

# Build the command
CMD="forge script script/InteractWithContracts.s.sol --rpc-url $RPC_URL"

# Add --broadcast flag if requested and action is not query
if $BROADCAST && [ "$ACTION" != "query" ]; then
  CMD="$CMD --broadcast"
fi

# Print interaction information
echo -e "${GREEN}Interacting with contracts on:${NC} $RPC_URL"
echo -e "${GREEN}Action:${NC} $ACTION"

if [ "$ACTION" != "query" ]; then
  if $BROADCAST; then
    echo -e "${YELLOW}Transactions will be broadcast to the network${NC}"
  else
    echo -e "${YELLOW}Dry run mode (use --broadcast to send transactions)${NC}"
  fi
fi

# Run the interaction script
echo -e "${GREEN}Running interaction script...${NC}"
eval $CMD

# Check if interaction was successful
if [ $? -eq 0 ]; then
  echo -e "${GREEN}Interaction completed successfully!${NC}"
else
  echo -e "${YELLOW}Interaction failed.${NC}"
  exit 1
fi
