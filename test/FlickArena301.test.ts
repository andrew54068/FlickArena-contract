import { expect } from "chai";
import { ethers } from "hardhat";
import { Contract } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

describe("FlickArena301", function () {
  let flickArena: Contract;
  let owner: SignerWithAddress;
  let player1: SignerWithAddress;
  let player2: SignerWithAddress;
  let player3: SignerWithAddress;

  beforeEach(async function () {
    [owner, player1, player2, player3] = await ethers.getSigners();
    const FlickArena301 = await ethers.getContractFactory("FlickArena301");
    flickArena = await FlickArena301.deploy();
    await flickArena.deployed();
  });

  describe("registerPlayer", function () {
    it("should allow two players to register", async function () {
      await expect(flickArena.connect(player1).registerPlayer())
        .to.emit(flickArena, "PlayerRegistered")
        .withArgs(player1.address, 0);

      await expect(flickArena.connect(player2).registerPlayer())
        .to.emit(flickArena, "PlayerRegistered")
        .withArgs(player2.address, 1);

      await expect(flickArena.connect(player2).registerPlayer())
        .to.be.revertedWith("Game already started");
    });

    it("should not allow more than two players", async function () {
      await flickArena.connect(player1).registerPlayer();
      await flickArena.connect(player2).registerPlayer();
      await expect(flickArena.connect(player3).registerPlayer())
        .to.be.revertedWith("Both players already registered");
    });

    it("should start the game when both players are registered", async function () {
      await flickArena.connect(player1).registerPlayer();
      await expect(flickArena.connect(player2).registerPlayer())
        .to.emit(flickArena, "GameStarted");
    });
  });

  describe("flickDart", function () {
    beforeEach(async function () {
      await flickArena.connect(player1).registerPlayer();
      await flickArena.connect(player2).registerPlayer();
    });

    it("should allow host to flick darts for players", async function () {
      await expect(flickArena.flickDart(20, player1.address))
        .to.emit(flickArena, "DartFlicked")
        .withArgs(player1.address, 20);
    });

    it("should not allow non-host to flick darts", async function () {
      await expect(flickArena.connect(player1).flickDart(20, player1.address))
        .to.be.revertedWith("Only the host can perform this action");
    });

    it("should not allow host to flick for non-registered players", async function () {
      await expect(flickArena.flickDart(20, player3.address))
        .to.be.revertedWith("Not the current player's turn");
    });

    it("should not allow out-of-turn flicks", async function () {
      await flickArena.flickDart(20, player1.address);
      await expect(flickArena.flickDart(20, player1.address))
        .to.be.revertedWith("Not the current player's turn");
    });

    it("should not allow invalid scores", async function () {
      await expect(flickArena.flickDart(61, player1.address))
        .to.be.revertedWith("Invalid score");
    });

    it("should handle busts correctly", async function () {
      await flickArena.flickDart(60, player1.address);
      await flickArena.flickDart(60, player1.address);
      await flickArena.flickDart(60, player1.address);
      await flickArena.flickDart(60, player2.address);
      await flickArena.flickDart(60, player2.address);
      await flickArena.flickDart(60, player2.address);
      await flickArena.flickDart(60, player1.address);
      expect(await flickArena.getCurrentScore(0)).to.equal(301);
    });

    it("should end the game when a player reaches 0", async function () {
      for (let i = 0; i < 5; i++) {
        await flickArena.flickDart(60, player1.address);
        await flickArena.flickDart(60, player2.address);
      }
      await expect(flickArena.flickDart(1, player1.address))
        .to.emit(flickArena, "PlayerWon")
        .withArgs(player1.address)
        .and.to.emit(flickArena, "GameEnded")
        .withArgs(player1.address);
    });

    it("should end the game after MAX_ROUNDS", async function () {
      for (let i = 0; i < 30; i++) {
        await flickArena.flickDart(1, player1.address);
        await flickArena.flickDart(1, player2.address);
      }
      await expect(flickArena.flickDart(1, player1.address))
        .to.emit(flickArena, "GameEnded");
    });

    it("should record individual dart scores for each round", async function () {
      await flickArena.flickDart(20, player1.address);
      await flickArena.flickDart(30, player1.address);
      await flickArena.flickDart(10, player1.address);
      
      let dartScores = await flickArena.getPlayerDartScores(0);
      expect(dartScores[0]).to.deep.equal([20, 30, 10]);
      
      await flickArena.flickDart(15, player2.address);
      await flickArena.flickDart(25, player2.address);
      await flickArena.flickDart(35, player2.address);
      
      dartScores = await flickArena.getPlayerDartScores(1);
      expect(dartScores[0]).to.deep.equal([15, 25, 35]);
    });

    it("should calculate round scores correctly", async function () {
      await flickArena.flickDart(20, player1.address);
      await flickArena.flickDart(30, player1.address);
      await flickArena.flickDart(10, player1.address);
      
      let roundScores = await flickArena.getPlayerRoundScores(0);
      expect(roundScores[0]).to.equal(60);
      
      await flickArena.flickDart(15, player2.address);
      await flickArena.flickDart(25, player2.address);
      await flickArena.flickDart(35, player2.address);
      
      roundScores = await flickArena.getPlayerRoundScores(1);
      expect(roundScores[0]).to.equal(75);
    });

    it("should handle busts correctly with individual dart scores", async function () {
      await flickArena.flickDart(60, player1.address);
      await flickArena.flickDart(60, player1.address);
      await flickArena.flickDart(60, player1.address);
      
      let dartScores = await flickArena.getPlayerDartScores(0);
      expect(dartScores[0]).to.deep.equal([]);
      expect(await flickArena.getCurrentScore(0)).to.equal(301);
      
      await flickArena.flickDart(50, player2.address);
      await flickArena.flickDart(50, player2.address);
      await flickArena.flickDart(50, player2.address);
      
      dartScores = await flickArena.getPlayerDartScores(1);
      expect(dartScores[0]).to.deep.equal([50, 50, 50]);
      expect(await flickArena.getCurrentScore(1)).to.equal(151);
    });

    it("should not allow invalid scores", async function () {
      await expect(flickArena.flickDart(61, player1.address))
        .to.be.revertedWith("Invalid score");
    });

    it("should end the game when a player reaches 0", async function () {
      for (let i = 0; i < 5; i++) {
        await flickArena.flickDart(60, player1.address);
        await flickArena.flickDart(60, player2.address);
      }
      await expect(flickArena.flickDart(1, player1.address))
        .to.emit(flickArena, "PlayerWon")
        .withArgs(player1.address)
        .and.to.emit(flickArena, "GameEnded")
        .withArgs(player1.address);
    });

    it("should end the game after MAX_ROUNDS", async function () {
      for (let i = 0; i < 30; i++) {
        await flickArena.flickDart(1, player1.address);
        await flickArena.flickDart(1, player2.address);
      }
      await expect(flickArena.flickDart(1, player1.address))
        .to.emit(flickArena, "GameEnded");
    });

    it("should end the game in a draw if both players have the same non-zero score after MAX_ROUNDS", async function () {
      // Both players score 1 point each round for 10 rounds
      for (let i = 0; i < 10; i++) {
        await flickArena.flickDart(1, player1.address);
        await flickArena.flickDart(1, player1.address);
        await flickArena.flickDart(1, player1.address);
        await flickArena.flickDart(1, player2.address);
        await flickArena.flickDart(1, player2.address);
        await flickArena.flickDart(1, player2.address);
      }

      // The 31st dart throw should end the game in a draw
      await expect(flickArena.flickDart(1, player1.address))
        .to.emit(flickArena, "GameDrawn")
        .and.to.emit(flickArena, "GameEnded")
        .withArgs(ethers.constants.AddressZero);  // AddressZero indicates a draw

      expect(await flickArena.getCurrentScore(0)).to.equal(271);  // 301 - (1 * 30) = 271
      expect(await flickArena.getCurrentScore(1)).to.equal(271);  // 301 - (1 * 30) = 271
    });
  });

  describe("View functions", function () {
    beforeEach(async function () {
      await flickArena.connect(player1).registerPlayer();
      await flickArena.connect(player2).registerPlayer();
      await flickArena.connect(player1).flickDart(20);
    });

    it("should return correct players", async function () {
      const players = await flickArena.getPlayers();
      expect(players[0]).to.equal(player1.address);
      expect(players[1]).to.equal(player2.address);
    });

    it("should return correct current player", async function () {
      expect(await flickArena.getCurrentPlayer()).to.equal(player2.address);
    });

    it("should return correct player scores", async function () {
      const scores = await flickArena.getPlayerScores(0);
      expect(scores[0]).to.equal(20);
    });

    it("should return correct current score", async function () {
      expect(await flickArena.getCurrentScore(0)).to.equal(281);
      expect(await flickArena.getCurrentScore(1)).to.equal(301);
    });

    it("should return correct player dart scores", async function () {
      await flickArena.flickDart(20, player1.address);
      await flickArena.flickDart(30, player1.address);
      await flickArena.flickDart(10, player1.address);
      
      const dartScores = await flickArena.getPlayerDartScores(0);
      expect(dartScores[0]).to.deep.equal([20, 30, 10]);
    });

    it("should return correct player round scores", async function () {
      await flickArena.flickDart(20, player1.address);
      await flickArena.flickDart(30, player1.address);
      await flickArena.flickDart(10, player1.address);
      
      const roundScores = await flickArena.getPlayerRoundScores(0);
      expect(roundScores[0]).to.equal(60);
    });

    it("should revert for invalid player index", async function () {
      await expect(flickArena.getPlayerScores(2)).to.be.revertedWith("Invalid player index");
      await expect(flickArena.getCurrentScore(2)).to.be.revertedWith("Invalid player index");
    });
  });
});