// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.18 <0.9.0;
import "hardhat/console.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./BankRoll.sol";
import "./OneOnOneGame.sol";

contract Dice is OneOnOneGame, ReentrancyGuard {
    // 掷骰子游戏
    // 选项: 点数, 1~6;
    constructor(uint256 _gameType, address _host, uint256 _wager) OneOnOneGame (_gameType, _host, _wager){
    }
    
    function getWinnerAndLoser()
        public
        override
        nonReentrant
        returns (address, address)
    {
        revert("Shouldn't call!");
    }

    function getWinnerAndLoser(
        uint256[] memory _randomWords
    ) public override nonReentrant returns (address, address) {
        uint256 roll = (_randomWords[0] % 6) + 1;
        
        if (isDefaultHost()) {
            Gambler memory playerHost = Gambler({id : host, choice : roll});
            gamblers.push(playerHost);
        }
    
        require(gamblers.length == 2, "NEED_TWO_PLAYER");
        Gambler memory gamblerA = gamblers[0];
        Gambler memory gamblerB = gamblers[1];
        
        bool winnerIsBig = roll >= 4;
        bool gamblerBIsBig = gamblerB.choice >= 4;
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
                gameType: gameType,
                wager: wager,
                isActive: isActive,
                gamblers: gamblers,
                host: host
            });
    }
}
