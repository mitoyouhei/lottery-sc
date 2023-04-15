// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.18 <0.9.0;
import "hardhat/console.sol";

import "./BankRoll.sol";
import "./Game.sol";
import "./GameWinner.sol";

contract RockPaperScissors is Game {
    // 石头剪刀布游戏
    // 选项: ROCK: 1; PAPER: 2; SCISSORS: 3;
    constructor(uint256 _gameType, address _host, uint256 _wager) Game(_gameType, _host, _wager){
    }
    
    function getWinnerAndLoser() public pure override returns (address, address){
        revert("Shouldn't call!");
    }
    
    function getWinnerAndLoser(uint256[] memory _randomWords) public override returns (address, address) {
        return GameWinner.getWinnerAndLoserForRPS(this, _randomWords);
    }

    function getDisplayInfo()
        public
        view
        override
        returns (DisplayInfo memory)
    {
        // 游戏已经完成，返回所有的数据
        // 游戏未完成，用户选择隐藏
        Gambler[] memory displayGamblers = new Gambler[](gamblers.length);
        if (isActive) {
            for (uint256 i = 0; i < gamblers.length; i++) {
                    displayGamblers[i] = Gambler({
                    id : gamblers[i].id,
                    choice : DEFAULT_CHOICE
                });
            }
        } else {
            displayGamblers = gamblers;
        }
        
        return
            DisplayInfo({
                id: address(this),
                gameType: gameType,
                wager: wager,
                isActive: isActive,
                gamblers: displayGamblers,
                host: host
            });
    }
}
