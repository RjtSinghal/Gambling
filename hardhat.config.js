require("@nomicfoundation/hardhat-toolbox");

const QUICKNODE_API_KEY = vars.get("QUICKNODE_API_KEY");

const SEPOLIA_PRIVATE_KEY = vars.get("SEPOLIA_PRIVATE_KEY");

const ETHERSCAN_API_KEY = vars.get("ETHERSCAN_API_KEY");


/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  defaultNetwork: "sepolia",
  networks: {
    sepolia: {
      // url: "https://eth-sepolia.g.alchemy.com/v2/m1A8zCuejMwG-mO8-_ImhAgzomSz7DFv",
      url: `https://responsive-bold-film.ethereum-sepolia.quiknode.pro/${QUICKNODE_API_KEY}/`,
      accounts: [SEPOLIA_PRIVATE_KEY],
      chainId: 11155111,
      timeout: 20000
    }
  },
  etherscan: {
    apiKey: {
      sepolia: ETHERSCAN_API_KEY,
    } 
  },
  solidity: {
    version: "0.8.26",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  mocha: {
    timeout: 100000000
  },
};
