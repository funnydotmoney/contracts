// SPDX-License-Identifier: UNKNOWN
pragma solidity ^0.8.18;

import { LibDiamond } from "../../libraries/LibDiamond.sol";
import { LibDegen } from "../../libraries/LibDegen.sol";
import { LibPools } from "../../libraries/LibPools.sol";
import { LibUtils } from "../../libraries/LibUtils.sol";
import { Diamondable } from "../../Diamondable.sol";
import { Token } from "../../../Token.sol";


contract Pools is Diamondable {
	event PoolCreated(address token, uint16 sellPenalty, uint256 ethReserve, uint256 tokenReserve);
	event PoolReserveChanged(address token, uint256 ethReserve, uint256 tokenReserve);
	event PoolMCapReached(address token);

	function swapExactTokensForETH(LibPools.Pool storage pool, uint256 tokens) internal returns (uint256) {
		uint256 out = getAmountOut(tokens, pool.tokenReserve, pool.ethReserve);
		pool.tokenReserve += tokens;
		pool.ethReserve -= out;
		emit PoolReserveChanged(pool.token, pool.ethReserve, pool.tokenReserve);
		return out;
	}

	function swapExactETHForTokens(LibPools.Pool storage pool, uint256 eth) internal returns (uint256) {
		uint256 out = getAmountOut(eth, pool.ethReserve, pool.tokenReserve);
		pool.tokenReserve -= out;
		pool.ethReserve += eth;
		emit PoolReserveChanged(pool.token, pool.ethReserve, pool.tokenReserve);
		return out;
	}

	function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) internal pure returns (uint256) {
		uint256 numerator = amountIn * reserveOut;
		uint256 denominator = reserveIn + amountIn;
		return numerator / denominator;
	}

	function price(LibPools.Pool storage pool, uint256 amount, bool ethOut) internal view returns (uint256) {
		if (ethOut) {
			return (amount * pool.ethReserve) / pool.tokenReserve;
		} else {
			return (amount * pool.tokenReserve) / pool.ethReserve;
		}
	}

	function checkMarketCapThreshold(LibPools.Pool storage pool) internal {
		LibDegen.Storage storage d = LibDegen.store();

	 	uint256 p = price(pool, 1 ether, true);
		uint256 ethMcap = d.tokenSupply * p;

		uint256 usdEthPrice = LibUtils.getOraclePrice(d.usdcOracle);
		uint256 amountUsd = LibUtils.ethToUsd(usdEthPrice, ethMcap);

		if (amountUsd >= d.poolMCapThreshold) {
			pool.locked = true;
			emit PoolMCapReached(pool.token);
		}
	}

	function calculateSellPenalty(LibPools.Pool storage pool, uint256 eth) internal view returns (uint256) {
		if (pool.sellPenalty == 0) return 0;
		return LibUtils.calculatePercentage(pool.sellPenalty, eth);
	}

	function deductSellPenalty(LibPools.Pool storage pool, uint256 eth) internal returns (uint256) {
		uint256 fee = calculateSellPenalty(pool, eth);
		if (fee == 0) {
			return eth;
		} else {
			pool.ethReserve += fee; // redistribute the penaltyFee back into the ether reserve
			return eth - fee;
		}
	}

	function _quote_Pool(address token, uint256 amount, bool ethOut) external view returns (uint256) {
		LibPools.Pool storage pool = LibPools.store().poolMap[token];
		if (ethOut) { // sell
			uint256 eth = getAmountOut(amount, pool.tokenReserve, pool.ethReserve);
			eth -= LibDegen.calculateTxFee(eth);
			eth -= calculateSellPenalty(pool, eth);
			return eth;
		} else { // buy
			uint256 txFee = LibDegen.calculateTxFee(amount);
			return getAmountOut(amount - txFee, pool.ethReserve, pool.tokenReserve);
		}
	}

	function _create_Pool(address tokenAddress, uint256 supply, bytes calldata data) external onlyDiamond returns (uint256) {
		LibDegen.Storage storage d = LibDegen.store();
		LibPools.Storage storage t =	LibPools.store();

		(uint16 sellPenalty) = abi.decode(data, (uint16));

		require(sellPenalty <= 700);

		LibPools.Pool storage pool = t.poolMap[tokenAddress];
		pool.token = tokenAddress;
		pool.fakeEth = d.poolBaseEther;
		pool.ethReserve = d.poolBaseEther;
		pool.tokenReserve = supply;
		pool.sellPenalty = sellPenalty;

		emit PoolCreated(tokenAddress, sellPenalty, pool.ethReserve, pool.tokenReserve);

		return price(pool, 1 ether, true);
	}

	function _launchstats_Pool(address token) external view returns (uint256, uint256) {
		LibPools.Pool storage pool = LibPools.store().poolMap[token];
		require(pool.token != address(0));
		return (pool.ethReserve - pool.fakeEth, pool.tokenReserve);
	}

	function _buy_Pool(address token, address user) external onlyDiamond payable returns (uint256, uint256) {
		LibPools.Pool storage pool = LibPools.store().poolMap[token];
		require(pool.token != address(0) && !pool.locked);

		uint256 ethIn = LibDegen.deductTxFee(msg.value, user);
		uint256 tokensOut = swapExactETHForTokens(pool, ethIn);

		checkMarketCapThreshold(pool);

		return (tokensOut, price(pool, 1 ether, true));
	}

	function _sell_Pool(address token, uint256 amount, address user) external onlyDiamond returns (uint256, uint256) {
		LibPools.Pool storage pool = LibPools.store().poolMap[token];
		require(pool.token != address(0) && !pool.locked);

		uint256 ethOut = swapExactTokensForETH(pool, amount);
		ethOut = LibDegen.deductTxFee(ethOut, user);
		ethOut = deductSellPenalty(pool, ethOut);

		require(pool.ethReserve >= pool.fakeEth, "no eth left in pool");
		checkMarketCapThreshold(pool);

		return (ethOut, price(pool, 1 ether, true));
	}

}
