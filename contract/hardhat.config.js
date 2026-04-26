require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");
require("dotenv").config();

const PRIVATE_KEY = process.env.PRIVATE_KEY;

if (!PRIVATE_KEY) {
  throw new Error("PRIVATE_KEY not set in .env");
}

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.28",
    settings: {
      viaIR: true,
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    beamTestnet: {
      url: "https://build.onbeam.com/rpc/testnet",
      accounts: [PRIVATE_KEY],
      chainId: 13337,
    },
    beamMainnet: {
      url: "https://build.onbeam.com/rpc",
      accounts: [PRIVATE_KEY],
      chainId: 4337,
    },
  },
};
