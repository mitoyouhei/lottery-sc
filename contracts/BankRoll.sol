// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.18 <0.9.0;
import "hardhat/console.sol";

interface IBankRoll {
    function income() external payable;

    function payout(address payable target, uint256 balance) external;

    function withdraw() external;

    function showBalance() external view returns (uint256);
}

contract BankRoll is IBankRoll {
    // TODO owner

    function income() public payable {
        console.log("BankRoll income: ", msg.value);
        console.log("BankRoll current balance: ", address(this).balance);
    }

    function payout(address payable _sendTo, uint256 balance) public {
        (bool success, ) = _sendTo.call{value: balance}("");
        console.log("BankRoll payout: ", balance, ", to: ", _sendTo);
        console.log("BankRoll current balance: ", address(this).balance);
        require(success, "PAYOUT_FAILED");
    }

    function withdraw() public {
        payable(msg.sender).transfer(address(this).balance);
    }

    function showBalance() public view returns (uint256) {
        return address(this).balance;
    }
}