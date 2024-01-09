// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";

contract Lottery is VRFConsumerBaseV2, ConfirmedOwner {
    address public manager;
    address payable[] public participants;
    address payable public winner;
    uint256 public randomResult;
    bytes32 internal keyHash;
    uint256 internal fee;
    uint64 public s_subscriptionId;

    struct RequestStatus {
        bool fulfilled;
        bool exists;
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus) public s_requests;
    VRFCoordinatorV2Interface COORDINATOR;

    uint256[] public requestIds;
    uint256 public lastRequestId;

    bytes32 public vrfKeyHash;
    uint32 public callbackGasLimit = 100000;
    uint16 public requestConfirmations = 3;
    uint32 public numWords = 1;

    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    constructor(uint64 subscriptionId)
        VRFConsumerBaseV2(0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625)
        ConfirmedOwner(msg.sender)
    {
        manager = msg.sender;
        COORDINATOR = VRFCoordinatorV2Interface(
            0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625
        );
        s_subscriptionId = subscriptionId;
        vrfKeyHash = 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;
    }

    receive() external payable {
        require(msg.value == 1 ether, "Contribute exactly 1 ether to participate");
        participants.push(payable(msg.sender));
    }

    function requestRandomWinner() external onlyOwner returns (uint256 requestId) {
        requestId = COORDINATOR.requestRandomWords(
            vrfKeyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        s_requests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        require(s_requests[_requestId].exists, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        selectWinner(_randomWords);
        emit RequestFulfilled(_requestId, _randomWords);
    }

    function selectWinner(uint256[] memory _randomWords) internal {
        uint256 index = _randomWords[0] % participants.length;
        winner = participants[index];
        winner.transfer(address(this).balance);
    }

    function getWinner() external view returns (address) {
        return winner;
    }

    function reset() external onlyOwner {
        participants = new address payable[](0);
        winner = payable(address(0));
        randomResult = 0;
    }
}