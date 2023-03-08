// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.18 <0.9.0;
import "hardhat/console.sol";

uint256 constant DEFAULT_BET = 0; // 保留值

interface IBankRoll {
    function income() external payable;

    function payout(address payable target, uint256 balance) external;

    function withdraw() external;

    function showBalance() external view returns (uint256);
}

struct Gambler {
    address id;
    uint256 bet;
}

// 这个 DisplayInfo 为了展示用，否则返回的是 address，
// 设计不太好，后面再想想
struct DisplayInfo {
    address id;
    uint256 wager;
    string gameType;
    Gambler[] gamblers;
}

contract BankRoll is IBankRoll {
    // TODO owner

    function income() public payable {
        console.log("BankRoll income: ", msg.value);
        console.log("BankRoll current balance: ", address(this).balance);
    }

    function payout(address payable _sendTo, uint256 balance) public {
        (bool success, ) = _sendTo.call{value: balance}("");
        console.log("BankRoll payout: ", balance, ", to: ", _sendTo);
        console.log("BankRoll current balance: ", address(this).balance);
        require(success, "PAYOUT_FAILED");
    }

    function withdraw() public {
        payable(msg.sender).transfer(address(this).balance);
    }

    function showBalance() public view returns (uint256) {
        return address(this).balance;
    }
}

abstract contract CasinoGame {
    string public gameType;
    uint256 public wager;
    Gambler[] public gamblers;

    event JoinGame_Event(CasinoGame game);
    event PlayGame_Event(address winner);

    function init(uint256 customizeWager) public virtual {
        wager = customizeWager;
    }

    // 玩家加入游戏
    function join(address gamblerAddress, uint256 bet) public payable {
        // require(wager > 0, 'INTERNAL_INIT');
        // require(wager == msg.value, 'WAGER_INVALID');

        console.log("join bet: ", bet);
        Gambler memory gambler = Gambler({id: gamblerAddress, bet: bet});

        gamblers.push(gambler);
        emit JoinGame_Event(this);
    }

    //  抽水，默认 10%
    function customizeVigorish() public view returns (uint256) {
        require(wager > 0, "INTERNAL_INIT");
        return (wager * 10) / 100;
    }

    // 游戏结果以及支付彩头
    function play(address _bankRoll) public {
        (address winner, address loser) = getWinnerAndLoser();

        IBankRoll bankRoll = IBankRoll(_bankRoll);
        uint256 refund = wager - customizeVigorish();
        if (winner == loser) {
            bankRoll.payout(payable(winner), refund);
            bankRoll.payout(payable(loser), refund);
        } else {
            bankRoll.payout(payable(winner), refund);
        }
        emit PlayGame_Event(winner);
    }

    function getWager() public view returns (uint256) {
        return wager;
    }

    // 需要具体 游戏SmartContract 实现的游戏输赢规则
    function getWinnerAndLoser() public virtual returns (address, address);

    function getDisplayInfo() public view virtual returns (DisplayInfo memory);
}

contract RockPaperScissors is CasinoGame {
    // 石头剪刀布游戏
    // 选项: ROCK: 1; PAPER: 2; SCISSORS: 3;
    function init(uint256 customizeWager) public override {
        super.init(customizeWager);
        gameType = "ROCK_PAPER_SCISSORS";
    }

    function getWinnerAndLoser()
        public
        view
        override
        returns (address, address)
    {
        require(gamblers.length == 2, "NEED_TWO_PLAYER");
        Gambler memory gamblerA = gamblers[0];
        Gambler memory gamblerB = gamblers[1];

        if (gamblerA.bet == gamblerB.bet) {
            return (address(0), address(0));
        }

        bool gamblerBIsWinner = false;
        if (gamblerA.bet == 1) {
            gamblerBIsWinner = gamblerB.bet == 2;
        } else if (gamblerA.bet == 2) {
            gamblerBIsWinner = gamblerB.bet == 3;
        } else if (gamblerA.bet == 3) {
            gamblerBIsWinner = gamblerB.bet == 1;
        }

        return
            gamblerBIsWinner
                ? (gamblerB.id, gamblerA.id)
                : (gamblerA.id, gamblerB.id);
    }

    function getDisplayInfo()
        public
        view
        override
        returns (DisplayInfo memory)
    {
        Gambler[] memory displayGamblers = new Gambler[](gamblers.length);
        for (uint8 i = 0; i < gamblers.length; i++) {
            // 游戏已经完成，返回所有的数据
            // 游戏未完成，用户选择隐藏
            if (gamblers.length == 2) {
                displayGamblers[i] = gamblers[i];
            } else {
                displayGamblers[i] = Gambler({
                    id: gamblers[i].id,
                    bet: DEFAULT_BET
                });
            }
        }
        return
            DisplayInfo({
                id: address(this),
                wager: wager,
                gameType: gameType,
                gamblers: displayGamblers
            });
    }
}

contract Casino {
    IBankRoll private bankRoll;
    mapping(address => CasinoGame) private activeGameMap;
    address[] private games;

    constructor() {
        bankRoll = new BankRoll();
    }

    // 游戏创建
    // 用户创建游戏，等待另一个玩家加入
    // @Params bet 用户的选项，如 ROCK-PAPER-SCISSORS 游戏中，选择的是 ROCK，PAPER，还是 SCISSORS，用数字表示
    function createGame(uint256 bet) public payable {
        require(msg.value > 0, "NEED_ETH");

        // 先付钱
        bankRoll.income{value: msg.value}();

        // 创建游戏
        CasinoGame game;
        game = new RockPaperScissors();
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
        CasinoGame game = activeGameMap[targetGame];

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
            CasinoGame game = activeGameMap[games[i]];
            allGames[i] = game.getDisplayInfo();
        }
        return allGames;
    }
}
