// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IModernDex {
	event PoolCreated(bytes32 indexed poolId, address indexed tokenA, uint256 liquidityA, address indexed tokenB, uint256 liquidityB);
	event Swap(address indexed account, address indexed tokenIn, uint256 amountIn, address indexed tokenOut, uint256 amountOut);
}