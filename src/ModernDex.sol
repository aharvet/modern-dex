// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

struct PoolData {
    address tokenA;
    uint256 liquidityA;
    address tokenB;
    uint256 liquidityB;
}

contract ModernDex {
    using SafeERC20 for IERC20;

    mapping(address tokenA => mapping(address tokenB => bytes32 poolId))
        public tokensToPool;
    mapping(bytes32 poolId => PoolData poolData) public idToPool;

    function getData(bytes32 id) public view returns (PoolData memory) {
        return idToPool[id];
    }

    function createPool(
        address token1,
        uint256 token1Amount,
        address token2,
        uint256 token2Amount
    ) external {
        (
            address tokenA,
            uint256 liquidityA,
            address tokenB,
            uint256 liquidityB
        ) = token1 < token2
                ? (token1, token1Amount, token2, token2Amount)
                : (token2, token2Amount, token1, token1Amount);
        bytes32 poolId = keccak256(abi.encode(tokenA, tokenB));

        tokensToPool[tokenA][tokenB] = poolId;
        idToPool[poolId] = PoolData({
            tokenA: tokenA,
            liquidityA: liquidityA,
            tokenB: tokenB,
            liquidityB: liquidityB
        });

        IERC20(token1).safeTransferFrom(
            msg.sender,
            address(this),
            token1Amount
        );
        IERC20(token2).safeTransferFrom(
            msg.sender,
            address(this),
            token2Amount
        );
    }

    function swap(
        address tokenIn,
        uint256 amountIn,
        address tokenOut
    ) external {
        uint256 tokenInAmount = IERC20(tokenIn).balanceOf(address(this));
        uint256 tokenOutAmount = IERC20(tokenOut).balanceOf(address(this));

        uint256 amountOut = (amountIn * tokenOutAmount) / tokenInAmount;

        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenOut).safeTransfer(msg.sender, amountOut);
    }
}
