import type { HardhatUserConfig } from "hardhat/config";
import "@typechain/hardhat";
import "@nomicfoundation/hardhat-foundry";

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.8.25",
      },
    ],
    settings: {
      evmVersion: "cancun"
    }
  },
  networks: {
    hardhat: {
      blockGasLimit: 30_000_000,
      throwOnCallFailures: false,
      allowUnlimitedContractSize: false,
    },
    verificationNetwork: {
      url: process.env.NETWORK_RPC ?? "",
    },
  },
  // specify separate cache for hardhat, since it could possibly conflict with foundry's
  paths: { cache: "hh-cache", sources: "src" },
};

export default config;
