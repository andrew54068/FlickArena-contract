// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {FlickArena301} from "../src/FlickArena301.sol";

contract DeployScript is Script {
    FlickArena301 public flickArena301;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        console.log("msg.sender", msg.sender);

        flickArena301 = new FlickArena301();

        vm.stopBroadcast();
    }
}
