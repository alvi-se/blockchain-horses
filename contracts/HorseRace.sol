// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;


contract HorseRace {

    address public owner;
    Race[] public races;

    struct Race {
        uint[] horses;
        uint horseCount;
        mapping (address => uint) bets;
        bool finished;
    }
    
    constructor() {
        owner = msg.sender;
    }

    function bet() public payable {

    }

    function prepareRace(uint horseCount) public {
        require(races[races.length - 1].finished, "The last race has not finished");
        /*

        Race race = Race({
            horses: new uint[horseCount]
        });
        */

    }

}
