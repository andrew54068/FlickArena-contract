// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./FlickArenaBet.sol";

contract FlickArenaBetFactory {
    event GameCreated(address gameAddress, address host, uint256 targetScore, uint256 maxRounds);

    function createGame(uint256 _targetScore, uint256 _maxRounds) external returns (address) {
        FlickArenaBet newGame = new FlickArenaBet(msg.sender, _targetScore, _maxRounds);
        emit GameCreated(address(newGame), msg.sender, _targetScore, _maxRounds);
        return address(newGame);
    }
}