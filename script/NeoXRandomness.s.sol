// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {NeoXRandomness} from "../src/NeoXRandomness.sol";

contract NeoXRandomnessScript is Script {
    function run() public {
        vm.startBroadcast();
        NeoXRandomness randomness = new NeoXRandomness();
        console.log("NeoXRandomness deployed at:", address(randomness));
        vm.stopBroadcast();
    }
}
