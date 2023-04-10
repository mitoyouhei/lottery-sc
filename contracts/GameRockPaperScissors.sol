// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.18 <0.9.0;
import "hardhat/console.sol";

import "./BankRoll.sol";
import "./Game.sol";

contract RockPaperScissors is Game {
    // 石头剪刀布游戏
    // 选项: ROCK: 1; PAPER: 2; SCISSORS: 3;
    constructor(uint8 _gameType, address _host, uint256 _wager) Game(_gameType, _host, _wager){
    }
    
    function getWinnerAndLoser()
    public
    override
    returns (address, address)
    {
        revert("Shouldn't call!");
    }
    
    function getWinnerAndLoser(
        uint256[] memory _randomWords
    ) public override returns (address, address) {
        uint8 result = uint8((_randomWords[0] % 3) + 1);
    
        if (isDefaultHost()) {
            Gambler memory playerHost = Gambler({id : host, choice : result});
            gamblers.push(playerHost);
        }
    
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
        // 游戏已经完成，返回所有的数据
        // 游戏未完成，用户选择隐藏
        Gambler[] memory displayGamblers = new Gambler[](gamblers.length);
        if (isGameActive()) {
            for (uint8 i = 0; i < gamblers.length; i++) {
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
