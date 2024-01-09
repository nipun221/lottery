// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Lottery {
    address public manager;
    address payable[] public participants;
    address payable  winner;

    constructor() {
        manager = msg.sender;
    }

    receive() external payable {
        require(msg.value == 1 ether);
        participants.push(payable(msg.sender));
    }

    function getBalance() public view returns(uint) {
        require(msg.sender == manager);
        return address(this).balance;
    }

    function random() public view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.prevrandao, block.timestamp, participants.length)));
    } 

    function selectWinner() public {
        require(msg.sender == manager);
        require(participants.length >= 3);
        uint r = random();
        uint index = r % participants.length;
        winner = participants[index];
        winner.transfer(getBalance());
    }

    function getWinner() public view returns(address) {
        return winner;
    }

    function reset() public {
        require(msg.sender == manager);
        require(participants.length > 0, "No participants to reset");
        require(isParticipant(winner), "Winner is not a participant");

        participants = new address payable[](0);
        winner = payable(address(0));
    }

    function isParticipant(address participant) internal view returns (bool) {
        for (uint i = 0; i < participants.length; i++) {
            if (participants[i] == participant) {
                return true;
            }
        }
        return false;
    }
}
