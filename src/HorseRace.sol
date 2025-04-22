// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import './Shuffler.sol';
import {console} from "forge-std/console.sol";

contract HorseRace {

    // ---------- Variables ----------

    address private owner;
    Race[] public races;
    Shuffler private shuffler;
    uint constant private HOUSE_EDGE = 69;

    // Tells whether the address has a bet on raceId
    // This is needed to quickly check if the address has a bet on a race
    mapping (address => mapping (uint256 => bool)) private betOwners;
    // Same as above but for race owners
    mapping (address => mapping (uint256 => bool)) private raceOwners;

    mapping (address => uint256) private winnings;

    // ---------- Structs --------

    struct Race {
        uint256[] horses;
        // Map horseId to address, and address to amount
        // mapping (uint256 => mapping (address => uint256)) bets;
        // Bet[] bets;
        mapping (uint256 => Bet[]) bets;
        uint256 winningHorse;
        RaceStatus status;
        address creator;
    }

    enum RaceStatus {
        NOT_STARTED,
        IN_PROGRESS,
        FINISHED
    }

    struct Bet {
        address owner;
        uint256 horseId;
        uint256 amount;
    }
    

    // ---------- Modifiers ----------

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    modifier onlyShuffler() {
        require(msg.sender == address(shuffler), "You are not the shuffler");
        _;
    }


    // ---------- Constructor ----------

    constructor(address shufflerAddress) {
        owner = msg.sender;
        shuffler = Shuffler(shufflerAddress);
    }

    // ---------- Functions ----------

    function bet(uint256 raceId, uint256 horseId) external payable {
        require(msg.value > 1000 && msg.value < 1_000_000, "Only bets between 1000 and 1000000 wei are allowed");
        require(raceId < races.length, "No such race exists");
        Race storage race = races[raceId];

        require(race.status == RaceStatus.NOT_STARTED, "Can't bet on started race");
        require(horseId < race.horses.length, "Horse index out of range");

        race.bets[horseId].push(Bet({
            owner: msg.sender,
            horseId: horseId,
            amount: msg.value
        }));
        
        // race.bets[horseId][msg.sender] += msg.value;
        if (!betOwners[msg.sender][raceId]) {
            betOwners[msg.sender][raceId] = true;
        }

        console.log("Bet placed on race %d, horse %d for %d wei", raceId, horseId, msg.value);
    }

    function createRace(uint256 horseCount) external returns (uint256) {
        require(horseCount > 1 && horseCount < 256, "Can only play with 1 < horseCount < 256");

        Race storage race = races.push();
        race.horses = new uint256[](horseCount);
        race.creator = msg.sender;
        race.status = RaceStatus.NOT_STARTED;

        raceOwners[msg.sender][races.length - 1] = true;

        console.log("Race %d created with %d horses", races.length - 1, horseCount);
        return races.length - 1;
    }

    function startRace(uint256 raceIndex) external {
        require(raceIndex < races.length, "Race does not exist");

        Race storage race = races[raceIndex];
        require(msg.sender == race.creator, "You are not the creator of this race");
        require(race.status == RaceStatus.NOT_STARTED, "Race already finished");

        race.status = RaceStatus.IN_PROGRESS;

        uint32 horseCount = uint32(race.horses.length);

        console.log("Starting race %d", raceIndex);
        shuffler.shuffle(raceIndex, horseCount);
    }

    function onRaceFinish(uint256 raceId, uint256[] calldata randomWords) external onlyShuffler {
        Race storage race = races[raceId];
        race.status = RaceStatus.FINISHED;
        race.horses = randomWords;

        uint256 min = type(uint256).max;

        for (uint256 i = 0; i < randomWords.length; i++) {
            if (randomWords[i] < min) {
                min = i;
            }
        }
        race.winningHorse = min;

        Bet[] storage winningBets = race.bets[min];

        for (uint256 i = 0; i < winningBets.length; i++) {
            Bet storage b = winningBets[i];
            uint256 amount = b.amount;
            // 1 / winningBets.length probability of winning
            amount = amount * race.horses.length;
            // TODO check if the computation is correct, Copilot wrote it
            uint256 winningsAmount = (amount * (1000 - HOUSE_EDGE)) / 1000;
            winnings[b.owner] += winningsAmount;
        }
    }


    function withdraw() external {
        uint256 amount = winnings[msg.sender];
        require(amount > 0, "No winnings to withdraw");
        // FIRST put the amount to 0, then transfer, to avoid re-entrancy attacks
        winnings[msg.sender] = 0;
        address payable to = payable(msg.sender);
        to.transfer(amount);
    }
}
