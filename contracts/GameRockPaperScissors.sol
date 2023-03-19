// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.18 <0.9.0;
import "hardhat/console.sol";

import "./BankRoll.sol";
import "./Game.sol";

uint256 constant DEFAULT_BET = 0; // 保留值

uint256 constant DICE_GAME_TYPE = 1; // 掷骰子
uint256 constant ROCK_PAPER_SCISSORS_GAME_TYPE = 2; // 石头剪刀布

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

