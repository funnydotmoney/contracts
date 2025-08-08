// SPDX-License-Identifier: UNKNOWN
pragma solidity ^0.8.18;

interface IUniV2Pair {
	function token0() external view returns (address);
	function token1() external view returns (address);
	
	function mint(address to) external returns (uint256);
}