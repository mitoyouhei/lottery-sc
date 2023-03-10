// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.18 <0.9.0;
import "hardhat/console.sol";

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

uint32 constant CALLBACK_GAS_LIMIT = 150000;
uint32 constant NUM_WORDS = 1;
uint16 constant REQUEST_CONFIRMATIONS = 3;
uint64 constant SUBSCRIPTION_ID = 10593;
address constant LINK_TOKEN = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB; // GOERLI TEST
bytes32 constant KEY_HASH = 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15; // we alread set this

contract DiceWithVRF is VRFConsumerBaseV2, ConfirmedOwner {
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);
    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus)
    public s_requests; /* requestId --> requestStatus */
    VRFCoordinatorV2Interface COORDINATOR;
    // past requests Id.
    uint256[] public requestIds;
    // address public immutable linkToken;
    uint public randomWordsNum;
    
    constructor()
    VRFConsumerBaseV2(0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D)
    ConfirmedOwner(msg.sender)
    {
        COORDINATOR = VRFCoordinatorV2Interface(0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D);
    }
    
    function requestRandomWords() public onlyOwner returns (uint256 requestId) {
        console.log("requestRandomWords");

        requestId = COORDINATOR.requestRandomWords(
            KEY_HASH,
            SUBSCRIPTION_ID,
            REQUEST_CONFIRMATIONS,
            CALLBACK_GAS_LIMIT,
            NUM_WORDS
        );
        console.log("requestRandomWords");
        console.log("requestRandomWords requestId: ", requestId);

        s_requests[requestId] = RequestStatus({
        randomWords: new uint256[](0),
        exists: true,
        fulfilled: false
        });
        requestIds.push(requestId);
        emit RequestSent(requestId, NUM_WORDS);
        return requestId; // requestID is a uint.
    }
    
    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        require(s_requests[_requestId].exists, "request not found");
        console.log("fulfillRandomWords requestId: ", _requestId);
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        randomWordsNum = _randomWords[0]; // Set array-index to variable, easier to play with
        console.log("fulfillRandomWords randomWordsNum: ", randomWordsNum);
        emit RequestFulfilled(_requestId, _randomWords);
    }
    
    // to check the request status of random number call.
    function getRequestStatus(
        uint256 _requestId
    ) external view returns (bool fulfilled, uint256[] memory randomWords) {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }
    
    function getRequestId() public view returns (uint256[] memory){
        return requestIds;
    }
}
