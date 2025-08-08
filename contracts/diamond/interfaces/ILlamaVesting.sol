// SPDX-License-Identifier: UNKNOWN
pragma solidity ^0.8.18;

interface ILlamaVesting {
	function deploy_vesting_contract(address token, address recipient, uint256 amount, uint256 vesting_duration) external;
}