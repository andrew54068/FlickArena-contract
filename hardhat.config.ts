import 'dotenv/config'

import 'hardhat-deploy'
import 'hardhat-contract-sizer'
import { HardhatUserConfig } from 'hardhat/types'
import '@nomiclabs/hardhat-ethers'
import "@nomicfoundation/hardhat-ignition"

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
        {
            version: '0.8.22',
            settings: {
                optimizer: {
                    enabled: true,
                    runs: 200,
                },
            },
        },
    ],
  },
  etherscan: {
    apiKey: {
      chiliz_spicy: "chiliz_spicy", // apiKey is not required, just set a placeholder
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
  },
};

export default config;