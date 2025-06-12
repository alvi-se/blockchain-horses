// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {HorseRace} from "./HorseRace.sol";
import {console} from "forge-std/console.sol";

contract Shuffler is VRFConsumerBaseV2Plus {
    // ---------- Variables ----------

    uint256 s_subscriptionId;
    // Sepolia VRF Coordinator
    // address vrfCoordinator = 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B;
    address vrfCoordinator;
    bytes32 s_keyHash = 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae;
    uint32 callbackGasLimit = 1_000_000;
    uint16 requestConfirmations = 3;
    // uint32 numWords = 1;

    // Map requestId to raceId
    mapping(uint256 => uint256) private requestsToRaces;
    HorseRace private horseRace;

    // ---------- Structs ----------

    struct Request {
        uint256 requestId;
        uint256 raceId;
    }

    constructor(address _vrfCoordinator, uint256 subscriptionId) VRFConsumerBaseV2Plus(_vrfCoordinator) {
        vrfCoordinator = _vrfCoordinator;
        s_subscriptionId = subscriptionId;
    }

    // ---------- Modifiers ----------

    modifier onlyHorseRace() {
        require(msg.sender == address(horseRace), "You are not the horse race contract");
        _;
    }

    // ---------- Events ----------

    event StartShuffling(uint256 requestId, uint256 indexed raceId);
    event Shuffled(uint256 requestId, uint256 indexed raceId);

    // ---------- Functions ----------

    function setHorseRace(address horseRaceAddress) external onlyOwner {
        horseRace = HorseRace(horseRaceAddress);
    }

    function generateHorsePositions(uint256 raceId, uint32 horseCount, bool nativePayment)
        external
        onlyHorseRace
        returns (uint256)
    {
        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: s_keyHash,
                subId: s_subscriptionId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: horseCount,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    // Pay with native token
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: nativePayment})
                )
            })
        );

        emit StartShuffling(requestId, raceId);
        console.log("Shuffling raceId %d with requestId %d", raceId, requestId);

        return requestId;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        uint256 raceId = requestsToRaces[requestId];
        emit Shuffled(requestId, raceId);
        console.log("Shuffled raceId %d with requestId %d", raceId, requestId);
        horseRace.onRaceFinish(raceId, randomWords);
    }
}
