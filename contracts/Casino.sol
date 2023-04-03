// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.18 <0.9.0;
import "hardhat/console.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

import "./BankRoll.sol";
import "./Game.sol";
import "./GameDice.sol";
import "./GameRockPaperScissors.sol";

// TODO: gameType to enum

uint32 constant MUMBAI_CALLBACK_GAS_LIMIT = 2500000;
uint32 constant MUMBAI_NUM_WORDS = 1;
uint16 constant REQUEST_CONFIRMATIONS = 3;
uint64 constant SUBSCRIPTION_ID = 3873; // g - 10593; mumbai - 3873;
bytes32 constant MUMBAI_KEY_HASH = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f; // Mumbai 500 gwei

contract Casino is VRFConsumerBaseV2 {
    IBankRoll private bankRoll;
    mapping(address => Game) private activeGameMap;
    mapping(address => Game) private finishedGameMap;
    mapping(uint256 => address) private vrfRequestIdGameMap;
    address[] private games;
    address[] private finishedGames;
    address private owner;

    VRFCoordinatorV2Interface vrfCoordinatorV2;
    bytes32 KEY_HASH;
    uint64 SUB_ID;
    uint16 MINIMUM_REQUEST_CONFIRMATIONS;
    uint32 CALLBACK_GAS_LIMIT;
    uint32 NUM_WORDS;

    // constructor(
    //     bytes32 keyHash,
    //     uint64 subId,
    //     uint16 minimumRequestConfirmations,
    //     uint32 callbackGasLimit,
    //     uint32 numWords,
    //     address VRFCoordinatorV2InterfaceAddress
    // ) VRFConsumerBaseV2(VRFCoordinatorV2InterfaceAddress) {
    constructor()
        VRFConsumerBaseV2(0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed)
    {
        vrfCoordinatorV2 = VRFCoordinatorV2Interface(
            0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed
        );
        KEY_HASH = MUMBAI_KEY_HASH;
        SUB_ID = SUBSCRIPTION_ID;
        MINIMUM_REQUEST_CONFIRMATIONS = REQUEST_CONFIRMATIONS;
        CALLBACK_GAS_LIMIT = MUMBAI_CALLBACK_GAS_LIMIT;
        NUM_WORDS = MUMBAI_NUM_WORDS;

        owner = msg.sender;
        bankRoll = new BankRoll();
        bankRoll.init(msg.sender);
    }

    event CreateGame_Event(DisplayInfo game);
    event CompleteGame_Event(address winner);
    event RandomRequestTest_Event(uint256 requestId);
    event RandomResultTest_Event(uint256 requestId, uint256[] randomWords);

    // 游戏创建
    // 用户创建游戏，等待另一个玩家加入
    // @Params gameType 用户选择的游戏
    // @Params choice 用户的选项，如 ROCK-PAPER-SCISSORS 游戏中，选择的是 ROCK，PAPER，还是 SCISSORS，用数字表示
    function createGame(uint256 gameType, uint256 choice) public payable {
        require(gameType > 0, "VALID_GAME");
        require(gameType < 4, "VALID_GAME");
        require(msg.value > 0, "NEED_ETH");
        console.log("owner: ", owner);

        // 先付钱
        bankRoll.income{value: msg.value}();

        // 创建游戏
        Game game;
        // TODO: Contract size 超出限制了，需要处理一下
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

        emit CreateGame_Event(game.getDisplayInfo());
    }

    function requestRandom(address gameAddress) public {
        uint256 requestId = vrfCoordinatorV2.requestRandomWords(
            KEY_HASH,
            SUB_ID,
            MINIMUM_REQUEST_CONFIRMATIONS,
            CALLBACK_GAS_LIMIT,
            NUM_WORDS
        );

        emit RandomRequestTest_Event(requestId);
        vrfRequestIdGameMap[requestId] = gameAddress;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        emit RandomResultTest_Event(_requestId, _randomWords);
        Game game = activeGameMap[vrfRequestIdGameMap[_requestId]];
        address winner = game.play(address(bankRoll), _randomWords);
        emit CompleteGame_Event(winner);
    }

    // 游戏开始
    // @Params targetGame 用户想要加入的游戏的地址
    // @Params choice 用户的选项，如 ROCK-PAPER-SCISSORS 游戏中，选择的是 ROCK，PAPER，还是 SCISSORS，用数字表示
    function playGame(address targetGame, uint256 choice) public payable {
        require(msg.value > 0, "NEED_WAGER");
        // 找到游戏
        Game game = activeGameMap[targetGame];
        // 游戏非 active 状态，revert
        if (address(game) == address(0)) {
            revert("GAME_FINISHED");
        }

        // 先付钱
        require(msg.value >= game.getWager(), "NEED_MORE");
        bankRoll.income{value: msg.value}();

        // 加入游戏
        game.join(msg.sender, choice);

        if (game.gameType() == DICE_GAME_TYPE) {
            // 游戏启动
            requestRandom(targetGame);
        } else {
            // 游戏启动
            address winner = game.play(address(bankRoll));

            //  游戏结束，删除游戏
            finishedGameMap[targetGame] = game;
            finishedGames.push(targetGame);
            delete activeGameMap[targetGame];

            emit CompleteGame_Event(winner);
        }
    }

    // 获取游戏列表
    // @returns array< DisplayInfo >, 如果游戏已经结束，则 address 为 address(0)
    function getGames() public view returns (DisplayInfo[] memory) {
        DisplayInfo[] memory allGames = new DisplayInfo[](games.length);
        for (uint256 i = 0; i < games.length; i++) {
            Game activeGame = activeGameMap[games[i]];
            Game finishedGame = finishedGameMap[games[i]];

            if (address(activeGame) == address(0)) {
                allGames[i] = finishedGame.getDisplayInfo();
            } else {
                allGames[i] = activeGame.getDisplayInfo();
            }
        }
        return allGames;
    }

    // 获取游戏列表
    // @returns array< DisplayInfo >
    function getActiveGames() public view returns (DisplayInfo[] memory) {
        DisplayInfo[] memory activeGames = new DisplayInfo[](
            games.length - finishedGames.length
        );
        for (uint256 i = 0; i < games.length; i++) {
            Game game = activeGameMap[games[i]];
            // 游戏状态为 active，则返回游戏数据
            if (address(game) != address(0)) {
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
        Game finishedGame = finishedGameMap[targetGame];

        if (address(activeGame) == address(0)) {
            return finishedGame.getDisplayInfo();
        } else {
            return activeGame.getDisplayInfo();
        }
    }
}
