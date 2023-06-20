// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.0;


contract CastlediceGame {
    uint8 constant public FIELD_HEIGHT = 10;
    uint8 constant public FIELD_WIDTH = 10;    
    event FinishedGames(uint256 roomId, address winner);
    BoardState[] playerColors = [BoardState.BLUE, BoardState.RED];

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
                "It is not your turn to make a move");
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
            countRooms,
            blockhash(block.number - 1)
        )));

        updateCurrentPlayerMoves(countRooms);

        return countRooms;
    }

    // returns amount of moves left for the player
    function makeMove(uint roomId, uint8 row, uint8 column) external onlyActivePlayer(roomId) returns(uint8){
        Room storage room = rooms[roomId];

        BoardState currentCellState = room.boardState[row][column];
        BoardState currentPlayerColor = playerColors[room.currentPlayerIndex];

        require(currentCellState != currentPlayerColor, "You cannot make move on your cell");
        validateMove(roomId, row, column);
        if (currentCellState == BoardState.FREE) {
            require(room.currentPlayerMoves >= 1, "You need at least 1 move");
            room.currentPlayerMoves -= 1;
            room.boardState[row][column] = currentPlayerColor;
        } else {
            require(room.currentPlayerMoves >= 3, "You need at least 3 moves left");
            room.currentPlayerMoves -= 3;
            room.boardState[row][column] = currentPlayerColor;
            // TODO: check tails
        }
        if (room.currentPlayerMoves == 0) {
            updateCurrentPlayer(roomId);
        }
        return room.currentPlayerMoves;
    }

    function validateMove(uint256 roomId, uint8 row, uint8 column) internal view {
        Room storage room = rooms[roomId];

        bool nearCellPresent = false;
        BoardState currentPlayerColor = playerColors[room.currentPlayerIndex];

        for(int8 horizontalShift = -1; horizontalShift <= 1; horizontalShift++) {
            for(int8 verticalShift = -1; verticalShift <= 1; verticalShift++) {
                int8 currRow = int8(row) + verticalShift;
                int8 currColumn = int8(column) + horizontalShift;
                if (currRow < 0 || currColumn < 0) {
                    continue;
                }
                if (currColumn >= int8(FIELD_HEIGHT) || currColumn >= int8(FIELD_WIDTH)) {
                    continue;
                }
                uint8 uCurrRow = uint8(currRow);
                uint8 uCurrColumn = uint8(currColumn);

                if (uCurrRow == row && uCurrColumn == column) {
                    continue;
                }
                if (room.boardState[uCurrRow][uCurrColumn] == currentPlayerColor) {
                    nearCellPresent = true;
                    break;
                }
            }
        }
        require(nearCellPresent, "Move is invalid: there is no cell with the same color nearby");
    }

    function updateRandomValue(uint256 roomId) internal {
        Room storage room = rooms[roomId];
        room.randomParameter = uint256(keccak256(abi.encodePacked(room.randomParameter, block.timestamp)));
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