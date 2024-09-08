# FlickArena

FlickArena is a decentralized gaming platform built on blockchain technology. It allows users to engage in various games and tournaments, leveraging the power of cryptocurrency and smart contracts to ensure fair play and secure transactions. One of the popular games on FlickArena is the dart game 301, where players compete to reach exactly 301 points in the fewest number of darts.

### Contract
Factory contract: https://testnet.chiliscan.com/address/0x405Bb05F3584CE93c1c033091b420199715E6555/contract/88882/code
Game contract: https://testnet.chiliscan.com/address/0xbD3B8462B96Ef9b51DeE13a46901D781e386EA34/contract/88882/code

### Deploy

```shell
source .env

npx hardhat ignition deploy ./ignition/modules/DeployFactory.ts --network chiliz_spicy
```

### Verify

verify factory contract
```shell
npx hardhat verify --network chiliz_spicy <factory_address>
```

verify game contract
```shell
npx hardhat verify --network baseSepolia 0x0B151F0C8763506bB8b0b5F28e16331542fC3405 <host_address> "0x000000000000000000000000000000000000000000000000000000000000012d" "0x000000000000000000000000000000000000000000000000000000000000000a"
```
