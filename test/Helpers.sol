// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

uint256 constant MAX = type(uint256).max;

library Helpers {
    struct TokenInfo {
        address token;
        uint256 amount;
    }

    function orderTokens(address token1, address token2) public pure returns (address tokenA, address tokenB) {
        (tokenA, tokenB) = token1 < token2 ? (address(token1), address(token2)) : (address(token2), address(token1));
    }

    function orderTokensData(address token1, uint256 liquidity1, address token2, uint256 liquidity2)
        public
        pure
        returns (address tokenA, uint256 liquidityA, address tokenB, uint256 liquidityB)
    {
        (tokenA, liquidityA, tokenB, liquidityB) = token1 < token2
            ? (address(token1), liquidity1, address(token2), liquidity2)
            : (address(token2), liquidity2, address(token1), liquidity1);
    }

    function getPoolId(address token1, address token2) external pure returns (bytes32) {
        (address tokenA, address tokenB) = orderTokens(token1, token2);
        return keccak256(abi.encode(tokenA, tokenB));
    }
}
