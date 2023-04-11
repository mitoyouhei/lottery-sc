// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.18 <0.9.0;

import "hardhat/console.sol";
import "./Game.sol";

library GameWinner {
	function getWinnerAndLoserForDice(Game self, uint256[] memory _randomWords) public returns (address, address) {
		uint256 roll = (_randomWords[0] % 6) + 1;
		if (self.isDefaultHost()) {
			self.join(self.getHost(), roll);
		}
		
		require(self.getGamblers().length == 2, "NEED_TWO_PLAYER");
		Gambler memory gamblerA = self.getGamblers()[0];
		Gambler memory gamblerB = self.getGamblers()[1];
		
		bool winnerIsBig = roll >= 4;
		bool gamblerAIsBig = gamblerA.choice >= 4;
		bool gamblerAIsWinner = (winnerIsBig && gamblerAIsBig) ||
		(!winnerIsBig && !gamblerAIsBig);
		
		return gamblerAIsWinner ? (gamblerA.id, gamblerB.id) : (gamblerB.id, gamblerA.id);
	}
	
	function getWinnerAndLoserForRPS(Game self, uint256[] memory _randomWords) public returns (address, address) {
		uint256 result = (_randomWords[0] % 3) + 1;
		if (self.isDefaultHost()) {
			self.join(self.getHost(), result);
		}
		
		require(self.getGamblers().length == 2, "NEED_TWO_PLAYER");
		Gambler memory gamblerB = self.getGamblers()[0];
		Gambler memory gamblerA = self.getGamblers()[1];
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
		
		return gamblerBIsWinner ? (gamblerB.id, gamblerA.id) : (gamblerA.id, gamblerB.id);
		
		}
}