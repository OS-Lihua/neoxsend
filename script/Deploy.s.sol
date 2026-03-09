// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {NeoXRandomness} from "../src/NeoXRandomness.sol";
import {MockGame} from "../test/mock/MockGame.sol";

/// @title Deploy
/// @notice Deployment script for NeoX BLS Randomness contracts.
/// @dev Uses Foundry keystore for secure key management. Usage:
///
///   1. Import your private key into Foundry's keystore (one-time setup):
///
///        cast wallet import deployer --interactive
///
///   2. Deploy to NeoX mainnet:
///
///        forge script script/Deploy.s.sol --account deployer --broadcast --rpc-url neox_mainnet
///
///   3. Deploy to NeoX testnet:
///
///        forge script script/Deploy.s.sol --account deployer --broadcast --rpc-url neox_testnet
///
///   Foundry will prompt for the keystore password at runtime.
contract DeployScript is Script {
    function run() public {
        vm.startBroadcast();

        NeoXRandomness randomness = new NeoXRandomness();
        console.log("NeoXRandomness deployed at:", address(randomness));

        MockGame mockGame = new MockGame();
        console.log("MockGame deployed at:", address(mockGame));

        vm.stopBroadcast();
    }
}
