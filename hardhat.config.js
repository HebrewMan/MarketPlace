require('@nomiclabs/hardhat-waffle');

var path = require("path");
const dotenv = require('dotenv')
const file = path.join("~", ".env-secret");

const envConfig = dotenv.config({
  path: file
}).parsed;

if (!envConfig) {
  console.error(`open ${file} fail`);
  process.exit(1);
}

const privateKey = process.env.PRIVATE_KEY

if (!privateKey) {
  console.error('undefined key');
  process.exit(1);
}


// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: "0.8.10",
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
};