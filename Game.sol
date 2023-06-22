// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.0;

contract CastlediceGame {
    uint256 constant public FIELD_HEIGHT = 10;
    uint256 constant public FIELD_WIDTH = 10;  
    uint256 constant STANDART_MOVE_COST = 1;
    uint256 constant STRIKE_MOVE_COST = 3;
    uint256 constant TREE_RANGE_MIN = 2;
    uint256 constant TREE_RANGE_MAX = 2;
    uint256 constant TREES_MIN_AMOUNT = 1;
    uint256 constant TREES_MAX_AMOUNT = 5;
    

    Position bluePlayerStart = Position(0, 0);
    Position redPlayerStart = Position(9, 9);

    event FinishedGames(uint256 roomId, address winner);
    BoardState[] playerColors = [BoardState.BLUE, BoardState.RED];

    struct Room {
        address[] players;
        uint256 currentPlayerIndex;
        // mapping(uint256 => mapping(uint256 => BoardState)) boardState;
        BoardState[FIELD_HEIGHT][FIELD_WIDTH] boardState;
        uint256 currentPlayerMoves;
        uint256 randomParameter;
    }

    mapping(uint256 => Room) public rooms;
    uint256 public countRooms;

    constructor() public {
        countRooms = 0;
    }

    modifier onlyActivePlayer(uint roomId) {
        uint256 playerIndex = rooms[roomId].currentPlayerIndex;

        require(rooms[roomId].players[playerIndex] == msg.sender,
                "It is not your turn to make a move");
        _;
    }

    function createRoom(address[] calldata players) external returns (uint256) {
        countRooms++;
        Room storage room = rooms[countRooms];
        room.players = players;
        for (uint256 i = 0; i < FIELD_HEIGHT; i++) {
            for (uint256 j = 0; j < FIELD_WIDTH; j++) {
                room.boardState[i][j] = BoardState.FREE;
            }
        }
        room.boardState[bluePlayerStart.row][bluePlayerStart.column] = BoardState.BLUE;
        room.boardState[redPlayerStart.row][redPlayerStart.column] = BoardState.RED;
        
        room.randomParameter = uint256(keccak256(abi.encodePacked(
            room.players[0], 
            room.players[1],
            countRooms,
            blockhash(block.number - 1)
        )));

        updateCurrentPlayerMoves(countRooms);
        generateTrees(countRooms);

        return countRooms;
    }

    function generateTrees(uint256 roomId) internal {
        Room storage room = rooms[roomId];
        uint8[] memory random = new uint8[](32);
        uint256 currentRandom = 0;
        updateRandomValue(roomId);

        for (uint256 i = 0; i < 32; i++) {
            random[i] = uint8((room.randomParameter >> (8 * (31 - i))) & 0xFF);
        }
        uint256 amountOfTrees = TREES_MIN_AMOUNT + (random[currentRandom++]) % TREES_MAX_AMOUNT;

        for (uint256 i = 0; i < amountOfTrees; i++) {
            Position memory treePosition = Position(
                setRandomNumberInRange(random[currentRandom++], TREE_RANGE_MIN, TREE_RANGE_MAX),
                setRandomNumberInRange(random[currentRandom++], TREE_RANGE_MIN, TREE_RANGE_MAX)
                );
            room.boardState[treePosition.row][treePosition.column] = BoardState.TREE;
        }
    }

    function setRandomNumberInRange(uint8 random, uint256 minValue, uint256 maxValue) internal pure returns(uint8) {
        return uint8(minValue) + (random % uint8(maxValue));
    }

    function makeMove(uint256 roomId, uint256 row, uint256 column) external onlyActivePlayer(roomId) returns(uint256){
        Room storage room = rooms[roomId];

        BoardState currentCellState = room.boardState[row][column];
        BoardState currentPlayerColor = playerColors[room.currentPlayerIndex];

        require(currentCellState != currentPlayerColor, "You cannot make move on your cell");
        validateMove(roomId, row, column);
        if (currentCellState == BoardState.FREE) {
            require(room.currentPlayerMoves >= STANDART_MOVE_COST, "You don`t have enough moves left");
            room.currentPlayerMoves -= STANDART_MOVE_COST;
            room.boardState[row][column] = currentPlayerColor;
        } else {
            require(room.currentPlayerMoves >= STRIKE_MOVE_COST, "You don`t have enough moves left");
            room.currentPlayerMoves -= STRIKE_MOVE_COST;
            room.boardState[row][column] = currentPlayerColor;
            removeTails(roomId, getOppositeColor(currentPlayerColor));
        }
        if (room.currentPlayerMoves == 0) {
            updateCurrentPlayer(roomId);
        }
        return room.currentPlayerMoves;
    }

    function getOppositeColor(BoardState color) internal pure returns(BoardState) {
        if (color == BoardState.BLUE) {
            return BoardState.RED;
        }
        return BoardState.BLUE;
    }

    function validateMove(uint256 roomId, uint256 row, uint256 column) internal view {
        Room storage room = rooms[roomId];

        bool nearCellPresent = false;
        BoardState currentPlayerColor = playerColors[room.currentPlayerIndex];

        for (int256 horizontalShift = -1; horizontalShift <= 1; horizontalShift++) {
            for (int256 verticalShift = -1; verticalShift <= 1; verticalShift++) {
                int256 currRow = int256(row) + verticalShift;
                int256 currColumn = int256(column) + horizontalShift;
                if (currRow < 0 || currColumn < 0) {
                    continue;
                }
                if (currColumn >= int256(FIELD_HEIGHT) || currColumn >= int256(FIELD_WIDTH)) {
                    continue;
                }
                uint256 uCurrRow = uint256(currRow);
                uint256 uCurrColumn = uint256(currColumn);

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

    function getBoardArray(uint256 roomId) external view returns (uint8[] memory) {
        Room storage room = rooms[roomId];
        uint8[] memory result = new uint8[](FIELD_HEIGHT * FIELD_WIDTH);
        for (uint256 row = 0; row < FIELD_HEIGHT; row++) {
            for (uint256 col = 0; col < FIELD_WIDTH; col++) {
                result[row * FIELD_WIDTH + col] = uint8(room.boardState[row][col]);
            }
        }
        return result;
    }

    function removeRedTails(uint256 roomId) internal {
        Room storage room = rooms[roomId];
        bool[10][10] memory isGood;
        isGood[redPlayerStart.row][redPlayerStart.column] = true;
        
        for (uint256 row = redPlayerStart.row; row >= 0; row--) {
            for (uint256 column = redPlayerStart.column; column >= 0; column--) {
                if (room.boardState[row][column] == BoardState.RED) {
                    bool needToRemove = true;
                    if (row + 1 < FIELD_HEIGHT && isGood[row+1][column]) {
                        needToRemove = false;
                    }
                    if (column + 1 < FIELD_WIDTH && isGood[row][column+1]) {
                        needToRemove = false;
                    }
                    if (column + 1 < FIELD_WIDTH && row + 1 < FIELD_HEIGHT && isGood[row+1][column+1]) {
                        needToRemove = false;
                    }

                    if (needToRemove) {
                        room.boardState[row][column] = BoardState.FREE;
                    } else {
                        isGood[row][column] = true;
                    }
                }
            }
        }


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
        room.currentPlayerMoves = uint256((room.randomParameter % 5) + 1);
    }

    function isGameFinished(uint256 roomId) public view returns (bool) {
        Room storage room = rooms[roomId];
        return room.boardState[0][0] == BoardState.RED || room.boardState[9][9] == BoardState.BLUE;            
    }

    function getGameWinner(uint256 roomId) public view returns (address) {
        Room storage room = rooms[roomId];
        if (room.boardState[bluePlayerStart.row][bluePlayerStart.column] == BoardState.RED) {
            return room.players[1];
        }
        if (room.boardState[redPlayerStart.row][redPlayerStart.column] == BoardState.BLUE) {
            return room.players[0];
        }
        revert("Game is not finished, there is no winner");
    }

    function getCurrentPlayerMovesLeft(uint256 roomId) public view returns (uint256) {
        return rooms[roomId].currentPlayerMoves;
    }

    function getCurrentPlayerIndex(uint256 roomId) public view returns (uint256) {
        return rooms[roomId].currentPlayerIndex;
    }
    
}

enum BoardState {
    FREE,
    BLUE,
    RED,
    TREE    
}

struct Position {
    uint256 row;
    uint256 column;
}