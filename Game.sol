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

    function createRoom() external {
        // todo
    }

    function joinRoom() external {
        // todo
    }

    function makeRoom() external {
        // todo
    }
}