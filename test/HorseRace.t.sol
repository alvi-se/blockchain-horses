// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import {Test, console} from 'forge-std/Test.sol';
import {HorseRace} from '../src/HorseRace.sol';
import {Shuffler} from '../src/Shuffler.sol';
import {VRFCoordinatorV2_5Mock} from '@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol';

contract HorseRaceTest is Test {
    VRFCoordinatorV2_5Mock vrfMock;
    HorseRace horseRace;
    Shuffler shuffler;
    uint256 vrfSubscription;

    constructor() {
        vm.startBroadcast();

        vrfMock = new VRFCoordinatorV2_5Mock(100_000_000_000_000_000, 1000000000, 1000);
        vrfSubscription = vrfMock.createSubscription();
        vrfMock.fundSubscription(vrfSubscription, 100000000000000000000); // 100 LINK

        shuffler = new Shuffler(address(vrfMock), vrfSubscription);
        vrfMock.addConsumer(vrfSubscription, address(shuffler));

        horseRace = new HorseRace(address(shuffler));
        shuffler.setHorseRace(address(horseRace));

        vm.stopBroadcast();

        console.log('VRF Subscription ID:', vrfSubscription);
        console.log('VRF Coordinator Address:', address(vrfMock));
        console.log('Shuffler Address:', address(shuffler));
        console.log('HorseRace Address:', address(horseRace));
    }

    function test_CreateRaceWithOneHorse() public {
        uint256 horses = 1;
        vm.expectRevert();
        horseRace.createRace(horses);
    }

    function test_CreateRace() public {
        uint256 horses = 5;
        horseRace.createRace(horses);
    }

    function test_CreateRaceWithTooManyHorses() public {
        uint256 tooManyHorses = 256;
        vm.expectRevert();
        horseRace.createRace(tooManyHorses);
    }

    function test_BetOnRace() public {
        uint256 race = horseRace.createRace(5);
        uint256 horse = 1;
        horseRace.bet{value: 2000}(race, horse);
    }

    function test_BetOnRaceWithInvalidHorse() public {
        uint256 race = horseRace.createRace(5);
        uint256 horse = 5;
        vm.expectRevert();
        horseRace.bet{value: 2000}(race, horse);
    }

    function test_BetOnRaceWithInvalidRace() public {

        uint256 horse = 1;
        vm.expectRevert();
        horseRace.bet{value: 2000}(10000, horse);
    }

    function test_BetOnRaceWithSmallValue() public {
        uint256 race = horseRace.createRace(5);
        uint256 horse = 1;
        vm.expectRevert();
        horseRace.bet{value: 999}(race, horse);
    }

    function test_BetOnRaceWithBigValue() public {
        uint256 race = horseRace.createRace(5);
        uint256 horse = 1;
        vm.expectRevert();
        horseRace.bet{value: 1_000_000}(race, horse);
    }

    function test_StartRace() public {
        uint256 race = horseRace.createRace(5);
        uint256 horse = 1;
        horseRace.bet{value: 2000}(race, horse);
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
        shuffler.shuffle(1, 10);
    }
}

