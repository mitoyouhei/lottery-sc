// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.18 <0.9.0;
import "hardhat/console.sol";

import "./BankRoll.sol";

uint256 constant DEFAULT_BET = 0; // 保留值

uint256 constant DICE_GAME_TYPE = 1; // 掷骰子
uint256 constant ROCK_PAPER_SCISSORS_GAME_TYPE = 2; // 石头剪刀布

struct Gambler {
    address id;
    uint256 bet;
}

// 这个 DisplayInfo 为了展示用，否则返回的是 address，
// 设计不太好，后面再想想
struct DisplayInfo {
    address id;
    uint256 wager;
    uint256 gameType;
    Gambler[] gamblers;
}

abstract contract Game {
    uint256 public gameType;
    uint256 public wager;
    Gambler[] public gamblers;

    event JoinGame_Event(Game game);
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

    // 抽水，默认 10%
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
            for (uint i = 0; i < gamblers.length; i++) {
                bankRoll.payout(payable(gamblers[i].id), refund);
            }
        } else {
            bankRoll.payout(payable(winner), refund * gamblers.length);
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

contract RockPaperScissors is Game {
    // 石头剪刀布游戏
    // 选项: ROCK: 1; PAPER: 2; SCISSORS: 3;
    function init(uint256 customizeWager) public override {
        super.init(customizeWager);
        gameType = ROCK_PAPER_SCISSORS_GAME_TYPE;
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

contract Dice is Game {
    // 掷骰子游戏
    // 选项: 点数, 1~6;
    function init(uint256 customizeWager) public override {
        super.init(customizeWager);
        gameType = DICE_GAME_TYPE;
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

        uint256 roll = (uint256(
            keccak256(
                abi.encodePacked(block.timestamp, block.prevrandao, msg.sender)
            )
        ) % 6) + 1;

        bool winnerIsBig = roll >= 4;
        bool gamblerBIsBig = gamblerB.bet >= 4;
        bool gamblerBIsWinner = (winnerIsBig && gamblerBIsBig) ||
            (!winnerIsBig && !gamblerBIsBig);

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
        return
            DisplayInfo({
                id: address(this),
                wager: wager,
                gameType: gameType,
                gamblers: gamblers
            });
    }
}
