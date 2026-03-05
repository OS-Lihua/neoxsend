// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {NeoXCommitReveal} from "../src/NeoXCommitReveal.sol";

/// @dev Concrete implementation for testing since NeoXCommitReveal is abstract.
contract MockGame is NeoXCommitReveal {
    function commit() external returns (uint256) {
        return _commit();
    }

    function reveal(uint256 requestId) external returns (uint256) {
        return _reveal(requestId);
    }
}

contract NeoXCommitRevealTest is Test {
    MockGame public game;

    function setUp() public {
        game = new MockGame();
    }

    function test_commitAndReveal() public {
        uint256 requestId = game.commit();
        assertEq(requestId, 0);

        (address requester, uint256 commitBlock, bool revealed) = game.getRequest(requestId);
        assertEq(requester, address(this));
        assertEq(commitBlock, block.number);
        assertFalse(revealed);

        vm.roll(block.number + 1);

        uint256 result = game.reveal(requestId);
        assertTrue(result != 0);

        (,, revealed) = game.getRequest(requestId);
        assertTrue(revealed);
    }

    function test_cannotRevealSameBlock() public {
        uint256 requestId = game.commit();

        vm.expectRevert("wait at least 1 block");
        game.reveal(requestId);
    }

    function test_cannotRevealTwice() public {
        uint256 requestId = game.commit();
        vm.roll(block.number + 1);
        game.reveal(requestId);

        vm.expectRevert("already revealed");
        game.reveal(requestId);
    }

    function test_cannotRevealNonexistent() public {
        vm.expectRevert("request not found");
        game.reveal(999);
    }

    function test_differentRequestsGetDifferentResults() public {
        uint256 id1 = game.commit();
        uint256 id2 = game.commit();

        vm.roll(block.number + 1);

        uint256 r1 = game.reveal(id1);
        uint256 r2 = game.reveal(id2);

        assertTrue(r1 != r2, "different requests should get different results");
    }

    function test_differentCallersGetDifferentResults() public {
        uint256 id1 = game.commit();

        vm.prank(address(0xBEEF));
        uint256 id2 = game.commit();

        vm.roll(block.number + 1);

        uint256 r1 = game.reveal(id1);
        uint256 r2 = game.reveal(id2);

        assertTrue(r1 != r2, "different callers should get different results");
    }

    function test_blockhashExpired() public {
        uint256 requestId = game.commit();
        vm.roll(block.number + 257);

        vm.expectRevert("blockhash expired, request void");
        game.reveal(requestId);
    }

    function test_requestIdIncrementing() public {
        assertEq(game.commit(), 0);
        assertEq(game.commit(), 1);
        assertEq(game.commit(), 2);
    }

    function test_commitEmitsEvent() public {
        vm.expectEmit(true, true, false, true);
        emit NeoXCommitReveal.Committed(0, address(this), block.number);
        game.commit();
    }

    function test_revealEmitsEvent() public {
        uint256 requestId = game.commit();
        vm.roll(block.number + 1);

        vm.expectEmit(true, false, false, false);
        emit NeoXCommitReveal.Revealed(requestId, 0);
        game.reveal(requestId);
    }
}
