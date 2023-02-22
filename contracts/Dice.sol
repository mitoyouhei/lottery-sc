// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

error FundMe__NotOwner();

contract Dice {
    address private immutable i_owner;
    Game[] private games;
    CompletedGame[] private completedGames;
    uint256 private gameIdFeed;

    struct Game {
        uint256 id;
        address player;
        uint256 value;
        uint betNumber;
    }

    struct CompletedGame {
        Game game;
        address playerB;
        uint betNumberB;
    }

    modifier onlyOwner() {
        // require(msg.sender == i_owner);
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        _;
    }

    constructor() {
        i_owner = msg.sender;
        gameIdFeed = 0;
    }

    function getGames() public view returns (Game[] memory) {
        return games;
    }

    function createGame(uint _betNumber) public payable {
        games.push(
            Game({
                id: gameIdFeed++,
                player: msg.sender,
                value: msg.value,
                betNumber: _betNumber
            })
        );
    }

    function play(uint256 gameId, uint _betNumber) public payable {
        for (uint256 i = 0; i < games.length; i++) {
            Game memory game = games[i];
            if (game.id == gameId) {
                require(msg.value != game.value, "InvalidValue");

                // random call
                uint256 price = game.value * 2;
                address winner = msg.sender;

                payable(winner).transfer(price);

                completedGames.push(
                    CompletedGame({
                        game: game,
                        playerB: msg.sender,
                        betNumberB: _betNumber
                    })
                );
            }
        }
    }

    function withdraw() public onlyOwner {
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success);
    }
}
