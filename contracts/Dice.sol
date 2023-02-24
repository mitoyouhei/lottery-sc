// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.19 <0.9.0;

contract DiceGame {
    address private player1;
    address private player2;
    uint private betAmount;
    uint private player1BetNumber;
    uint private player2BetNumber;

    function createGame(uint betNumber) public payable {
        require(msg.value > 0, "Please send a bet amount.");
        require(player1 == address(0), "Game already created.");
        require(
            betNumber >= 1 && betNumber <= 6,
            "Please send correct number."
        );
        player1 = msg.sender;
        betAmount = msg.value;
        player1BetNumber = betNumber;
    }

    function joinGame(uint betNumber) public payable {
        require(msg.value == betAmount, "Please send the correct bet amount.");
        require(player2 == address(0), "Game already has two players.");
        require(
            betNumber >= 1 && betNumber <= 6,
            "Please send correct number."
        );
        player2 = msg.sender;
        player2BetNumber = betNumber;
    }

    function rollDice() public returns (uint) {
        uint roll = (uint(
            keccak256(
                abi.encodePacked(block.timestamp, block.prevrandao, msg.sender)
            )
        ) % 6) + 1;
        bool isBig = roll >= 4;

        address bigWinner;
        address smallWinner;
        if (player1BetNumber >= 4) {
            bigWinner = player1;
            smallWinner = player2;
        } else {
            bigWinner = player2;
            smallWinner = player1;
        }

        if (isBig) {
            payWinner(bigWinner);
        } else {
            payWinner(smallWinner);
        }

        return roll;
    }

    function payWinner(address winner) private {
        payable(winner).transfer(address(this).balance);
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getAddress() public view returns (address) {
        return address(this);
    }
}

contract DiceGameLobby {
    uint256 private gameCounter;
    DiceGame[] private games;
    event CreateGame(address _gameAddress);

    function createGame(uint betNumber) public payable {
        require(msg.value > 0, "Please send a bet amount.");
        DiceGame newGame = (new DiceGame)();
        newGame.createGame{value: msg.value}(betNumber);
        games.push(newGame);
        gameCounter++;
        emit CreateGame(newGame.getAddress());
    }

    function play(
        address gameAddress,
        uint betNumber
    ) public payable returns (uint) {
        require(msg.value > 0, "Please send a bet amount.");
        for (uint256 i = 0; i < games.length; i++) {
            DiceGame game = games[i];
            if (game.getAddress() == gameAddress) {
                game.joinGame{value: msg.value}(betNumber);
                return game.rollDice();
            }
        }
        return 0;
    }

    function getGameCount() public view returns (uint) {
        return gameCounter;
    }

    function getGames() public view returns (DiceGame[] memory) {
        return games;
    }
}
