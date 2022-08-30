// require('@nomiclabs/hardhat-waffle');
import { HardhatUserConfig } from "hardhat/config";

const path = require('path');
const dotenv = require('dotenv')
const file = path.join("~", ".env-secret");

const envConfig = dotenv.config({
  path: file
}).parsed;

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
        main: {
          url: `http://192.168.0.20:8545`, //<---- YOUR INFURA ID! (or it won't work)
          accounts: [`${privateKey}`],
        },
        testnet: {
          url: `https://data-seed-prebsc-1.arcdex.io:8575`, //<---- YOUR INFURA ID! (or it won't work)
          accounts: [`${privateKey}`],
        },
      },
    // etherscan: {
    //   apiKey: process.env.ETHERSCAN_API_KEY,
    // },
  };

export default config;