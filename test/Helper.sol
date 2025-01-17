// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
	
uint256 constant MAX = type(uint256).max;
	 
contract Helpers {

	function orderTokens(
        address _token1,
        address _token2
    ) public pure returns (address tokenA, address tokenB) {
        (tokenA, tokenB) = _token1 < _token2
            ? (address(_token1), address(_token2))
            : (address(_token2), address(_token1));
    }

    function getPoolId(
        address _token1,
        address _token2
    ) external pure returns (bytes32) {
        (address tokenA, address tokenB) = orderTokens(_token1, _token2);
        return keccak256(abi.encode(tokenA, tokenB));
    }
}