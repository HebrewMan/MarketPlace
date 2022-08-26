import { HardhatUserConfig } from "hardhat/config";
import { config as dotenvConfig } from "dotenv";
import "hardhat-abi-exporter";
import "@nomicfoundation/hardhat-toolbox";
import { resolve } from "path";

const dotenvConfigPath: string = process.env.DOTENV_CONFIG_PATH || "./.env";
dotenvConfig({ path: resolve(__dirname, dotenvConfigPath) });


const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
          version: "0.8.14"
      },
        {
            version: "0.8.9"
        },
    ],
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    mainnet: {
      url:process.env.BSC_MAINNET_URL,
      chainId: 56,
      accounts:[process.env.PRIVATE_KEY || ''],
    },
    bsctest: { 
      url:process.env.BSC_TESTNET_ARC_URL,
      chainId: 97,
      accounts:[process.env.PRIVATE_KEY || ''],
    },
    kovan: {
      url: process.env.KOVAN_URL,
      chainId: 42,
      accounts:[process.env.PRIVATE_KEY || ''],
    },
    
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
};

const abiExporter = {
  path: './data/abi',
  runOnCompile: true,
  clear: true,
  flat: true,
  only: [':ERC20$'],
  spacing: 2,
  pretty: true,
  format: "minimal",
};

export default config;
