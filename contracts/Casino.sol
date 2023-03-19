// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.18 <0.9.0;
import "hardhat/console.sol";

import "./BankRoll.sol";
import "./Game.sol";
import "./GameDice.sol";
import "./GameRockPaperScissors.sol";

// TODO: chainlink VRF
// TODO: gameType to enum

contract Casino {
    IBankRoll private bankRoll;
    mapping(address => Game) private activeGameMap;
    mapping(address => Game) private finishedGameMap;
    address[] private games;
    address[] private finishedGames;
    address private owner;
    function init() public {
        owner = msg.sender;
        bankRoll = new BankRoll();
        bankRoll.init(msg.sender);
    }
    
    // 游戏创建
    // 用户创建游戏，等待另一个玩家加入
    // @Params gameType 用户选择的游戏
    // @Params choice 用户的选项，如 ROCK-PAPER-SCISSORS 游戏中，选择的是 ROCK，PAPER，还是 SCISSORS，用数字表示
    function createGame(uint256 gameType, uint256 choice) public payable {
        require(gameType > 0, "VALID_GAME");
        require(gameType < 3, "VALID_GAME");
        require(msg.value > 0, "NEED_ETH");
        console.log('owner: ', owner);

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
        game.join(msg.sender, choice);

        address gameAddress = address(game);
        activeGameMap[gameAddress] = game;
        games.push(gameAddress);
    }

    // 游戏开始
    // @Params targetGame 用户想要加入的游戏的地址
    // @Params choice 用户的选项，如 ROCK-PAPER-SCISSORS 游戏中，选择的是 ROCK，PAPER，还是 SCISSORS，用数字表示
    function playGame(address targetGame, uint256 choice) public payable {
        require(msg.value > 0, "NEED_WAGER");
        // 找到游戏
        Game game = activeGameMap[targetGame];
        // 游戏非 active 状态，revert
        if(address(game) == address(0)) {
            revert("GAME_FINISHED");
        }

        // 先付钱
        require(msg.value >= game.getWager(), "NEED_MORE");
        bankRoll.income{value: msg.value}();

        // 加入游戏
        game.join(msg.sender, choice);
        // 游戏启动
        game.play(address(bankRoll));

        //  游戏结束，删除游戏
        finishedGameMap[targetGame] = game;
        finishedGames.push(targetGame);
        delete activeGameMap[targetGame];
    }

    // 获取游戏列表
    // @returns array< DisplayInfo >, 如果游戏已经结束，则 address 为 address(0)
    function getGames() public view returns (DisplayInfo[] memory) {
        DisplayInfo[] memory allGames = new DisplayInfo[](games.length);
        for (uint256 i = 0; i < games.length; i++) {
            Game activeGame = activeGameMap[games[i]];
            Game finishedGame = finishedGame[games[i]];
            
            if(address(game) == address(0)) {
                allGames[i] = finishedGame.getDisplayInfo();
            } else {
                allGames[i] = activeGameMap.getDisplayInfo();
            }
        }
        return allGames;
    }
    
    // 获取游戏列表
    // @returns array< DisplayInfo >
    function getActiveGames() public view returns (DisplayInfo[] memory) {
        DisplayInfo[] memory activeGames = new DisplayInfo[](games.length - finishedGames.length);
        for (uint256 i = 0; i < games.length; i++) {
            Game game = activeGameMap[games[i]];
            // 游戏状态为 active，则返回游戏数据
            if(address(game) != address(0)) {
                activeGames[i] = game.getDisplayInfo();
            }
        }
        return activeGames;
    }

    // 获取游戏
    // @returns array< DisplayInfo >
    function getGame(
        address targetGame
    ) public view returns (DisplayInfo memory) {
        Game activeGame = activeGameMap[targetGame];
        Game finishedGame = finishedGame[targetGame];
        
        if(address(game) == address(0)) {
            return finishedGame.getDisplayInfo();
        } else {
            return activeGame.getDisplayInfo();
        }
    }
}
