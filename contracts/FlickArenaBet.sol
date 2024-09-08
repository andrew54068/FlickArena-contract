// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract FlickArenaBet {
    struct Player {
        address addr;
        uint256 score;
        uint256[][] dartScores;
        uint256 bet;
    }

    Player[2] public players;
    uint256 public currentPlayerIndex;
    uint256 public currentRound;
    uint256 public immutable MAX_ROUNDS;
    uint256 public immutable TARGET_SCORE;
    uint256 public constant MAX_DARTS_PER_TURN = 3;
    bool public gameStarted;
    bool public gameEnded;
    address public host;
    uint256 public prizePool;

    event PlayerRegistered(address player, uint256 playerIndex);
    event BetPlaced(address player, uint256 amount);
    event GameStarted();
    event DartFlicked(address player, uint256 score);
    event PlayerWon(address winner, uint256 prize);
    event GameEnded(address winner);
    event GameDrawn(uint256 refundAmount);

    constructor(address _host, uint256 _targetScore, uint256 _maxRounds) {
        host = _host;
        TARGET_SCORE = _targetScore;
        MAX_ROUNDS = _maxRounds;
    }

    modifier onlyHost() {
        require(msg.sender == host, "Only the host can perform this action");
        _;
    }

    modifier gameInProgress() {
        require(gameStarted && !gameEnded, "Game not in progress");
        _;
    }

    receive() external payable {
        registerAndBet();
    }

    function registerAndBet() public payable {
        require(!gameStarted, "Game already started");
        require(
            players[0].addr == address(0) || players[1].addr == address(0),
            "Both players already registered"
        );
        require(msg.value > 0, "Bet amount must be greater than 0");

        uint256 playerIndex = players[0].addr == address(0) ? 0 : 1;
        players[playerIndex].addr = msg.sender;
        players[playerIndex].score = TARGET_SCORE;
        players[playerIndex].dartScores.push();
        players[playerIndex].bet = msg.value;
        prizePool += msg.value;

        emit PlayerRegistered(msg.sender, playerIndex);
        emit BetPlaced(msg.sender, msg.value);

        if (players[0].addr != address(0) && players[1].addr != address(0)) {
            require(players[0].bet == players[1].bet, "Bets must match");
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

        int256 playerCurrentScore = int256(players[currentPlayerIndex].score);

        // Update the player's score
        playerCurrentScore -= int256(score);

        // Record the individual dart score
        currentPlayer.dartScores[currentRound - 1].push(score);

        emit DartFlicked(player, score);

        // Handle bust scenario
        if (playerCurrentScore < 0) {
            // Bust, reset the round score
            currentPlayer.score =
                TARGET_SCORE -
                accumulateScore(currentPlayerIndex, currentRound - 1);
            switchPlayer();
            return;
        }

        currentPlayer.score = uint256(playerCurrentScore);

        if (currentPlayer.score == 0) {
            gameEnded = true;
            endGame(player);
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

    function endGame(address winner) internal {
        gameEnded = true;
        uint256 hostFee = prizePool / 100; // 1% fee
        uint256 winnerPrize = prizePool - hostFee;

        if (winner != address(0)) {
            payable(host).transfer(hostFee);
            payable(winner).transfer(winnerPrize);
            emit PlayerWon(winner, winnerPrize);
        } else {
            // In case of a draw, refund players
            uint256 refundAmount = prizePool / 2;
            payable(players[0].addr).transfer(refundAmount);
            payable(players[1].addr).transfer(refundAmount);
            emit GameDrawn(refundAmount);
        }

        emit GameEnded(winner);
    }

    function switchPlayer() internal {
        currentPlayerIndex = 1 - currentPlayerIndex;
        if (currentPlayerIndex == 0) {
            currentRound++;
            if (currentRound > MAX_ROUNDS) {
                if (players[0].score == players[1].score) {
                    endGame(address(0)); // Draw
                } else {
                    address winner = players[0].score < players[1].score
                        ? players[0].addr
                        : players[1].addr;
                    endGame(winner);
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
