// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";
import {ModernDex, PoolData} from "../src/ModernDex.sol";

contract CreatePoolTest is Test {
    // uint256 public constant MAX = type(uint256).max;

    uint256 public constant token1Amount = 300 ether;
    uint256 public constant token2Amount = 1000 ether;

    MockERC20 public token1;
    MockERC20 public token2;
    ModernDex public dex;

    function orderTokens(
        address _token1,
        address _token2
    ) private pure returns (address tokenA, address tokenB) {
        (tokenA, tokenB) = _token1 < _token2
            ? (address(_token1), address(_token2))
            : (address(_token2), address(_token1));
    }

    function getPoolId(
        address _token1,
        address _token2
    ) private pure returns (bytes32) {
        (address tokenA, address tokenB) = orderTokens(_token1, _token2);
        return keccak256(abi.encode(tokenA, tokenB));
    }

    function setUp() public {
        token1 = new MockERC20("Token1", "TK1");
        token2 = new MockERC20("Token2", "TK2");
        dex = new ModernDex();

        token1.approve(address(dex), token1Amount);
        token2.approve(address(dex), token2Amount);
    }

    function test_DepositTokens() public {
        dex.createPool(
            address(token1),
            token1Amount,
            address(token2),
            token2Amount
        );

        assertEq(token1.balanceOf(address(dex)), token1Amount);
        assertEq(token2.balanceOf(address(dex)), token2Amount);
    }

    function test_RegisterPool() public {
        (address tokenA, address tokenB) = orderTokens(
            address(token1),
            address(token2)
        );
        bytes32 expectedId = getPoolId(tokenA, tokenB);

        dex.createPool(
            address(token1),
            token1Amount,
            address(token2),
            token2Amount
        );

        assertEq(dex.tokensToPool(tokenA, tokenB), expectedId);
    }

    function test_AccountForDeposit() public {
        (address tokenA, address tokenB) = orderTokens(
            address(token1),
            address(token2)
        );
        bytes32 id = getPoolId(tokenA, tokenB);

        dex.createPool(
            address(token1),
            token1Amount,
            address(token2),
            token2Amount
        );

        PoolData memory poolData = dex.getPoolData(id);

        assertEq(poolData.tokenA, tokenA);
        assertEq(
            poolData.liquidityA,
            MockERC20(tokenA).balanceOf(address(dex))
        );
        assertEq(poolData.tokenB, tokenB);
        assertEq(
            poolData.liquidityB,
            MockERC20(tokenB).balanceOf(address(dex))
        );
    }
}
