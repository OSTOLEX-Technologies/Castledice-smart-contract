// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.0;


contract CastlediceGame {
    uint8 constant public FIELD_HEIGHT = 10;
    uint8 constant public FIELD_WIDTH = 10;    

    struct Room {
        address[] players;
        uint currentPlayerIndex;
        mapping(uint8 => mapping(uint8 => BoardState)) boardState;
        uint8 currentPlayerMoves;
    }

    mapping(uint => Room) public rooms;
    uint public countRooms;

    constructor() public {
        countRooms = 0;
    }

    modifier onlyActivePlayer(uint roomId) {
        require(rooms[roomId].players[0] == msg.sender ||
                rooms[roomId].players[1] == msg.sender , 
                "You are not a player of this room");
        _;
    }

    function createRoom(address[] calldata players) external {
        countRooms++;
        Room storage room = rooms[countRooms];
        room.players = players;
        for (uint8 i = 0; i < FIELD_HEIGHT; i++) {
            for (uint8 j = 0; j < FIELD_WIDTH; j++) {
                room.boardState[i][j] = BoardState.FREE; // 0 for FREE, 1 for RED, 2 for BLUE
            }
        }
        room.boardState[0][0] = BoardState.BLUE;
        room.boardState[9][9] = BoardState.RED;
    }

    function makeMove(uint roomId, uint row, uint col) external onlyActivePlayer(roomId){
        
    }
}

enum BoardState {
    FREE,
    RED,
    BLUE
}
// board state 