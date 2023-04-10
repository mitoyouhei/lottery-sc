// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.18 <0.9.0;
import "hardhat/console.sol";

import "./BankRoll.sol";

uint256 constant DEFAULT_CHOICE = 0; // 保留值
uint256 constant DICE_GAME_TYPE = 1; // 掷骰子
uint256 constant ROCK_PAPER_SCISSORS_GAME_TYPE = 2; // 石头剪刀布
address constant DEFAULT_GAME_HOST = address(0);

struct Gambler {
    address id;
    uint256 choice;
}

struct DisplayInfo {
    address id;
    address host;
    uint256 gameType;
    uint256 wager;
    bool isActive;
    Gambler[] gamblers;
}

abstract contract Game {
    uint256 public gameType;
    address public host;
    uint256 public wager;
    address public winner;
    bool public isActive;
    Gambler[] gamblers;
    
    constructor(uint256 _gameType, address _host, uint256 _wager){
        gameType = _gameType;
        host = _host;
        wager = _wager;
        isActive = true;
    }
    
    // 玩家加入游戏
    function join(address _gamblerAddress, uint256 _choice) public payable {
        Gambler memory gambler = Gambler({id : _gamblerAddress, choice : _choice});
        gamblers.push(gambler);
    }
    
    // TODO 抽水
    function customizeVigorish() public view returns (uint256) {
        return (wager * 50) / 100;
    }
    
    function isDefaultHost() public view returns (bool) {
        return host == DEFAULT_GAME_HOST;
    }
    
    function isGameActive() public view returns (bool) {
        return isActive;
    }
    
    function getWager() public view returns (uint256) {
        return wager;
    }
    
    function getHost() public view returns (address) {
        return host;
    }
    
    function _play(
        address _bankRoll,
        address _winner,
        address _loser
    ) internal returns (address) {
        IBankRoll bankRoll = IBankRoll(_bankRoll);
        uint256 refund = wager - customizeVigorish();
        if (_winner == _loser) {
            for (uint i = 0; i < gamblers.length; i++) {
                if (gamblers[i].id != DEFAULT_GAME_HOST) {
                    bankRoll.gamePayout(payable(gamblers[i].id), refund);
                }
            }
        } else {
            bankRoll.gamePayout(payable(_winner), refund * 2);
        }
        isActive = false; // TODO：这里稍微有点延迟了
        return _winner;
    }
    
    // 游戏结果以及支付彩头
    function play(address _bankRoll) public returns (address) {
        (address _winner, address _loser) = getWinnerAndLoser();
        winner = _winner;
        return _play(_bankRoll, _winner, _loser);
    }
    
    function play(
        address _bankRoll,
        uint256[] memory _randomWords
    ) public returns (address) {
        (address _winner, address _loser) = getWinnerAndLoser(_randomWords);
        return _play(_bankRoll, _winner, _loser);
    }
    
    // 需要具体 游戏SmartContract 实现的游戏输赢规则
    function getWinnerAndLoser() public virtual returns (address, address);
    
    function getWinnerAndLoser(
        uint256[] memory _randomWords
    ) public virtual returns (address, address);
    
    function getDisplayInfo() public view virtual returns (DisplayInfo memory);
}
