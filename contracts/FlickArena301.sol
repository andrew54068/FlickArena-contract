// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FlickArena301 {
    struct Player {
        address addr;
        uint256 score;
        uint256[][] dartScores; // Double layer array to store dart scores for each round
    }

    Player[2] public players;
    uint256 public currentPlayerIndex;
    uint256 public currentRound;
    uint256 public constant MAX_ROUNDS = 10;
    uint256 public constant TARGET_SCORE = 301;
    uint256 public constant MAX_DARTS_PER_TURN = 3;
    bool public gameStarted;
    bool public gameEnded;
    address public host;

    event PlayerRegistered(address player, uint256 playerIndex);
    event GameStarted();
    event DartFlicked(address player, uint256 score);
    event PlayerWon(address winner);
    event GameEnded(address winner);
    event GameDrawn(); // New event for draw games

    constructor() {
        host = msg.sender;
    }

    modifier onlyHost() {
        require(msg.sender == host, "Only the host can perform this action");
        _;
    }

    modifier gameInProgress() {
        require(gameStarted && !gameEnded, "Game not in progress");
        _;
    }

    function registerPlayer() external {
        require(!gameStarted, "Game already started");
        require(
            players[0].addr == address(0) || players[1].addr == address(0),
            "Both players already registered"
        );

        uint256 playerIndex = players[0].addr == address(0) ? 0 : 1;
        players[playerIndex].addr = msg.sender;
        players[playerIndex].score = TARGET_SCORE;
        players[playerIndex].dartScores.push(); // Initialize first round

        emit PlayerRegistered(msg.sender, playerIndex);

        if (players[0].addr != address(0) && players[1].addr != address(0)) {
            gameStarted = true;
            currentRound = 1;
            emit GameStarted();
        }
    }

    function flickDart(
        uint256 score,
        address player
    ) external onlyHost gameInProgress {
        require(
            players[currentPlayerIndex].dartScores[currentRound - 1].length < 3,
            "Already thrown 3 darts"
        );
        require(score >= 0 && score <= 60, "Invalid score");

        if (player != players[currentPlayerIndex].addr) {
            currentPlayerIndex = 1 - currentPlayerIndex;
        }

        Player storage currentPlayer = players[currentPlayerIndex];

        // Update the player's score
        currentPlayer.score -= score;

        // Record the individual dart score
        currentPlayer.dartScores[currentRound - 1].push(score);

        emit DartFlicked(player, score);

        // Handle bust scenario
        if (currentPlayer.score < 0) {
            // Bust, reset the round score
            currentPlayer.score = accumulateScore(
                currentPlayerIndex,
                currentRound - 1
            );
            switchPlayer();
            return;
        }

        if (currentPlayer.score == 0) {
            gameEnded = true;
            emit PlayerWon(player);
            emit GameEnded(player);
        } else {
            // Check if the player has thrown 3 darts
            if (
                currentPlayer.dartScores[currentRound - 1].length ==
                MAX_DARTS_PER_TURN
            ) {
                // Switch to the next player
                switchPlayer();
            }
        }
    }

    function switchPlayer() internal {
        currentPlayerIndex = 1 - currentPlayerIndex;
        if (currentPlayerIndex == 0) {
            currentRound++;
            if (currentRound > MAX_ROUNDS) {
                gameEnded = true;
                if (players[0].score == players[1].score) {
                    emit GameDrawn();
                    emit GameEnded(address(0)); // Use address(0) to indicate a draw
                } else {
                    address winner = players[0].score < players[1].score
                        ? players[0].addr
                        : players[1].addr;
                    emit GameEnded(winner);
                }
            } else {
                players[0].dartScores.push();
                players[1].dartScores.push();
            }
        }
    }

    function calculateRoundScore(
        uint256 playerIndex,
        uint256 round
    ) internal view returns (uint256) {
        uint256 roundScore = 0;
        for (
            uint256 i = 0;
            i < players[playerIndex].dartScores[round].length;
            i++
        ) {
            roundScore += players[playerIndex].dartScores[round][i];
        }
        return roundScore;
    }

    function accumulateScore(
        uint256 playerIndex,
        uint256 round
    ) internal view returns (uint256) {
        uint256 roundScore = 0;
        for (uint256 i = 0; i < round; i++) {
            roundScore += calculateRoundScore(playerIndex, i);
        }
        return roundScore;
    }

    function getPlayers() external view returns (address[2] memory) {
        return [players[0].addr, players[1].addr];
    }

    function getCurrentPlayer() external view returns (address) {
        return players[currentPlayerIndex].addr;
    }

    function getCurrentScore(
        uint256 playerIndex
    ) external view returns (uint256) {
        require(playerIndex < 2, "Invalid player index");
        return players[playerIndex].score;
    }

    function getPlayerDartScores(
        uint256 playerIndex
    ) external view returns (uint256[][] memory) {
        require(playerIndex < 2, "Invalid player index");
        return players[playerIndex].dartScores;
    }

    function getPlayerRoundScores(
        uint256 playerIndex,
        uint256 round
    ) external view returns (uint256[] memory) {
        require(playerIndex < 2, "Invalid player index");
        return players[playerIndex].dartScores[round];
    }
}
