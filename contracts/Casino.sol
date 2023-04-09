// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.18 <0.9.0;
import "hardhat/console.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

import "./BankRoll.sol";
import "./GameDice.sol";
import "./GameRockPaperScissors.sol";
// TODO: gameType to enum

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
    
    constructor(
        bytes32 keyHash,
        uint64 subId,
        uint16 minimumRequestConfirmations,
        uint32 callbackGasLimit,
        uint32 numWords,
        address VRFCoordinatorV2InterfaceAddress
    ) VRFConsumerBaseV2(VRFCoordinatorV2InterfaceAddress) {
        vrfCoordinatorV2 = VRFCoordinatorV2Interface(VRFCoordinatorV2InterfaceAddress);
        KEY_HASH = keyHash;
        SUB_ID = subId;
        MINIMUM_REQUEST_CONFIRMATIONS = minimumRequestConfirmations;
        CALLBACK_GAS_LIMIT = callbackGasLimit;
        NUM_WORDS = numWords;
        owner = msg.sender;
        bankRoll = new BankRoll();
        bankRoll.init(msg.sender);
    }

    event CreateGame_Event(DisplayInfo game);
    event CompleteGame_Event(address game, address winner);
    event VrfRequest_Event(address game, uint256 requestId);
    event VrfResponse_Event(uint256 requestId, uint256[] randomWords);

    // 游戏创建
    // 用户创建游戏，等待另一个玩家加入
    // @Params gameType 用户选择的游戏
    // @Params choice 用户的选项，如 ROCK-PAPER-SCISSORS 游戏中，选择的是 ROCK，PAPER，还是 SCISSORS，用数字表示
    function createGame(uint256 gameType, uint256 choice) public payable {
        require(msg.value > 0, "NEED_WAGER");
        // 先付钱
        bankRoll.gameIncome{value: msg.value}(msg.sender);
        Game game = _createGame(gameType, msg.value, msg.sender);
        game.join(msg.sender, choice);
        emit CreateGame_Event(game.getDisplayInfo());
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
        bankRoll.gameIncome{value: msg.value}(msg.sender);
        // 加入游戏
        game.join(msg.sender, choice);

        _playGame(game);
    }
    
    function _createGame(uint256 _gameType, uint256 _wager, address _host) private returns (Game) {
        require(_gameType > 0, "VALID_GAME");
        require(_gameType < 3, "VALID_GAME");
        
        // 创建游戏
        Game game;
        if (_gameType == DICE_GAME_TYPE) {
            game = new Dice(DICE_GAME_TYPE, _host, _wager);
        }
        if (_gameType == ROCK_PAPER_SCISSORS_GAME_TYPE) {
            game = new RockPaperScissors(ROCK_PAPER_SCISSORS_GAME_TYPE, _host, _wager);
        }

        address gameAddress = address(game);
        activeGameMap[gameAddress] = game;
        games.push(gameAddress);

        return game;
    }
    
    function _playGame(Game game) private {
        address targetGame = address(game);
        // 游戏启动
        if (game.gameType() != DICE_GAME_TYPE && !game.isDefaultHost() ) {
            address winner = game.play(address(bankRoll));
    
            //  游戏结束，删除游戏
            finishedGameMap[targetGame] = game;
            finishedGames.push(targetGame);
            delete activeGameMap[targetGame];
            emit CompleteGame_Event(targetGame, winner);
        } else {
            requestRandom(targetGame);
        }
    }
    
    // 游戏创建
    // 用户创建游戏并与 Host 开始玩
    // @Params gameType 用户选择的游戏
    // @Params choice 用户的选项，如 ROCK-PAPER-SCISSORS 游戏中，选择的是 ROCK，PAPER，还是 SCISSORS，用数字表示
    function playGameWithDefaultHost(uint256 gameType, uint256 choice) public payable {
        require(msg.value > 0, "NEED_WAGER");
        // 先付钱
        bankRoll.gameIncome{value: msg.value}(msg.sender);
        // 创建游戏
        Game game = _createGame(gameType, msg.value, DEFAULT_GAME_HOST);
        emit CreateGame_Event(game.getDisplayInfo());
    
        // 加入游戏
        game.join(msg.sender, choice);
        _playGame(game);
    }

    function requestRandom(address gameAddress) public {
        uint256 requestId = vrfCoordinatorV2.requestRandomWords(
            KEY_HASH,
            SUB_ID,
            MINIMUM_REQUEST_CONFIRMATIONS,
            CALLBACK_GAS_LIMIT,
            NUM_WORDS
        );

        emit VrfRequest_Event(gameAddress, requestId);
        vrfRequestIdGameMap[requestId] = gameAddress;
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        emit VrfResponse_Event(_requestId, _randomWords);
        Game game = activeGameMap[vrfRequestIdGameMap[_requestId]];
        address winner = game.play(address(bankRoll), _randomWords);
        
        //  游戏结束，删除游戏
        address targetGame = address(game);
        finishedGameMap[targetGame] = game;
        finishedGames.push(targetGame);
        delete activeGameMap[targetGame];
        emit CompleteGame_Event(targetGame, winner);
    }

    // 获取游戏列表
    // @returns array< DisplayInfo >
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
    function getGame(address targetGame) public view returns (DisplayInfo memory) {
        Game activeGame = activeGameMap[targetGame];
        Game finishedGame = finishedGameMap[targetGame];

        if (address(activeGame) == address(0)) {
            return finishedGame.getDisplayInfo();
        } else {
            return activeGame.getDisplayInfo();
        }
    }
    
    /*  ************ BANKROLL ************  */
    // BANKROLL 取现
    function bankrollWithdraw() public {
        bankRoll.withdraw();
    }
    // BANKROLL 充值
    function bankrollDeposit() public payable {
        bankRoll.deposit{value: msg.value}();
    }
    // BANKROLL 记录
    function bankrollGetTransactionRecords() public view returns (Record[] memory){
        return bankRoll.getAllRecords();
    }
}
