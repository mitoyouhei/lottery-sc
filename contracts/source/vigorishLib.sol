// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.18 <0.9.0;

library Vigorish {
	/** 默认的抽水 2%，赔率 98 */
	function defaultHouseEdge(uint256 _wager) public pure returns (uint256) {
		uint256 vigorish = (_wager * 2) / 100;
		return _wager - vigorish;
	}
}