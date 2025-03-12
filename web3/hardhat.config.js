require('dotenv').config(); // Load environment variables from .env file

require("@matterlabs/hardhat-zksync-solc");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  zksolc: {
    version: "1.3.9",
    compilerSource: "binary",
    settings: {
      optimizer: {
        enabled: true,
      },
    },
  },
  defaultNetwork: 'sepolia',
  networks: {
    hardhat: {},
    ganache: {
      url: process.env.GANACHE_URL,
      chainId: parseInt(process.env.GANACHE_CHAIN_ID, 10),// Ganache chain ID, often 1337
    },
    sepolia: {
      url: process.env.SEPOLIA_URL,
      chainId: parseInt(process.env.SEPOLIA_CHAIN_ID, 10), // Specify the Sepolia chain ID
      accounts: {
        mnemonic: process.env.PRIVATE_KEY, // Specify the mnemonic for your Sepolia accounts
      },
    }
  },
  paths: {
    artifacts: "./artifacts-zk",
    cache: "./cache-zk",
    sources: "./contracts",
    tests: "./test",
  },
  solidity: {
    version: "0.8.17",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
};
