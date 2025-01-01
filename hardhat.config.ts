import { HardhatUserConfig } from "hardhat/config"; // Imports Hardhat's configuration type
import "@nomicfoundation/hardhat-toolbox"; // Integrates the toolbox

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.28", // Specifies the Solidity compiler version
    // settings: {        // Specifies compiler settings, such as optimizer and evmVersion
    //   evmVersion: "istanbul",
    // }
  },
  paths: {
    sources: "./contracts",    // Directory where Solidity contracts are located
    //scripts: "./scripts",      // Directory for deployment and utility scripts
    cache: "./cache",          // Directory for Hardhat's cache
    artifacts: "./artifacts"   // Directory for compiled contract artifacts
  },

  defaultNetwork: "hardhat", // Sets the default network to Hardhat's local network

  networks: {
    hardhat: {
      // Configuration for the Hardhat network
      // Additional settings like forking can be added here if needed
    }
    // Additional networks can be configured here
    // Example:
    // rinkeby: {
    //   url: "https://rinkeby.infura.io/v3/YOUR_INFURA_PROJECT_ID",
    //   accounts: [`0x${YOUR_PRIVATE_KEY}`]
    // }
  },

  etherscan: {
    // Optional: Etherscan API key for contract verification
    // apiKey: "YOUR_ETHERSCAN_API_KEY"
  },

  typechain: {
    outDir: "typechain", // Directory where Typechain will output TypeScript bindings
    target: "ethers-v6"  // Specifies that Typechain should generate bindings compatible with Ethers.js v6
  }
};

export default config; // Exports the configuration object as the default export
