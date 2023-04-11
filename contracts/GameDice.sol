// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.18 <0.9.0;
import "hardhat/console.sol";

import "./BankRoll.sol";
import "./Game.sol";
import "./GameWinner.sol";

contract Dice is Game {
    // 掷骰子游戏
    // 选项: 点数, 1~6;
    constructor(uint256 _gameType, address _host, uint256 _wager) Game (_gameType, _host, _wager){
    }
    
    function getWinnerAndLoser() public pure override returns (address, address){
        revert("Shouldn't call!");
    }

    function getWinnerAndLoser(uint256[] memory _randomWords) public override returns (address, address) {
        return GameWinner.getWinnerAndLoserForDice(this, _randomWords);
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
                gameType: gameType,
                wager: wager,
                isActive: isActive,
                gamblers: gamblers,
                host: host
            });
    }
}
