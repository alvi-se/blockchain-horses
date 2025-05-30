// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import {Test, console} from "forge-std/Test.sol";
import {HorseRace} from "../src/HorseRace.sol";
import {Shuffler} from "../src/Shuffler.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract HorseRaceTest is Test {
    VRFCoordinatorV2_5Mock vrfMock;
    HorseRace horseRace;
    Shuffler shuffler;
    uint256 vrfSubscription;

    constructor() {
        vrfMock = new VRFCoordinatorV2_5Mock(100_000_000_000_000_000, 1000000000, 10_000_000_000_000_000_000);
        vrfSubscription = vrfMock.createSubscription();
        vrfMock.fundSubscription(vrfSubscription, 100_000_000_000_000_000_000); // 100 LINK

        shuffler = new Shuffler(address(vrfMock), vrfSubscription);
        vm.deal(address(shuffler), 1 ether);
        vrfMock.addConsumer(vrfSubscription, address(shuffler));

        horseRace = new HorseRace(payable(address(shuffler)));
        shuffler.setHorseRace(address(horseRace));
        vm.deal(address(horseRace), 1 ether);

        console.log("VRF Subscription ID:", vrfSubscription);
        console.log("VRF Coordinator Address:", address(vrfMock));
        console.log("Shuffler Address:", address(shuffler));
        console.log("HorseRace Address:", address(horseRace));
    }

    function test_CreateRaceWithOneHorse() public {
        uint8 horses = 1;
        vm.expectRevert();
        horseRace.createRace(horses);
    }

    function test_CreateRace() public {
        uint8 horses = 5;
        horseRace.createRace(horses);
    }

    function test_BetOnRace() public {
        uint256 race = horseRace.createRace(5);
        uint8 horse = 1;
        horseRace.bet{value: 2000 gwei}(race, horse);
    }

    function test_BetOnRaceWithInvalidHorse() public {
        uint256 race = horseRace.createRace(5);
        uint8 horse = 5;
        vm.expectRevert();
        horseRace.bet{value: 2000 gwei}(race, horse);
    }

    function test_BetOnRaceWithInvalidRace() public {
        uint8 horse = 1;
        vm.expectRevert();
        horseRace.bet{value: 2000 gwei}(10000, horse);
    }

    function test_BetOnRaceWithSmallValue() public {
        uint256 race = horseRace.createRace(5);
        uint8 horse = 1;
        vm.expectRevert();
        horseRace.bet{value: 999 gwei}(race, horse);
    }

    function test_BetOnRaceWithBigValue() public {
        uint256 race = horseRace.createRace(5);
        uint8 horse = 1;
        vm.expectRevert();
        horseRace.bet{value: 1_000_000 gwei}(race, horse);
    }

    function test_StartRace() public {
        uint256 race = horseRace.createRace(5);
        uint8 horse = 1;
        horseRace.bet{value: 2000 gwei}(race, horse);
        horseRace.startRace(race);
    }

    function test_StartRaceWithInvalidRace() public {
        vm.expectRevert();
        horseRace.startRace(10000);
    }

    function test_StartRaceWithoutPermission() public {
        uint256 race = horseRace.createRace(5);
        address fake = address(0x1337);
        vm.prank(fake);
        vm.expectRevert();
        horseRace.startRace(race);
    }

    function test_ShuffleWithoutPermission() public {
        vm.expectRevert();
        shuffler.generateHorsePositions(1, 10, false);
    }

    function test_Shuffle() public {
        vm.prank(address(horseRace));
        uint256 requestId = shuffler.generateHorsePositions(1, 10, false);
        vrfMock.fulfillRandomWords(requestId, address(shuffler));
    }

    function test_FinishRace() public {
        uint256 race = horseRace.createRace(5);
        uint8 horse = 1;
        horseRace.bet{value: 2000 gwei}(race, horse);
        uint256 requestId = horseRace.startRace(race);
        
        vrfMock.fulfillRandomWords(requestId, address(shuffler));

        console.log(horseRace.getWinningHorse(race));

    }

    function test_WinRace() public {
        uint256 raceId = horseRace.createRace(5);
        uint8 horse = 0;
        horseRace.bet{value: 2000 gwei}(raceId, horse);
        horseRace.startRace(raceId);
        
        vm.prank(address(shuffler));
        uint256[] memory positions = new uint256[](5);
        // We make horse 0 win
        positions[0] = 4;
        positions[1] = 3;
        positions[2] = 2;
        positions[3] = 1;
        positions[4] = 0;
        horseRace.onRaceFinish(raceId, positions);

        assertEq(horseRace.getWinningHorse(raceId), horse, "Winning horse should be 0");
    }

    function test_Withdraw() public {
        uint256 raceId = horseRace.createRace(5);
        uint8 horse = 0;
        horseRace.bet{value: 2000 gwei}(raceId, horse);
        horseRace.startRace(raceId);
        
        vm.startPrank(address(shuffler));
        uint256[] memory positions = new uint256[](5);
        // We make horse 0 win
        positions[0] = 4;
        positions[1] = 3;
        positions[2] = 2;
        positions[3] = 1;
        positions[4] = 0;
        horseRace.onRaceFinish(raceId, positions);

        assertEq(horseRace.getWinningHorse(raceId), horse, "Winning horse should be 0");
        
        vm.stopPrank();
        horseRace.withdraw();
    }
}
