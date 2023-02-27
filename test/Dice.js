// 引入 Chai 库，用于断言
const { expect } = require("chai");

// 定义 DiceGame 合约测试套件
describe("DiceGame", function () {
  // 定义一个空的玩家地址，用于测试
  const emptyAddress = "0x0000000000000000000000000000000000000000";

  // 声明全局变量
  let diceGame;
  let player1;
  let player2;
  let player1BetNum;
  let player2BetNum;

  // 在每个测试用例之前部署新的 DiceGame 合约
  beforeEach(async function () {
    const DiceGame = await ethers.getContractFactory("DiceGameLobby");
    diceGame = await DiceGame.deploy();
    await diceGame.deployed();

    // 创建两个测试用的玩家地址
    [player1, player2] = await ethers.getSigners();
    player1BetNum = 1;
    player2BetNum = 6;
  });

  // 测试 createGame 函数
  it("should allow players to create and play the game", async function () {
    // 玩家 1 加入游戏
    await diceGame.createGame(player1BetNum, { value: ethers.utils.parseEther("1") });
    const game = (await diceGame.getGames())[0];
    expect(game.player1).to.equal(player1.address);
    expect(game.player1BetNumber).to.equal(player1BetNum);

    // 玩家 2 加入游戏
    await diceGame
      .connect(player2)
      .play(game.id, player2BetNum, { value: ethers.utils.parseEther("1") });
    const gameAfterPlay = (await diceGame.getGames())[0];
    expect(gameAfterPlay.player2).to.equal(player2.address);
  });
//
//  // 测试 rollDice 函数
//  it("should allow players to roll the dice", async function () {
//    // 玩家 1 和玩家 2 加入游戏
//    await diceGame.joinGame({ value: ethers.utils.parseEther("1") });
//    await diceGame
//      .connect(player2)
//      .joinGame({ value: ethers.utils.parseEther("1") });
//
//    // 玩家 1 和玩家 2 分别掷骰子
//    await diceGame.rollDice();
//    await diceGame.connect(player2).rollDice();
//
//    // 检查游戏是否结束
//    expect(await diceGame.gameFinished()).to.equal(true);
//
//    // 检查胜者地址是否有效
//    const winner = await diceGame.determineWinner();
//    expect(winner).to.not.equal(emptyAddress);
//  });
//
//  // 测试 payout 函数
//  it("should allow the winner to withdraw their winnings", async function () {
//    // 玩家 1 和玩家 2 加入游戏
//    await diceGame.joinGame({ value: ethers.utils.parseEther("1") });
//    await diceGame
//      .connect(player2)
//      .joinGame({ value: ethers.utils.parseEther("1") });
//
//    // 玩家 1 和玩家 2 分别掷骰子
//    await diceGame.rollDice();
//    await diceGame.connect(player2).rollDice();
//
//    // 确定胜者并进行付款
//    const winner = await diceGame.determineWinner();
//    await expect(() => diceGame.payout()).to.changeEtherBalance(
//      winner,
//      ethers.utils.parseEther("2")
//    );
//  });
});

// // 定义 DiceGameLobby 合约测试套件
// describe("DiceGameLobby", function () {
//   // 声明全局变量
