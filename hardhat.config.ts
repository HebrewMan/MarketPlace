import { HardhatUserConfig } from "hardhat/config";
import "hardhat-abi-exporter";
import "@nomicfoundation/hardhat-toolbox";


const config: HardhatUserConfig = {
  solidity: "0.8.9",
  networks: {
    mainnet: {
      url:'https://bsc-dataseed.binance.org/',
      chainId: 56,
      accounts:['3dc56a87216e81830a8b5193fdabcf9b85f48ddaa266a041d97573e872ba8923'],
    },
    bsctest: { 
      url:'https://data-seed-prebsc-1.arcdex.io:8575/',
      chainId: 97,
      accounts:['3dc56a87216e81830a8b5193fdabcf9b85f48ddaa266a041d97573e872ba8923'],
    },
    kovan: {
      url: 'https://kovan.infura.io/v3/d8fdd5c450944e2e8a5bdf0f1ae7440e',
      chainId: 42,
      accounts:['3dc56a87216e81830a8b5193fdabcf9b85f48ddaa266a041d97573e872ba8923'],
    },
    
  },
  etherscan: {
    apiKey: 'ABC123ABC123ABC123ABC123ABC123ABC1',
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
