// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.18 <0.9.0;
import "hardhat/console.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol";

uint32 constant CALLBACK_GAS_LIMIT = 150000;
uint32 constant NUM_WORDS = 1;
uint16 constant REQUEST_CONFIRMATIONS = 3;
//address constant LINK_TOKEN = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB; // GOERLI TEST
address constant LINK_TOKEN = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB; // MUMBAI TEST
//address constant LINK_WRAPPER_ADDRESS = 0x708701a1DfF4f478de54383E49a627eD4852C816; // address WRAPPER - hardcoded for GOERLI TEST
address constant LINK_WRAPPER_ADDRESS = 0x99aFAf084eBA697E584501b8Ed2c0B37Dd136693; // address WRAPPER - hardcoded for MUMBAI TEST

contract DiceWithVRFViaDirectFunding is VRFV2WrapperConsumerBase, ConfirmedOwner {
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords, uint256 payment);
    
    struct RequestStatus {
        uint256 paid; // amount paid in link
        bool fulfilled; // whether the request has been successfully fulfilled
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus)
    public s_requests;
    uint256[] public requestIds;
    
    uint public randomWordsNum;
    
    constructor()
    ConfirmedOwner(msg.sender)
    VRFV2WrapperConsumerBase(LINK_TOKEN, LINK_WRAPPER_ADDRESS)
    {
    }
    
    function requestRandomWords() external onlyOwner returns (uint256 requestId){
        requestId = requestRandomness(
            CALLBACK_GAS_LIMIT,
            REQUEST_CONFIRMATIONS,
            NUM_WORDS
        );
        s_requests[requestId] = RequestStatus({
        paid: VRF_V2_WRAPPER.calculateRequestPrice(CALLBACK_GAS_LIMIT),
        randomWords: new uint256[](0),
        fulfilled: false
        });
        
        requestIds.push(requestId);
        emit RequestSent(requestId, NUM_WORDS);
        return requestId;
    }
    
    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        require(s_requests[_requestId].paid > 0, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        randomWordsNum = _randomWords[0]; // Set array-index to variable, easier to play with
        console.log("fulfillRandomWords randomWordsNum: ", randomWordsNum);
        emit RequestFulfilled(
            _requestId,
            _randomWords,
            s_requests[_requestId].paid
        );
    }
    
    function getRequestStatus(uint256 _requestId) external view returns (uint256 paid, bool fulfilled, uint256[] memory randomWords){
        require(s_requests[_requestId].paid > 0, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.paid, request.fulfilled, request.randomWords);
    }
    
    function getRequestId() public view returns (uint256[] memory){
        return requestIds;
    }
    
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(LINK_TOKEN);
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }
}
