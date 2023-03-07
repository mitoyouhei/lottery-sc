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
        console.log("BankRoll income: ", msg.value, ", from: ", msg.sender );
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

abstract contract CasinoGame {
    struct Gambler {
        address id;
        uint256 bet;
    }

    string public gameType;
    uint256 public wager;
    Gambler[] public gamblers;

    event JoinGame_Event(CasinoGame game);
    event PlayGame_Event(address winner);

    function init(uint256 customizeWager) public virtual {
        wager = customizeWager;
    }

    function join(address gamblerAddress, uint256 bet) public payable {
        // require(wager > 0, 'INTERNAL_INIT');
        // require(wager == msg.value, 'WAGER_INVALID');

        Gambler memory gambler = Gambler({
            id : gamblerAddress,
            bet : bet
        });

        gamblers.push(gambler);
        emit JoinGame_Event(this);
    }


    function customizeVigorish() public view returns (uint256) {
        require(wager > 0, 'INTERNAL_INIT');
        return (wager * 5) / 100;
    }

    function play() public returns (address, address) {
        (address winner, address loser) = getWinnerAndLoser();
        emit PlayGame_Event(winner);
        return (winner, loser);
    }


    function getWinnerAndLoser() public virtual returns (address, address);
}

// ROCK: 0; PAPER: 1; SCISSORS: 2;
contract RockPaperScissors is CasinoGame {
    function init(uint256 customizeWager) public override {
        super.init(customizeWager);
        gameType = 'ROCK_PAPER_SCISSORS';
    }

    function getWinnerAndLoser() public override view returns (address, address) {
        require(gamblers.length == 2, 'NEED_TWO_PLAYER');
        Gambler memory gamblerA = gamblers[0];
        Gambler memory gamblerB = gamblers[1];

        if(gamblerA.bet == gamblerB.bet) {
            return (address(0), address(0));
        }

        bool gamblerBIsWinner = false;
        if (gamblerA.bet == 0) {
            gamblerBIsWinner = gamblerB.bet == 1;
        } else if (gamblerA.bet == 1) {
            gamblerBIsWinner = gamblerB.bet == 2;
        } else if (gamblerA.bet == 2) {
            gamblerBIsWinner = gamblerB.bet == 0;
        }

        return gamblerBIsWinner ? (gamblerB.id, gamblerA.id) : (gamblerA.id, gamblerB.id);
    }
}

contract ACasino {
    IBankRoll private bankRoll;
    mapping(address => CasinoGame) private gameMap;
    address[] private games;

    constructor() {
        bankRoll = new BankRoll();
    }

    // function createGame(string memory inputGameType, uint256 bet) public payable {
    function createGame() public payable {
        bankRoll.income{value: msg.value}();

        string memory inputGameType = "SCISSORS";
        uint256 bet = 2;

        CasinoGame game;
        game = new RockPaperScissors();
        game.init(msg.value);
        game.join(msg.sender, bet);

        address gameAddress = address(game);
        gameMap[gameAddress] = game;
        games.push(gameAddress);
    }

    // function playGame(address targetGame, uint256 bet) public payable {
    function playGame() public payable {
        uint256 bet = 1;
        bankRoll.income{value: 100}();

        CasinoGame game = gameMap[games[0]];
        game.join(msg.sender, bet);
        (address winner, address loser) = game.play();

        uint256 refund = game.customizeVigorish();
        if(winner == loser) {
            bankRoll.payout(payable(winner), refund);
            bankRoll.payout(payable(loser), refund);
        } else {
            bankRoll.payout(payable(winner), refund);
        }
        // delete gameMap[address(game)];
    }

    function getGames() public view returns (CasinoGame[] memory) {
        CasinoGame[] memory allGames = new CasinoGame[](games.length);
        for(uint i = 0; i<games.length; i++) {
            CasinoGame game = gameMap[games[i]];
            allGames[i] = game;
        }    
        return allGames;
    }
}