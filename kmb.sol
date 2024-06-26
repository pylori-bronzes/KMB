// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RockPaperScissors {
    enum Move { None, Rock, Paper, Scissors }
    enum Player { None, Player1, Player2 }

    struct Game {
        address player1;
        address player2;
        Move player1Move;
        Move player2Move;
        uint256 betAmount;
        bool isActive;
    }

    mapping(uint256 => Game) public games;
    uint256 public gameCounter;
    address public owner;

    event GameCreated(uint256 gameId, address player1, address player2, uint256 betAmount);
    event MoveMade(uint256 gameId, address player, Move move);
    event GameResult(uint256 gameId, address winner);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier isActiveGame(uint256 gameId) {
        require(games[gameId].isActive, "Game is not active");
        _;
    }

    modifier onlyPlayers(uint256 gameId) {
        require(
            msg.sender == games[gameId].player1 || msg.sender == games[gameId].player2,
            "Only players can call this function"
        );
        _;
    }

    function createGame(address _player2) external payable {
        require(msg.value > 0, "Bet amount must be greater than zero");

        gameCounter++;
        games[gameCounter] = Game({
            player1: msg.sender,
            player2: _player2,
            player1Move: Move.None,
            player2Move: Move.None,
            betAmount: msg.value,
            isActive: true
        });

        emit GameCreated(gameCounter, msg.sender, _player2, msg.value);
    }

    function makeMove(uint256 gameId, Move _move) external isActiveGame(gameId) onlyPlayers(gameId) {
        require(_move != Move.None, "Invalid move");
        Game storage game = games[gameId];

        if (msg.sender == game.player1) {
            require(game.player1Move == Move.None, "Player1 has already made a move");
            game.player1Move = _move;
        } else if (msg.sender == game.player2) {
            require(game.player2Move == Move.None, "Player2 has already made a move");
            game.player2Move = _move;
        }

        emit MoveMade(gameId, msg.sender, _move);

        if (game.player1Move != Move.None && game.player2Move != Move.None) {
            determineWinner(gameId);
        }
    }

    function determineWinner(uint256 gameId) private {
        Game storage game = games[gameId];
        Player winner = Player.None;

        if (game.player1Move == game.player2Move) {
            // It's a tie
            payable(game.player1).transfer(game.betAmount);
            payable(game.player2).transfer(game.betAmount);
        } else if (
            (game.player1Move == Move.Rock && game.player2Move == Move.Scissors) ||
            (game.player1Move == Move.Paper && game.player2Move == Move.Rock) ||
            (game.player1Move == Move.Scissors && game.player2Move == Move.Paper)
        ) {
            // Player1 wins
            winner = Player.Player1;
            payable(game.player1).transfer(2 * game.betAmount);
        } else {
            // Player2 wins
            winner = Player.Player2;
            payable(game.player2).transfer(2 * game.betAmount);
        }

        game.isActive = false;
        emit GameResult(gameId, winner == Player.Player1 ? game.player1 : (winner == Player.Player2 ? game.player2 : address(0)));
    }
}
