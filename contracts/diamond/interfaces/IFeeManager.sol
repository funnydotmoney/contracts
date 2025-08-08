// SPDX-License-Identifier: UNKNOWN
pragma solidity ^0.8.18;

interface IFeeManager {
	function withdrawFees(address recipient) external;
}