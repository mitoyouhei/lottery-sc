// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.18 <0.9.0;
import "hardhat/console.sol";

import "./BankRoll.sol";
import "./Game.sol";

uint256 constant DEFAULT_BET = 0; // 保留值

uint256 constant DICE_GAME_TYPE = 1; // 掷骰子
uint256 constant ROCK_PAPER_SCISSORS_GAME_TYPE = 2; // 石头剪刀布

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
