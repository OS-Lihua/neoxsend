// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {NeoXRandomness} from "../src/NeoXRandomness.sol";

contract NeoXRandomnessTest is Test {
    NeoXRandomness public randomness;

    function setUp() public {
        randomness = new NeoXRandomness();
    }

    function test_getRandomNumber() public view {
        uint256 r = randomness.getRandomNumber(42);
        assertTrue(r != 0);
    }

    function test_differentSeedsProduceDifferentResults() public view {
        uint256 r1 = randomness.getRandomNumber(1);
        uint256 r2 = randomness.getRandomNumber(2);
        assertTrue(r1 != r2, "different seeds should produce different results");
    }

    function test_differentCallersProduceDifferentResults() public {
        uint256 r1 = randomness.getRandomNumber(42);

        vm.prank(address(0xBEEF));
        uint256 r2 = randomness.getRandomNumber(42);

        assertTrue(r1 != r2, "different callers should produce different results");
    }

    function test_differentBlocksProduceDifferentResults() public {
        uint256 r1 = randomness.getRandomNumber(42);

        vm.roll(block.number + 1);
        vm.warp(block.timestamp + 15);

        uint256 r2 = randomness.getRandomNumber(42);
        assertTrue(r1 != r2, "different blocks should produce different results");
    }
}
