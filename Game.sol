pragma solidity ^0.6.0;


contract BoardGame {
    struct Room {
        address[] players;
        mapping(address => bool) isPlayerActive;
        uint currentPlayerIndex;
        uint[10][10] boardState;
    }

    mapping(uint => Room) public rooms;
    uint public countRooms;

    constructor() public {
        countRooms = 0;
    }

    modifier onlyActivePlayer(uint roomId) {
        require(rooms[roomId].isPlayerActive[msg.sender], "You are not a player of this room");
    }

    function createRoom() external {
        // todo
    }

    function joinRoom() external {
        // todo
    }

    function makeMove(uint roomId, uint row, uint col) external onlyActivePlayer(roomId){
        Room storage room = rooms[roomId];

        // todo: impement game logic;

        room.currentPlayerIndex ^= 1;
    }
}