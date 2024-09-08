/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { ethers } from "ethers";
import {
  FactoryOptions,
  HardhatEthersHelpers as HardhatEthersHelpersBase,
} from "@nomiclabs/hardhat-ethers/types";

import * as Contracts from ".";

declare module "hardhat/types/runtime" {
  interface HardhatEthersHelpers extends HardhatEthersHelpersBase {
    getContractFactory(
      name: "FlickArenaBet",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.FlickArenaBet__factory>;
    getContractFactory(
      name: "FlickArenaBetFactory",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.FlickArenaBetFactory__factory>;

    getContractAt(
      name: "FlickArenaBet",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.FlickArenaBet>;
    getContractAt(
      name: "FlickArenaBetFactory",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.FlickArenaBetFactory>;

    // default types
    getContractFactory(
      name: string,
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<ethers.ContractFactory>;
    getContractFactory(
      abi: any[],
      bytecode: ethers.utils.BytesLike,
      signer?: ethers.Signer
    ): Promise<ethers.ContractFactory>;
    getContractAt(
      nameOrAbi: string | any[],
      address: string,
      signer?: ethers.Signer
    ): Promise<ethers.Contract>;
  }
}
