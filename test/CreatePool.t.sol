// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";
import {ModernDex, PoolData} from "../src/ModernDex.sol";
import {Helpers} from "./Helpers.sol";
import {IModernDex} from "../src/interface/IModernDex.sol";

contract CreatePoolTest is Test {
    uint256 public constant amount1 = 300 ether;
    uint256 public constant amount2 = 1000 ether;
    uint256 public constant amount3 = 500 ether;
    uint256 public constant amount4 = 1200 ether;

    MockERC20 public token1;
    MockERC20 public token2;
    MockERC20 public token3;
    ModernDex public dex;

    function setUp() public {
        token1 = new MockERC20("Token1", "TK1");
        token2 = new MockERC20("Token2", "TK2");
        token3 = new MockERC20("Token3", "TK3");
        dex = new ModernDex();

        token1.approve(address(dex), amount1);
        token2.approve(address(dex), amount2 + amount3);
        token3.approve(address(dex), amount4);
    }

    function testRegisterPools() public {
        (address tokenA, address tokenB) = Helpers.orderTokens(address(token1), address(token2));
        dex.createPool(address(token1), amount1, address(token2), amount2);

        token2.approve(address(dex), amount3);
        (address tokenC, address tokenD) = Helpers.orderTokens(address(token2), address(token3));
        dex.createPool(address(token2), amount3, address(token3), amount4);

        bytes32 expectedIdPool1 = Helpers.getPoolId(tokenA, tokenB);
        bytes32 expectedIdPool2 = Helpers.getPoolId(tokenC, tokenD);

        assertEq(dex.tokensToPool(tokenA, tokenB), expectedIdPool1);
        assertEq(dex.tokensToPool(tokenC, tokenD), expectedIdPool2);
    }

    function testAccountForDeposit() public {
        (address tokenA, uint256 liquidityA, address tokenB, uint256 liquidityB) =
            Helpers.orderTokensData(address(token1), amount1, address(token2), amount2);
        dex.createPool(address(token1), amount1, address(token2), amount2);

        (address tokenC, uint256 liquidityC, address tokenD, uint256 liquidityD) =
            Helpers.orderTokensData(address(token2), amount3, address(token3), amount4);
        dex.createPool(address(token2), amount3, address(token3), amount4);

        bytes32 pool1Id = Helpers.getPoolId(tokenA, tokenB);
        bytes32 pool2Id = Helpers.getPoolId(tokenC, tokenD);

        PoolData memory pool1Data = dex.getPoolData(pool1Id);
        PoolData memory pool2Data = dex.getPoolData(pool2Id);

        assertEq(pool1Data.tokenA, tokenA);
        assertEq(pool1Data.liquidityA, liquidityA);
        assertEq(pool1Data.tokenB, tokenB);
        assertEq(pool1Data.liquidityB, liquidityB);

        assertEq(pool1Data.tokenA, tokenC);
        assertEq(pool2Data.liquidityA, liquidityC);
        assertEq(pool2Data.tokenB, tokenD);
        assertEq(pool2Data.liquidityB, liquidityD);
    }

    function testTokenCollection() public {
        dex.createPool(address(token1), amount1, address(token2), amount2);
        assertEq(MockERC20(token1).balanceOf(address(dex)), amount1);
        assertEq(MockERC20(token2).balanceOf(address(dex)), amount2);

        dex.createPool(address(token2), amount3, address(token3), amount4);
        assertEq(MockERC20(token2).balanceOf(address(dex)), amount2 + amount3);
        assertEq(MockERC20(token3).balanceOf(address(dex)), amount4);
    }

    function testAccountForShares() public {
        (address tokenA, address tokenB) = Helpers.orderTokens(address(token1), address(token2));
        bytes32 poolId = Helpers.getPoolId(tokenA, tokenB);

        dex.createPool(address(token1), amount1, address(token2), amount2);
        uint256 shareAmount = dex.shares(address(this), poolId);

        assertEq(shareAmount, 1000);
    }

    function testEmitEvent() public {
        (address tokenA, uint256 liquidityA, address tokenB, uint256  liquidityB) = Helpers.orderTokensData(address(token1), amount1, address(token2), amount2);
        bytes32 poolId = Helpers.getPoolId(tokenA, tokenB);

        vm.expectEmit(true, true, true, true);
        emit IModernDex.PoolCreated(poolId, tokenA, liquidityA, tokenB, liquidityB);

        dex.createPool(address(token1), amount1, address(token2), amount2);
    }
}
