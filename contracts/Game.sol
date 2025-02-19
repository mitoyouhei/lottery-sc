// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.18 <0.9.0;
import "hardhat/console.sol";

import "./BankRoll.sol";

uint256 constant DEFAULT_CHOICE = 0; // 保留值

uint256 constant DICE_GAME_TYPE = 1; // 掷骰子
uint256 constant ROCK_PAPER_SCISSORS_GAME_TYPE = 2; // 石头剪刀布

struct Gambler {
    address id;
    uint256 choice;
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

    event JoinGame_Event(DisplayInfo game);
    event PlayGame_Event(address winner);

    function init(uint256 customizeWager) public virtual {
        wager = customizeWager;
    }

    // 玩家加入游戏
    function join(address gamblerAddress, uint256 choice) public payable {
        // require(wager > 0, 'INTERNAL_INIT');
        // require(wager == msg.value, 'WAGER_INVALID');

        console.log("join choice: ", choice);
        Gambler memory gambler = Gambler({id: gamblerAddress, choice: choice});

        gamblers.push(gambler);
        emit JoinGame_Event(this.getDisplayInfo());
    }

    // 抽水，默认 10%
    function customizeVigorish() public view returns (uint256) {
        require(wager > 0, "INTERNAL_INIT");
        return (wager * 0) / 100;
    }

    function _play(
        address _bankRoll,
        address winner,
        address loser
    ) internal returns (address) {
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

        return winner;
    }

    // 游戏结果以及支付彩头
    function play(address _bankRoll) public returns (address) {
        (address winner, address loser) = getWinnerAndLoser();
        return _play(_bankRoll, winner, loser);
    }

    function play(
        address _bankRoll,
        uint256[] memory _randomWords
    ) public returns (address) {
        (address winner, address loser) = getWinnerAndLoser(_randomWords);
        return _play(_bankRoll, winner, loser);
    }

    function getWager() public view returns (uint256) {
        return wager;
    }

    // 需要具体 游戏SmartContract 实现的游戏输赢规则
    function getWinnerAndLoser() public virtual returns (address, address);

    function getWinnerAndLoser(
        uint256[] memory _randomWords
    ) public virtual returns (address, address);

    function getDisplayInfo() public view virtual returns (DisplayInfo memory);

    // function playWithVRF() public virtual;
}
