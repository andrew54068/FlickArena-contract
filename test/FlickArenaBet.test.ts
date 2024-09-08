import { expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { FlickArenaBet, FlickArenaBetFactory } from "../typechain-types";
import { parseEther } from "ethers";

describe("FlickArenaBet", function () {
  let game: FlickArenaBet;
  let factory: FlickArenaBetFactory;
  let host: SignerWithAddress;
  let player1: SignerWithAddress;
  let player2: SignerWithAddress;
  const TARGET_SCORE = 301;
  const MAX_ROUNDS = 10;
  const BET_AMOUNT = parseEther("1");

  beforeEach(async function () {
    // @ts-ignore
    [host, player2] = await ethers.getSigners();
    player1 = host;

    const FlickArenaBetFactory = await ethers.getContractFactory(
      "FlickArenaBetFactory"
    );
    factory = await FlickArenaBetFactory.deploy();
    await factory.waitForDeployment();

    // call createGame function with eth value
    const tx = await factory
      .connect(host)
      .createGame(TARGET_SCORE, MAX_ROUNDS, { value: BET_AMOUNT });
    // @ts-ignore
    const receipt = await tx.wait();

    const event = receipt.logs.find(
      (log: any) => log.eventName === "GameCreated"
    );
    const gameAddress = event?.args?.gameAddress;

    game = (await ethers.getContractAt(
      "FlickArenaBet",
      gameAddress
    )) as FlickArenaBet;
  });

  it("Should create game correctly", async function () {
    expect(await game.host()).to.equal(host.address);
    expect(await game.TARGET_SCORE()).to.equal(TARGET_SCORE);
    expect(await game.MAX_ROUNDS()).to.equal(MAX_ROUNDS);
  });

  it("Fist player should have registed", async function () {
    expect(await game.prizePool()).to.equal(BET_AMOUNT);
    expect(await game.gameStarted()).to.be.false;
  });

  it("Should allow players to register and bet", async function () {
    await game.connect(player2).registerAndBet({ value: BET_AMOUNT });

    expect(await game.prizePool()).to.equal(BET_AMOUNT * 2n);
    expect(await game.gameStarted()).to.be.true;
  });

  it("Should allow players to register and bet using receive function", async function () {
    await player2.sendTransaction({
      to: await game.getAddress(),
      value: BET_AMOUNT,
    });

    expect(await game.prizePool()).to.equal(BET_AMOUNT * 2n);
    expect(await game.gameStarted()).to.be.true;
    expect((await game.players(0)).score).to.equal(TARGET_SCORE);
  });

  it("Should allow host to flick dart", async function () {
    await setupGame();

    await game.connect(host).flickDart(20, player1.address);

    expect(await game.getCurrentScore(0)).to.equal(TARGET_SCORE - 20);
  });

  it("Should calculate the score correctly", async function () {
    await setupGame();

    await game.connect(host).flickDart(20, player1.address);

    expect(await game.getCurrentScore(0)).to.equal(TARGET_SCORE - 20);
  });

  it("Should calculate the score correctly after one round", async function () {
    await setupGame();

    for (let i = 0; i < 3; i++) {
      await game.connect(host).flickDart(20, player1.address);
    }

    await game.connect(host).flickDart(20, player2.address);

    expect(await game.getCurrentScore(0)).to.equal(TARGET_SCORE - 60);
    expect(await game.getCurrentScore(1)).to.equal(TARGET_SCORE - 20);
  });

  it("Should only allow player to flick dart three in a row", async function () {
    await setupGame();

    await game.connect(host).flickDart(20, player1.address);
    await game.connect(host).flickDart(20, player1.address);
    await game.connect(host).flickDart(20, player1.address);
    await game.connect(host).flickDart(1, player1.address);

    await expect(
      game.connect(host).flickDart(1, player1.address)
    ).to.be.revertedWith("Already thrown 3 darts");
  });

  it("Should end game when a player wins", async function () {
    await setupGame();

    const MAX_DARTS_PER_TURN = await game.MAX_DARTS_PER_TURN();

    for (let i = 0; i < MAX_ROUNDS - 1; i++) {
      for (let j = 0; j < MAX_DARTS_PER_TURN; j++) {
        await game.connect(host).flickDart(10, player1.address);
      }
      for (let j = 0; j < MAX_DARTS_PER_TURN; j++) {
        await game.connect(host).flickDart(10, player2.address);
      }
    }
    expect(await game.getCurrentScore(0)).to.equal(TARGET_SCORE - 270);
    expect(await game.getCurrentScore(1)).to.equal(TARGET_SCORE - 270);

    expect(await game.gameEnded()).to.be.false;

    const tx = await game.connect(host).flickDart(31, player1.address);

    // @ts-ignore
    const receipt = await tx.wait();

    const event = receipt.logs.find(
      (log: any) => log.eventName === "PlayerWon"
    );
    const winner = event?.args?.winner;
    const prize = event?.args?.prize;

    expect(await game.gameEnded()).to.be.true;
    expect(winner).to.equal(player1.address);
    expect(prize).to.equal((BET_AMOUNT * 2n * 99n) / 100n);
  });

  it("Should end game in a draw when max rounds are reached", async function () {
    await setupGame();

    for (let i = 0; i < MAX_ROUNDS * 3 * 2 - 1; i++) {
      await game
        .connect(host)
        .flickDart(1, i % 2 === 0 ? player1.address : player2.address);
    }
    const currentRound = await game.currentRound();

    expect(currentRound).to.equal(MAX_ROUNDS);

    const tx = await game.connect(host).flickDart(1, player2.address);

    const currentRound2 = await game.currentRound();

    expect(currentRound2).to.equal(MAX_ROUNDS + 1);
    // @ts-ignore
    const receipt = await tx.wait();

    const event = receipt.logs.find(
      (log: any) => log.eventName === "GameEnded"
    );

    const winner = event?.args?.winner;

    expect(winner).to.equal(ethers.ZeroAddress);

    const drawnEvent = receipt.logs.find(
      (log: any) => log.eventName === "GameDrawn"
    );
    const refundAmount = drawnEvent?.args?.refundAmount;
    expect(refundAmount).to.equal(BET_AMOUNT);

    expect(await game.gameEnded()).to.be.true;
  });

  it("Should handle bust scenario correctly", async function () {
    await setupGame();

    const MAX_DARTS_PER_TURN = await game.MAX_DARTS_PER_TURN();

    for (let i = 0; i < MAX_ROUNDS - 1; i++) {
      for (let j = 0; j < MAX_DARTS_PER_TURN; j++) {
        await game.connect(host).flickDart(10, player1.address);
      }
      for (let j = 0; j < MAX_DARTS_PER_TURN; j++) {
        await game.connect(host).flickDart(10, player2.address);
      }
    }

    expect(await game.getCurrentScore(0)).to.equal(TARGET_SCORE - 270);

    await game.connect(host).flickDart(32, player1.address);

    expect(await game.getCurrentScore(0)).to.equal(TARGET_SCORE - 270);
  });

  it("Should only allow host to flick dart", async function () {
    await setupGame();

    await expect(
      game.connect(player2).flickDart(20, player2.address)
    ).to.be.revertedWith("Only the host can perform this action");
  });

  async function setupGame() {
    await game.connect(player2).registerAndBet({ value: BET_AMOUNT });
  }
});
