// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;


contract HorseRace {

    address public owner;
    Race[] public races;

    struct Race {
        uint[] horses;
        mapping (uint => mapping (address => uint)) bets;
        bool finished;
        address creator;
    }

    
    constructor() {
        owner = msg.sender;
    }

    function bet(uint raceId, uint horseId) public payable {
        require(msg.value > 0, "Negative amount was sent");
        require(raceId < races.length, "No such race exists");
        Race storage race = races[raceId];

        require(!race.finished, "Can't bet on finished race");
        require(horseId < race.horses.length, "Horse index out of range");
        
        race.bets[horseId][msg.sender] += msg.value;
    }

    function createRace(uint horseCount) public returns (uint) {

        Race storage race = races.push();
        race.horses = new uint[](horseCount);
        race.creator = msg.sender;
        race.finished = false;

        return races.length - 1;
    }

    function startRace(uint raceIndex) public {
        require(raceIndex < races.length, "Race does not exist");

        Race storage race = races[raceIndex];
        require(msg.sender == race.creator, "You are not the creator of this race");
        require(!race.finished, "Race already finished");

        // Finish
    }
}
