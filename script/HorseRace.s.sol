// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import 'forge-std/Script.sol';
import '../src/HorseRace.sol';
import '../src/Shuffler.sol';
import '@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol';

/*
To fix overflow/underflow errors in the script, check here
https://github.com/smartcontractkit/chainlink-brownie-contracts/issues/33
 */


contract HorseRaceScript is Script {
    VRFCoordinatorV2_5Mock vrfMock;
    HorseRace horseRace;
    Shuffler shuffler;
    uint256 vrfSubscription;

    function run() public {
        vm.startBroadcast();

        vrfMock = new VRFCoordinatorV2_5Mock(100_000_000_000_000_000, 1000000000, 1000);
        vrfSubscription = vrfMock.createSubscription();
        vrfMock.fundSubscription(vrfSubscription, 100000000000000000000); // 100 LINK

        shuffler = new Shuffler(address(vrfMock), vrfSubscription);
        horseRace = new HorseRace(address(shuffler));
        shuffler.setHorseRace(address(horseRace));

        vm.stopBroadcast();

        console.log('VRF Subscription ID:', vrfSubscription);
        console.log('VRF Coordinator Address:', address(vrfMock));
        console.log('Shuffler Address:', address(shuffler));
        console.log('HorseRace Address:', address(horseRace));
    }
}
