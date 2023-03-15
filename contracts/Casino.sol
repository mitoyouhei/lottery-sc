// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.18 <0.9.0;
import "hardhat/console.sol";

import "./BankRoll.sol";
import "./Game.sol";

// TODO: chainlink VRF
// TODO: gameType to enum
// TODO: withDraw

contract Casino {
    IBankRoll private bankRoll;
    mapping(address => Game) private activeGameMap;
    address[] private games;

    function init() public {
        bankRoll = new BankRoll();
    }

    // 游戏创建
    // 用户创建游戏，等待另一个玩家加入
    // @Params gameType 用户选择的游戏
    // @Params bet 用户的选项，如 ROCK-PAPER-SCISSORS 游戏中，选择的是 ROCK，PAPER，还是 SCISSORS，用数字表示
    function createGame(uint256 gameType, uint256 bet) public payable {
        require(gameType > 0, "VALID_GAME");
        require(gameType < 3, "VALID_GAME");
        require(msg.value > 0, "NEED_ETH");

        // 先付钱
        bankRoll.income{value: msg.value}();

        // 创建游戏
        Game game;
        if (gameType == DICE_GAME_TYPE) {
            game = new Dice();
        }
        if (gameType == ROCK_PAPER_SCISSORS_GAME_TYPE) {
            game = new RockPaperScissors();
        }

        game.init(msg.value);
        // 加入游戏
        game.join(msg.sender, bet);

        address gameAddress = address(game);
        activeGameMap[gameAddress] = game;
        games.push(gameAddress);
    }

    // 游戏开始
    // @Params targetGame 用户想要加入的游戏的地址
    // @Params bet 用户的选项，如 ROCK-PAPER-SCISSORS 游戏中，选择的是 ROCK，PAPER，还是 SCISSORS，用数字表示
    function playGame(address targetGame, uint256 bet) public payable {
        require(msg.value > 0, "NEED_WAGER");
        // 找到游戏
        Game game = activeGameMap[targetGame];

        // 先付钱
        require(msg.value >= game.getWager(), "NEED_MORE");
        bankRoll.income{value: msg.value}();

        // 加入游戏
        game.join(msg.sender, bet);
        // 游戏启动
        game.play(address(bankRoll));

        //　TODO
        //  游戏结束，删除游戏
        // delete activeGameMap[address(game)];
    }

    // 获取游戏列表
    // @returns array< DisplayInfo >
    function getGames() public view returns (DisplayInfo[] memory) {
        DisplayInfo[] memory allGames = new DisplayInfo[](games.length);
        for (uint256 i = 0; i < games.length; i++) {
            Game game = activeGameMap[games[i]];
            allGames[i] = game.getDisplayInfo();
        }
        return allGames;
    }

    // 获取游戏
    // @returns array< DisplayInfo >
    function getGame(
        address targetGame
    ) public view returns (DisplayInfo memory) {
        Game game = activeGameMap[targetGame];
        return game.getDisplayInfo();
    }
}
