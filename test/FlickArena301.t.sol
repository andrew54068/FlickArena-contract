 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/FlickArena301.sol";

contract FlickArena301Test is Test {
    FlickArena301 public flickArena;
    address public owner;
    address public player1;
    address public player2;
    address public player3;

    function setUp() public {
        owner = address(this);
        player1 = address(0x1);
        player2 = address(0x2);
        player3 = address(0x3);
        flickArena = new FlickArena301();
    }

    function testRegisterPlayers() public {
        vm.prank(player1);
        vm.expectEmit(true, true, false, true);
        emit FlickArena301.PlayerRegistered(player1, 0);
        flickArena.registerPlayer();

        vm.prank(player2);
        vm.expectEmit(true, true, false, true);
        emit FlickArena301.PlayerRegistered(player2, 1);
        emit FlickArena301.GameStarted();
        flickArena.registerPlayer();

        vm.prank(player2);
        vm.expectRevert("Game already started");
        flickArena.registerPlayer();
    }

    function testRegisterMoreThanTwoPlayers() public {
        vm.prank(player1);
        flickArena.registerPlayer();
        vm.prank(player2);
        flickArena.registerPlayer();

        vm.prank(player3);
        vm.expectRevert("Both players already registered");
        flickArena.registerPlayer();
    }

    function testFlickDart() public {
        vm.prank(player1);
        flickArena.registerPlayer();
        vm.prank(player2);
        flickArena.registerPlayer();

        vm.expectEmit(true, true, false, true);
        emit FlickArena301.DartFlicked(player1, 20);
        flickArena.flickDart(20, player1);
    }

    function testNonHostFlickDart() public {
        vm.prank(player1);
        flickArena.registerPlayer();
        vm.prank(player2);
        flickArena.registerPlayer();

        vm.prank(player1);
        vm.expectRevert("Only the host can perform this action");
        flickArena.flickDart(20, player1);
    }

    function testFlickForNonRegisteredPlayer() public {
        vm.prank(player1);
        flickArena.registerPlayer();
        vm.prank(player2);
        flickArena.registerPlayer();

        vm.expectRevert("Already thrown 3 darts");
        flickArena.flickDart(20, player3);
    }

    function testOutOfTurnFlicks() public {
        vm.prank(player1);
        flickArena.registerPlayer();
        vm.prank(player2);
        flickArena.registerPlayer();

        flickArena.flickDart(20, player1);
        vm.expectRevert("Already thrown 3 darts");
        flickArena.flickDart(20, player1);
    }

    function testInvalidScores() public {
        vm.prank(player1);
        flickArena.registerPlayer();
        vm.prank(player2);
        flickArena.registerPlayer();

        vm.expectRevert("Invalid score");
        flickArena.flickDart(61, player1);
    }

    function testHandleBusts() public {
        vm.prank(player1);
        flickArena.registerPlayer();
        vm.prank(player2);
        flickArena.registerPlayer();

        flickArena.flickDart(60, player1);
        flickArena.flickDart(60, player1);
        flickArena.flickDart(60, player1);
        flickArena.flickDart(60, player2);
        flickArena.flickDart(60, player2);
        flickArena.flickDart(60, player2);
        flickArena.flickDart(60, player1);
        assertEq(flickArena.getCurrentScore(0), 301);
    }

    function testEndGameWhenPlayerReachesZero() public {
        vm.prank(player1);
        flickArena.registerPlayer();
        vm.prank(player2);
        flickArena.registerPlayer();

        for (uint i = 0; i < 5; i++) {
            flickArena.flickDart(60, player1);
            flickArena.flickDart(60, player2);
        }

        vm.expectEmit(true, true, false, true);
        emit FlickArena301.PlayerWon(player1);
        emit FlickArena301.GameEnded(player1);
        flickArena.flickDart(1, player1);
    }

    function testEndGameAfterMaxRounds() public {
        vm.prank(player1);
        flickArena.registerPlayer();
        vm.prank(player2);
        flickArena.registerPlayer();

        for (uint i = 0; i < 30; i++) {
            flickArena.flickDart(1, player1);
            flickArena.flickDart(1, player2);
        }

        vm.expectEmit(true, true, false, true);
        emit FlickArena301.GameEnded(player1);
        flickArena.flickDart(1, player1);
    }

    function testRecordIndividualDartScores() public {
        vm.prank(player1);
        flickArena.registerPlayer();
        vm.prank(player2);
        flickArena.registerPlayer();

        flickArena.flickDart(20, player1);
        flickArena.flickDart(30, player1);
        flickArena.flickDart(10, player1);

        uint256[][] memory dartScores = flickArena.getPlayerDartScores(0);
        assertEq(dartScores[0][0], 20);
        assertEq(dartScores[0][1], 30);
        assertEq(dartScores[0][2], 10);

        flickArena.flickDart(15, player2);
        flickArena.flickDart(25, player2);
        flickArena.flickDart(35, player2);

        dartScores = flickArena.getPlayerDartScores(1);
        assertEq(dartScores[0][0], 15);
        assertEq(dartScores[0][1], 25);
        assertEq(dartScores[0][2], 35);
    }

    function testCalculateRoundScores() public {
        vm.prank(player1);
        flickArena.registerPlayer();
        vm.prank(player2);
        flickArena.registerPlayer();

        flickArena.flickDart(20, player1);
        flickArena.flickDart(30, player1);
        flickArena.flickDart(10, player1);

        uint256[] memory roundScores = flickArena.getPlayerRoundScores(0, 0);
        assertEq(roundScores[0], 20);
        assertEq(roundScores[1], 30);
        assertEq(roundScores[2], 10);

        flickArena.flickDart(15, player2);
        flickArena.flickDart(25, player2);
        flickArena.flickDart(35, player2);

        roundScores = flickArena.getPlayerRoundScores(1, 0);
        assertEq(roundScores[0], 15);
        assertEq(roundScores[1], 25);
        assertEq(roundScores[2], 35);
    }

    function testHandleBustsWithIndividualDartScores() public {
        vm.prank(player1);
        flickArena.registerPlayer();
        vm.prank(player2);
        flickArena.registerPlayer();

        flickArena.flickDart(60, player1);
        flickArena.flickDart(60, player1);
        flickArena.flickDart(60, player1);

        uint256[][] memory dartScores = flickArena.getPlayerDartScores(0);
        assertEq(dartScores[0].length, 3);
        assertEq(flickArena.getCurrentScore(0), 301);

        flickArena.flickDart(50, player2);
        flickArena.flickDart(50, player2);
        flickArena.flickDart(50, player2);

        dartScores = flickArena.getPlayerDartScores(1);
        assertEq(dartScores[0][0], 50);
        assertEq(dartScores[0][1], 50);
        assertEq(dartScores[0][2], 50);
        assertEq(flickArena.getCurrentScore(1), 151);
    }

    function testDrawGame() public {
        vm.prank(player1);
        flickArena.registerPlayer();
        vm.prank(player2);
        flickArena.registerPlayer();

        for (uint i = 0; i < 10; i++) {
            flickArena.flickDart(1, player1);
            flickArena.flickDart(1, player1);
            flickArena.flickDart(1, player1);
            flickArena.flickDart(1, player2);
            flickArena.flickDart(1, player2);
            flickArena.flickDart(1, player2);
        }

        vm.expectEmit(true, true, false, true);
        emit FlickArena301.GameDrawn();
        emit FlickArena301.GameEnded(address(0));
        flickArena.flickDart(1, player1);

        assertEq(flickArena.getCurrentScore(0), 271);
        assertEq(flickArena.getCurrentScore(1), 271);
    }

    function testViewFunctions() public {
        vm.prank(player1);
        flickArena.registerPlayer();
        vm.prank(player2);
        flickArena.registerPlayer();

        flickArena.flickDart(20, player1);

        address[2] memory players = flickArena.getPlayers();
        assertEq(players[0], player1);
        assertEq(players[1], player2);

        assertEq(flickArena.getCurrentPlayer(), player1);

        assertEq(flickArena.getCurrentScore(0), 281);
        assertEq(flickArena.getCurrentScore(1), 301);

        vm.expectRevert("Invalid player index");
        flickArena.getCurrentScore(2);
    }
}