// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.19 <0.9.0;
import "hardhat/console.sol";

contract DiceGameLobby {
    struct DiceGame {
        uint256 id;
        address player1;
        address player2;
        uint256 betAmount;
        uint256 player1BetNumber;
        uint256 player2BetNumber;
    }
    uint256 gameIndexFeed;
    DiceGame[] private games;

    event CreateGame(DiceGame game);
    event PlayGame(uint256 roll);

    function getGames() public view returns (DiceGame[] memory) {
        return games;
    }

    function createGame(uint256 betNumber) public payable {
        require(msg.value > 0, "Please send a bet amount.");
        DiceGame memory newGame = DiceGame({
            id: ++gameIndexFeed,
            player1: msg.sender,
            player1BetNumber: betNumber,
            betAmount: msg.value,
            player2: address(0),
            player2BetNumber: 0
        });
        games.push(newGame);
        emit CreateGame(newGame);
    }

    function play(uint256 id, uint256 betNumber) public payable {
        for (uint256 i = 0; i < games.length; i++) {
            if (games[i].id == id) {
                DiceGame memory game = games[i];
                require(
                    msg.value == game.betAmount,
                    "Please send the correct bet amount."
                );

                game.player2 = msg.sender;
                game.player2BetNumber = betNumber;

                uint256 roll = rollDice();
                console.log("roll", roll);

                bool isBig = roll >= 4;

                address bigWinner;
                address smallWinner;
                if (game.player1BetNumber >= 4) {
                    bigWinner = game.player1;
                    smallWinner = game.player2;
                } else {
                    bigWinner = game.player2;
                    smallWinner = game.player1;
                }

                if (isBig) {
                    payWinner(bigWinner, game.betAmount * 2);
                } else {
                    payWinner(smallWinner, game.betAmount * 2);
                }

                emit PlayGame(roll);
            }
        }
    }

    function payWinner(address winner, uint256 balance) private {
        payable(winner).transfer(balance);
    }

    function rollDice() private view returns (uint256) {
        uint256 roll = (uint256(
            keccak256(
                abi.encodePacked(block.timestamp, block.prevrandao, msg.sender)
            )
        ) % 6) + 1;
        console.log("rollDice roll", roll);
        return roll;
    }
}
