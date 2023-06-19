// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.0;


contract CastlediceGame {
    uint8 constant public FIELD_HEIGHT = 10;
    uint8 constant public FIELD_WIDTH = 10;    
    event FinishedGames(uint256 roomId, address winner);

    struct Room {
        address[] players;
        uint8 currentPlayerIndex;
        mapping(uint8 => mapping(uint8 => BoardState)) boardState;
        uint8 currentPlayerMoves;
        uint256 randomParameter;
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

    function createRoom(address[] calldata players) external returns (uint256) {
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
        
        room.randomParameter = uint256(keccak256(abi.encodePacked(
            room.players[0], 
            room.players[1],
            countRooms
        )));
        return countRooms;
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
            // TODO: check tails
        }
        if (room.currentPlayerMoves == 0) {
            updateCurrentPlayer(roomId);
        }
        return room.currentPlayerMoves;
    }

    function updateRandomValue(uint256 roomId) internal {
        Room storage room = rooms[roomId];
        room.randomParameter = uint256(keccak256(abi.encodePacked(room.randomParameter)));
    }

    function updateCurrentPlayer(uint256 roomId) internal {
        Room storage room = rooms[roomId];
        require(room.currentPlayerMoves == 0, "Previous player still has moves");
        updateCurrentPlayerMoves(roomId);
        room.currentPlayerIndex ^= 1;
    }

    function updateCurrentPlayerMoves(uint roomId) internal {
        Room storage room = rooms[roomId];
        updateRandomValue(roomId);
        room.currentPlayerMoves = uint8((room.randomParameter % 5) + 1);
    }

    function isGameFinished(uint256 roomId) public view returns (bool) {
        Room storage room = rooms[roomId];
        return room.boardState[0][0] == BoardState.RED || room.boardState[9][9] == BoardState.BLUE;            
    }

    function getGameWinner(uint256 roomId) public view returns (address) {
        Room storage room = rooms[roomId];
        if (room.boardState[0][0] == BoardState.RED) {
            return room.players[1];
        }
        if (room.boardState[9][9] == BoardState.BLUE) {
            return room.players[0];
        }
        revert("Game is not finished, there is no winner");
    }

    function getCurrentPlayerMovesLeft(uint256 roomId) public view returns (uint8) {
        return rooms[roomId].currentPlayerMoves;
    }

    function getCurrentPlayerIndex(uint256 roomId) public view returns (uint8) {
        return rooms[roomId].currentPlayerIndex;
    }
    
}

enum BoardState {
    FREE,
    RED,
    BLUE
}