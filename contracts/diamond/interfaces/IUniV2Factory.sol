// SPDX-License-Identifier: UNKNOWN
pragma solidity ^0.8.18;

interface IUniV2Factory {
	function getPair(address tokenA, address tokenB) external view returns (address pair);
	
	function createPair(address token0, address token1) external returns (address);
}