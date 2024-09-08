// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {FlickArenaBetFactory} from "../contracts/FlickArenaBetFactory.sol";

contract DeployScript is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        FlickArenaBetFactory factory = new FlickArenaBetFactory();
        console2.log("FlickArenaBetFactory deployed at:", address(factory));

        vm.stopBroadcast();
    }
}