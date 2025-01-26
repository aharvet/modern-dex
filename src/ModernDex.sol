// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IModernDex} from "./interface/IModernDex.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

struct PoolData {
    address tokenA;
    uint256 liquidityA;
    address tokenB;
    uint256 liquidityB;
}

contract ModernDex is IModernDex {
    using SafeERC20 for IERC20;

    mapping(address tokenA => mapping(address tokenB => bytes32 poolId))
        public tokensToPool;
    mapping(bytes32 poolId => PoolData poolData) private idToPool;
    mapping(address owner => mapping(bytes32 poolId => uint256 shares)) public shares;

    function getPoolData(bytes32 id) external view returns (PoolData memory) {
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

        shares[msg.sender][poolId] = 1000;

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

        emit PoolCreated(poolId, tokenA, liquidityA, tokenB, liquidityB);
    }

    function swap(
        address tokenIn,
        uint256 amountIn,
        address tokenOut
        // address receiver
    ) external {
        (address tokenA, address tokenB) = orderTokens(tokenIn, tokenOut);
        bytes32 poolId = tokensToPool[tokenA][tokenB];
        PoolData storage poolData = idToPool[poolId];

        uint256 amountOut;
        {
            uint256 k = poolData.liquidityA * poolData.liquidityB;
            uint256 liquidityIn = tokenIn == tokenA ? poolData.liquidityA : poolData.liquidityB;
            uint256 newLiquidityIn = liquidityIn + amountIn;
            uint256 newLiquidityOut = k / newLiquidityIn;
            uint256 liquityOut = tokenOut == tokenA ? poolData.liquidityA : poolData.liquidityB;
            uint256 fullAmountOut = liquityOut - newLiquidityOut;
            amountOut = fullAmountOut * 998 / 1000;
                
            poolData.liquidityA = tokenA == tokenIn ? newLiquidityIn : newLiquidityOut;
            poolData.liquidityB = tokenB == tokenIn ? newLiquidityIn : newLiquidityOut;
        }

        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenOut).safeTransfer(msg.sender, amountOut);

        emit Swap(msg.sender, tokenIn, amountIn, tokenOut, amountOut);
    }

    function orderTokens(
        address _token1,
        address _token2
    ) private pure returns (address tokenA, address tokenB) {
        (tokenA, tokenB) = _token1 < _token2
            ? (address(_token1), address(_token2))
            : (address(_token2), address(_token1));
    }
}