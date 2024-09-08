import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@typechain/hardhat";
import "@nomicfoundation/hardhat-ethers";
import "dotenv/config";

const config: HardhatUserConfig = {
  solidity: '0.8.24',
  etherscan: {
    apiKey: {
      chiliz_spicy: "chiliz_spicy", // apiKey is not required, just set a placeholder
      polygonAmoy: process.env.POLYGONSCAN_API_KEY!,
    },
    customChains: [
      {
        network: "chiliz_spicy",
        chainId: 88882,
        urls: {
          apiURL: "https://api.routescan.io/v2/network/testnet/evm/88882/etherscan",
          browserURL: "https://testnet.chiliscan.com"
        }
      }
    ]
  },
  networks: {
    chiliz_spicy: {
      url: 'https://spicy-rpc.chiliz.com',
      accounts: [process.env.PRIVATE_KEY!]
    },
    amoy: {
      url: "https://polygon-amoy-bor-rpc.publicnode.com",
      accounts: [process.env.PRIVATE_KEY!],
    },
  },
  typechain: {
    outDir: "typechain-types",
    target: "ethers-v5",
  },
};

export default config;