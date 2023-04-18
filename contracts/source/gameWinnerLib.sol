// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.18 <0.9.0;

import "hardhat/console.sol";
import "./Game.sol";

library GameWinner {
	function getWinnerAndLoserForDice(Game self, uint256[] memory _randomWords) public returns (address, address) {
		uint256 result = (_randomWords[0] % 6) + 1;
		if (self.isDefaultHost()) {
			self.join(self.host(), result);
		}
		self.setResult(result);
	
		require(self.getGamblerLength() == 2, "NEED_TWO_PLAYER");
		(address gamblerAId, uint256 gamblerAChoice,) = self.gamblers(0);
		(address gamblerBId, ,) = self.gamblers(1);
		
		bool winnerIsBig = result >= 4;
		bool gamblerAIsBig = gamblerAChoice >= 4;
		bool gamblerAIsWinner = (winnerIsBig && gamblerAIsBig) ||
		(!winnerIsBig && !gamblerAIsBig);
		
		if (gamblerAIsWinner) {
			self.setWinner(gamblerAId);
			return (gamblerAId, gamblerBId);
		} else {
			self.setWinner(gamblerBId);
			return (gamblerBId, gamblerAId);
		}
	}
	
	function getWinnerAndLoserForRPS(Game self, uint256[] memory _randomWords) public returns (address, address) {
		uint256 result = (_randomWords[0] % 3) + 1;
		if (self.isDefaultHost()) {
			self.join(self.host(), result);
		}
		self.setResult(result);
		
		require(self.getGamblerLength() == 2, "NEED_TWO_PLAYER");
		(address gamblerAId, uint256 gamblerAChoice,) = self.gamblers(1);
		(address gamblerBId, uint256 gamblerBChoice,) = self.gamblers(0);
		
		if (gamblerAChoice == gamblerBChoice) {
			return (address(0), address(0));
		}
		
		bool gamblerBIsWinner = false;
		if (gamblerAChoice == 1) {
			gamblerBIsWinner = gamblerBChoice == 2;
		} else if (gamblerAChoice == 2) {
			gamblerBIsWinner = gamblerBChoice == 3;
		} else if (gamblerAChoice == 3) {
			gamblerBIsWinner = gamblerBChoice == 1;
		}
		
		if (gamblerBIsWinner) {
			self.setWinner(gamblerBId);
			return (gamblerBId, gamblerAId);
		} else {
			self.setWinner(gamblerAId);
			return (gamblerAId, gamblerBId);
		}
	}
}