// Import the type definition for Hardhat configuration
import { HardhatUserConfig } from "hardhat/config";
// Import all the hardhat plugins (testing, deployment, etc.) in one package
import "@nomicfoundation/hardhat-toolbox";
// Import dotenvx for managing environment variables
import dotenvx from '@dotenvx/dotenvx';

// Load environment variables from .env file
dotenvx.config({ path: '.env' });

// Define required environment variables with TypeScript for type safety
const REQUIRED_ENV_VARS = {
  SEPOLIA_RPC_URL: process.env.SEPOLIA_RPC_URL,        // URL to connect to Sepolia testnet
  ACCOUNT_PRIVATE_KEY: process.env.ACCOUNT_PRIVATE_KEY, // Primary account's private key
  ACCOUNT2_PRIVATE_KEY: process.env.ACCOUNT2_PRIVATE_KEY, // Secondary account's private key
  ETHERSCAN_API_KEY: process.env.ETHERSCAN_API_KEY,    // API key for Etherscan verification
} as const;

// Helper function to validate environment variables
// Generic type T extends Record<string, string | undefined> means it accepts an object with string keys and string or undefined values
const getEnvVars = <T extends Record<string, string | undefined>>(vars: T): { [K in keyof T]: string } => {
  // Find any missing (undefined) environment variables
  const missingVars = Object.entries(vars)
    .filter(([_, value]) => !value)
    .map(([key]) => key);

  // Throw error if any required variables are missing
  if (missingVars.length > 0) {
    throw new Error(`Missing required environment variables: ${missingVars.join(', ')}`);
  }

  // Return the validated environment variables
  return vars as { [K in keyof T]: string };
};

// Destructure and validate all required environment variables
const {
  SEPOLIA_RPC_URL,
  ACCOUNT_PRIVATE_KEY,
  ACCOUNT2_PRIVATE_KEY,
  ETHERSCAN_API_KEY,
} = getEnvVars(REQUIRED_ENV_VARS);

// Main Hardhat configuration object
const config: HardhatUserConfig = {
  // Solidity compiler configuration
  solidity: {
    version: "0.8.28", // Specify which version of Solidity to use
  },

  // Project structure paths
  paths: {
    sources: "./contracts",    // Where your smart contracts are located
    cache: "./cache",          // Where compilation cache is stored
    artifacts: "./artifacts"   // Where compiled contracts are stored
  },

  // Default network to use when none is specified
  defaultNetwork: "hardhat",

  // Network configurations
  networks: {
    // Configuration for Sepolia testnet
    sepolia: {
      url: SEPOLIA_RPC_URL,                                    // RPC endpoint URL
      accounts: [ACCOUNT_PRIVATE_KEY, ACCOUNT2_PRIVATE_KEY],   // Account private keys
      chainId: 11155111                                        // Sepolia's chain ID
    }
  },

  // Etherscan configuration for contract verification
  etherscan: {
    apiKey: {
      sepolia: ETHERSCAN_API_KEY  // API key for verifying contracts on Sepolia
    }
  },

  // TypeChain configuration for generating TypeScript bindings
  typechain: {
    outDir: "typechain",    // Output directory for generated TypeScript files
    target: "ethers-v6"     // Generate types compatible with ethers.js v6
  }
};

// Export the configuration
export default config;
