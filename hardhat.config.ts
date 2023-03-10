import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import { join } from 'path';
import dotenv from 'dotenv';

const file = join("~", ".env-secret");
const envConfig = dotenv.config({ path: file }).parsed;

if (!envConfig) {
  console.error(`open ${file} fail`);
  process.exit(1);
}

const privateKey = process.env.PRIVATE_KEY;

if (!privateKey) {
  console.error('undefined key');
  process.exit(1);
}

const config: HardhatUserConfig = {
  networks: {
    hardhat: {
      blockGasLimit: 20000000,
    },
    main: {
      url: `http://192.168.0.20:8545`, //<---- YOUR INFURA ID! (or it won't work)
      accounts: [`${privateKey}`],
    },
    testnet: {
      url: `https://data-seed-prebsc-1-s1.binance.org:8545`, //<---- YOUR INFURA ID! (or it won't work)
      accounts: [`${privateKey}`],
    },
  },
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
        runs: 1000,
      },
    }
  },
  
  // etherscan: {
  //   apiKey: process.env.ETHERSCAN_API_KEY,
  // },
};

export default config;
