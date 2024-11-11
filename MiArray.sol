// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract MiArray {
    struct SenderValue {
        address sender;
        uint256 value;
    }

    SenderValue[] public senderValues;

    function storeSenderValue() public payable {
        senderValues.push(SenderValue(msg.sender, msg.value));
    }

    function listSendersAndValues() public view returns (SenderValue[] memory) {
        return senderValues;
    }
}