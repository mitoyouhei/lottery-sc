library Vigorish {
	/** 默认的抽水 2%，赔率 98 */
	function defaultHouseEdge(uint256 _wager) public returns (uint256) {
		uint256 vigorish = (_wager * 2) / 100;
		return _wager - vigorish;
	}
}