// SPDX-License-Identifier: UNKNOWN
pragma solidity ^0.8.18;

interface IUniV3Launcher {
	function weth() external view returns (address);
	function launch(address token, uint256 amount) external payable returns (uint256 nfp);
}