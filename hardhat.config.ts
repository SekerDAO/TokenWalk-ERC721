import "@nomiclabs/hardhat-waffle";
import "hardhat-deploy";
import "hardhat-gas-reporter"
import "@nomiclabs/hardhat-etherscan";

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
const INFURA_API_KEY = "";
const RINKEBY_PRIVATE_KEY = "";

module.exports = {
  defaultNetwork: "kovan",
  solidity: {
    version: "0.8.6",
    allowUnlimitedContractSize: true,
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    hardhat: {
    },
    rinkeby: {
      url: `https://rinkeby.infura.io/v3/${INFURA_API_KEY}`,
      accounts: [`0x${RINKEBY_PRIVATE_KEY}`],
    },
    kovan: {
      url: `https://kovan.infura.io/v3/${INFURA_API_KEY}`,
      accounts: [`0x${RINKEBY_PRIVATE_KEY}`],
    }
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: ""
  },
  gasReporter: {
    enabled: false
  }
};
