// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";
import {ModernDex, PoolData} from "../src/ModernDex.sol";
import {MAX, Helpers} from "./Helper.sol";

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

        dex.createPool(
            address(token1),
            token1Amount,
            address(token2),
            token2Amount
        );
    }

    function test_SwapOneWay(uint256 amountIn) public {
        vm.assume(amountIn <= MAX - amountIn);

        uint256 invariant = token1Amount * token2Amount;
        uint256 liquityIn = token1Amount;
        uint256 newLiquidityIn = liquityIn + amountIn;
        uint256 newLiquidityOut = invariant / newLiquidityIn;
        uint256 liquityOut = token2Amount;
        uint256 expectedAmountOut = liquityOut - newLiquidityOut;

        uint256 initialBalance = token2.balanceOf(address(this));
        token1.approve(address(dex), amountIn);
        dex.swap(address(token1), amountIn, address(token2));
        uint256 finalBalance = token2.balanceOf(address(this));

        assertEq(finalBalance - initialBalance, expectedAmountOut);
    }

    // function test_SwapTheOtherWay(uint256 amountIn) public {
    //     // uint256 amountIn = 1 ether;
    //     uint256 expectedAmountOut = (amountIn * token1Amount) / token2Amount;

    //     uint256 initialBalance = token1.balanceOf(address(this));
    //     token2.approve(address(dex), amountIn);
    //     dex.swap(address(token2), amountIn, address(token1));
    //     uint256 finalBalance = token1.balanceOf(address(this));

    //     assertEq(finalBalance - initialBalance, expectedAmountOut);
    // }
}
