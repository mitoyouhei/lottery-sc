// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.18 <0.9.0;

import "hardhat/console.sol";

address constant EMPTY_ADDRESS = address(0);
uint256 constant GAME_INCOME = 1;
uint256 constant GAME_PAYOUT = 2;
uint256 constant OWNER_WITHDRAW = 3;
uint256 constant OWNER_DEPOSIT = 4;

interface IBankRoll {
    function init(address owner) external;
    
    function gameIncome(address _playerAddress, address _gameAddress) external payable;
    
    function gamePayout(address payable _sendTo, uint256 _balance) external;
    
    function withdraw() external;
    
    function deposit() external payable;
    
    function showBalance() external view returns (uint256);
    
    function getAllRecords() external view returns (Record[] memory);
}
    
struct Record {
    address from; // 账目资金来源
    address to; // 账目资金去处
    address game; // 触发资金变动的 game。如果不是由game触发的，则为 EMPTY_ADDRESS
    uint256 value; // 账目资金价值
    uint256 recordType; // 账目类型
}

contract BankRoll is IBankRoll {
    address private owner;
    Record[] records;
    
    modifier _onlyOwner(){
        require(msg.sender == owner, "DENIED_BY_NOT_OWNER");
        _;
    }
    
    modifier _onlyValidCaller(){
        _;
    }
    
    function init(address _owner) public {
        owner = _owner;
    }
    
    function recordIncome(address _from, address _gameAddress, uint256 _value, uint256 _type) private {
        Record memory recordItem = Record({
            from : _from,
            to : address(this),
            game: _gameAddress,
            value : _value,
            recordType : _type
        });
        records.push(recordItem);
    }
    
    function recordPayout(address _to, address _gameAddress, uint256 _value, uint256 _type) private {
        Record memory recordItem = Record({
            from : address(this),
            to : _to,
            game: _gameAddress,
            value : _value,
            recordType : _type
        });
        records.push(recordItem);
    }
    
    function gameIncome(address _playerAddress, address _gameAddress) public payable {
        recordIncome(_playerAddress, _gameAddress, msg.value, GAME_INCOME);
    }
    
    function gamePayout(address payable _sendTo, uint256 _balance) _onlyValidCaller public {
        require(_balance <= address(this).balance, "BANKROLL_BALANCE_NOT_ENOUGH");
        if (_sendTo != EMPTY_ADDRESS) {
            (bool success,) = _sendTo.call{value : _balance}("");
            require(success, "PAYOUT_FAILED");
            recordPayout(_sendTo, msg.sender, _balance, GAME_PAYOUT);
        }
    }
    
    function withdraw() public {
        uint256 bankrollBalance = address(this).balance;
        payable(owner).transfer(bankrollBalance);
        recordPayout(owner, EMPTY_ADDRESS, bankrollBalance, OWNER_WITHDRAW);
    }
    
    function deposit() public payable {
        recordIncome(msg.sender, EMPTY_ADDRESS, msg.value, OWNER_DEPOSIT);
    }
    
    function showBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    function getAllRecords() public view returns (Record[] memory) {
        return records;
    }
}