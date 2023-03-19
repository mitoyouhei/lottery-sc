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