// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";
import {ModernDex, PoolData} from "../src/ModernDex.sol";
import {MAX, Helpers} from "./Helpers.sol";
import {IModernDex} from "../src/interface/IModernDex.sol";

contract SwapTest is Test {
    uint256 public constant token1Amount = 300 ether;
    uint256 public constant token2Amount = 1000 ether;

    MockERC20 public token1;
    MockERC20 public token2;
    ModernDex public dex;

    function setUp() public {
        token1 = new MockERC20("Token1", "TK1");
        token2 = new MockERC20("Token2", "TK2");
        dex = new ModernDex();

        token1.approve(address(dex), token1Amount);
        token2.approve(address(dex), token2Amount);

        dex.createPool(address(token1), token1Amount, address(token2), token2Amount);
    }

    function testSwapOneWay(uint256 amountIn) public {
        vm.assume(amountIn <= MAX - token1Amount);
        vm.assume(amountIn < MAX / 2);

        uint256 expectedAmountOut = getAmountOut(token1Amount, token2Amount, amountIn);

        uint256 initialBalance = token2.balanceOf(address(this));
        token1.approve(address(dex), amountIn);
        dex.swap(address(token1), amountIn, address(token2));
        uint256 finalBalance = token2.balanceOf(address(this));

        assertEq(finalBalance - initialBalance, expectedAmountOut);
    }

    function testSwapTheOtherWay(uint256 amountIn) public {
        vm.assume(amountIn <= MAX - token2Amount);
        vm.assume(amountIn < MAX / 2);

        uint256 expectedAmountOut = getAmountOut(token2Amount, token1Amount, amountIn);

        uint256 initialBalance = token1.balanceOf(address(this));
        token2.approve(address(dex), amountIn);
        dex.swap(address(token2), amountIn, address(token1));
        uint256 finalBalance = token1.balanceOf(address(this));

        assertEq(finalBalance - initialBalance, expectedAmountOut);
    }

    function testEmitEvent() public {
        uint256 amountIn = 223 ether;
        uint256 amountOut = getAmountOut(token1Amount, token2Amount, amountIn);
        token1.approve(address(dex), amountIn);
        
        vm.expectEmit(true, true, true, true);
        emit IModernDex.Swap(address(this), address(token1), amountIn, address(token2), amountOut);

        dex.swap(address(token1), amountIn, address(token2));
    }


    function getAmountOut(uint256 liquidityIn, uint256 liquidityOut, uint256 amountIn) private pure returns (uint256) {
        uint256 k = liquidityIn * liquidityOut;

        uint256 newLiquidityIn = liquidityIn + amountIn;
        uint256 newLiquidityOut = k / newLiquidityIn;
        uint256 expectedAmountOut = liquidityOut - newLiquidityOut;
        uint256 expectedAmountOutMinFee = expectedAmountOut * 998 / 1000;

        return expectedAmountOutMinFee;
    }
}
