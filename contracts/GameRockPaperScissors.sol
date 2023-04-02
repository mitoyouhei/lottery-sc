// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.18 <0.9.0;
import "hardhat/console.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./BankRoll.sol";
import "./Game.sol";

contract RockPaperScissors is Game, ReentrancyGuard {
    // 石头剪刀布游戏
    // 选项: ROCK: 1; PAPER: 2; SCISSORS: 3;
    function init(uint256 customizeWager) public override {
        super.init(customizeWager);
        gameType = ROCK_PAPER_SCISSORS_GAME_TYPE;
    }

    function getWinnerAndLoser()
        public
        nonReentrant
        override
        returns (address, address)
    {
        require(gamblers.length == 2, "NEED_TWO_PLAYER");
        Gambler memory gamblerA = gamblers[0];
        Gambler memory gamblerB = gamblers[1];

        if (gamblerA.choice == gamblerB.choice) {
            return (address(0), address(0));
        }

        bool gamblerBIsWinner = false;
        if (gamblerA.choice == 1) {
            gamblerBIsWinner = gamblerB.choice == 2;
        } else if (gamblerA.choice == 2) {
            gamblerBIsWinner = gamblerB.choice == 3;
        } else if (gamblerA.choice == 3) {
            gamblerBIsWinner = gamblerB.choice == 1;
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
                    choice: DEFAULT_CHOICE
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
    
    function playWithVRF() public view override {
        require(gamblers.length == 2, "NEED_TWO_PLAYER");
    }
}

