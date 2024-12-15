// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "hardhat/console.sol";

contract ModernDex {
    mapping(address tokenA => mapping(address tokenB => bytes32 poolId))
        public tokensToPools;
    mapping(bytes32 poolId => address[] tokens) public idToTokens;

    function createPool(address token1, address token2) external {
        (address tokenA, address tokenB) = token1 < token2
            ? (token1, token2)
            : (token2, token1);
        bytes32 poolId = keccak256(abi.encode(tokenA, tokenB));

        tokensToPools[tokenA][tokenB] = poolId;
        idToTokens[poolId] = [tokenA, tokenB];
    }
}
