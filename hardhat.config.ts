import { HardhatUserConfig } from "hardhat/config";
import "hardhat-abi-exporter";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  solidity: "0.8.9",
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
