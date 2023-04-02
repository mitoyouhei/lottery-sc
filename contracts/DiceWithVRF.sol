// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.18 <0.9.0;
import "hardhat/console.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./BankRoll.sol";
import "./Game.sol";

uint32 constant CALLBACK_GAS_LIMIT = 150000;
uint32 constant MUMBAI_CALLBACK_GAS_LIMIT = 2500000;
uint32 constant NUM_WORDS = 1;
uint16 constant REQUEST_CONFIRMATIONS = 3;
uint64 constant SUBSCRIPTION_ID = 3873;// g - 10593; mumbai - 3873;
address constant LINK_TOKEN = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB; // MUMBAI/GOERLI TEST
bytes32 constant KEY_HASH = 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15; // Goerli 150 gwei
bytes32 constant MUMBAI_KEY_HASH = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f; // Mumbai 500 gwei

contract DiceWithVRF is VRFConsumerBaseV2, Game {
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);
    event CompleteGame_Event(address winner);
    
    struct RequestStatus {
        bool fulfilled;
        bool exists;
        uint256[] randomWords;
    }
    
    mapping(uint256 => RequestStatus)
    public s_requests;
    VRFCoordinatorV2Interface COORDINATOR;
    uint256[] public requestIds;
    uint public randomWordsNum;
    
    address private bankRollAddress;
    
    constructor(address _bankRoll)
    VRFConsumerBaseV2(0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed)
    {
        COORDINATOR = VRFCoordinatorV2Interface(0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed);
        gameType = DICE_GAME_TYPE;
        bankRollAddress = _bankRoll;
    }
    
    function getDisplayInfo() public view override returns (DisplayInfo memory){
        return DisplayInfo({
        id: address(this),
        wager: wager,
        gameType: gameType,
        gamblers: gamblers
        });
    }
    
    function getWinnerAndLoser() public pure override returns (address, address) {
        return (address(0), address(0));
    }
    
    function defineWinner(uint256 rollResult) public {
        require(gamblers.length == 2, "NEED_TWO_PLAYER");
        Gambler memory gamblerA = gamblers[0];
        Gambler memory gamblerB = gamblers[1];
        
        bool winnerIsBig = rollResult >= 4;
        bool gamblerBIsBig = gamblerB.choice >= 4;
        bool gamblerBIsWinner = (winnerIsBig && gamblerBIsBig) ||
        (!winnerIsBig && !gamblerBIsBig);
        
        address winnerAddress = gamblerBIsWinner ? gamblerB.id : gamblerA.id;
        console.log("winnerAddress: ", winnerAddress);
        console.log("rollResult: ", rollResult);
        
        IBankRoll bankRoll = IBankRoll(bankRollAddress);
        uint256 refund = wager - customizeVigorish();
        
        bankRoll.payout(payable(winnerAddress), refund * 2);
        
        emit CompleteGame_Event(winnerAddress);
    }
    
    
    function playWithVRF() public override {
        console.log("requestRandomWords");
        
        uint256 requestId = COORDINATOR.requestRandomWords(
            MUMBAI_KEY_HASH,
            SUBSCRIPTION_ID,
            REQUEST_CONFIRMATIONS,
            MUMBAI_CALLBACK_GAS_LIMIT,
            NUM_WORDS
        );
        console.log("requestRandomWords requestId: ", requestId);
        
        s_requests[requestId] = RequestStatus({
        randomWords : new uint256[](0),
        exists : true,
        fulfilled : false
        });
        requestIds.push(requestId);
        emit RequestSent(requestId, NUM_WORDS);
    }
    
    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        require(s_requests[_requestId].exists, "request not found");
        console.log("fulfillRandomWords requestId: ", _requestId);
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        randomWordsNum = _randomWords[0];
        console.log("fulfillRandomWords randomWordsNum: ", randomWordsNum);
        
        uint256 result = (randomWordsNum % 5);
        defineWinner(result);
        emit RequestFulfilled(_requestId, _randomWords);
    }
    
    function getWords() public view returns (uint256) {
        return randomWordsNum;
    }
}