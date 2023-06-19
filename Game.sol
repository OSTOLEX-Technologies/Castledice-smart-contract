// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.0;


contract CastlediceGame {
    uint8 constant public FIELD_HEIGHT = 10;
    uint8 constant public FIELD_WIDTH = 10;    
    event GameOver(uint256 roomId, address winner);

    struct Room {
        address[] players;
        uint8 currentPlayerIndex;
        mapping(uint8 => mapping(uint8 => BoardState)) boardState;
        uint8 currentPlayerMoves;
    }

    mapping(uint256 => Room) public rooms;
    uint256 public countRooms;

    constructor() public {
        countRooms = 0;
    }

    modifier onlyActivePlayer(uint roomId) {
        uint8 playerIndex = rooms[roomId].currentPlayerIndex;

        require(rooms[roomId].players[playerIndex] == msg.sender,
                "You are not a player of this room");
        _;
    }

    function createRoom(address[] calldata players) external {
        countRooms++;
        Room storage room = rooms[countRooms];
        room.players = players;
        for (uint8 i = 0; i < FIELD_HEIGHT; i++) {
            for (uint8 j = 0; j < FIELD_WIDTH; j++) {
                room.boardState[i][j] = BoardState.FREE;
            }
        }
        room.boardState[0][0] = BoardState.BLUE;
        room.boardState[9][9] = BoardState.RED;
    }

    // returns amount of moves left for the player
    function makeMove(uint roomId, uint8 row, uint8 col) external onlyActivePlayer(roomId) returns(uint8){
        Room storage room = rooms[roomId];

        BoardState currentCellState = room.boardState[row][col];
        BoardState currentPlayerColor = BoardState.RED;
        if (room.currentPlayerIndex == 1) {
            currentPlayerColor = BoardState.BLUE;
        }

        require(currentCellState != currentPlayerColor, "You cannot make move on your cell");

        if (currentCellState == BoardState.FREE) {
            require(room.currentPlayerMoves >= 1, "You need at least 1 move");
            room.currentPlayerMoves -= 1;
            room.boardState[row][col] = currentPlayerColor;
        } else {
            require(room.currentPlayerMoves >= 3, "You need at least 3 moves left");
            room.currentPlayerMoves -= 3;
            room.boardState[row][col] = currentPlayerColor;
            // TODO: check *tails
        }
        return room.currentPlayerMoves;
    }
}

enum BoardState {
    FREE,
    RED,
    BLUE
}
// board state 