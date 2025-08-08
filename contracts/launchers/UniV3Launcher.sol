// SPDX-License-Identifier: UNKNOWN
pragma solidity ^0.8.18;

import { IUniV3Launcher } from "../diamond/interfaces/IUniV3Launcher.sol";
import { Token } from "../Token.sol";

interface IUniswapV3Pool {
	function initialize(uint160 sqrtPriceX96) external;
}

interface INonfungiblePositionManager {
	function WETH9() external view returns (address);
	
	struct MintParams {
		address token0;
		address token1;
		uint24 fee;
		int24 tickLower;
		int24 tickUpper;
		uint256 amount0Desired;
		uint256 amount1Desired;
		uint256 amount0Min;
		uint256 amount1Min;
		address recipient;
		uint256 deadline;
	}

	function mint(MintParams memory params) external returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
}

interface IUniswapV3Factory {
	function getPool(address tokenA, address tokenB, uint24 fee) external view returns (address pool);
	function createPool(address tokenA, address tokenB, uint24 fee) external returns (address pool);
}

contract UniV3Launcher is IUniV3Launcher {
	address public weth;
	IUniswapV3Factory public factory;
	INonfungiblePositionManager public nfpManager;

	constructor(address _nfpManager, address _factory) {
		factory = IUniswapV3Factory(_factory);
		nfpManager = INonfungiblePositionManager(_nfpManager);
		weth = nfpManager.WETH9();
	}

	function launch(
		address token,
		uint256 amount1
	) external payable returns (uint256 nfp) {
		Token token0 = Token(weth);
		uint256 amount0 = msg.value;
		Token token1 = Token(token);

		address pool = factory.getPool(address(token0), address(token1), 10000);
		if (pool == address(0)) {
			pool = factory.createPool(address(token0), address(token1), 10000);
			IUniswapV3Pool(pool).initialize(getSqrtPriceX96(amount0, amount1));
		}

		// Approve token transfers to the position manager
		Token(token0).approve(address(nfpManager), amount0);
		Token(token1).approve(address(nfpManager), amount1);

		// Mint the position (add liquidity)
		INonfungiblePositionManager.MintParams
			memory params = INonfungiblePositionManager.MintParams({
				token0: address(token0),
				token1: address(token1),
				fee: 10000,
				tickLower: -887272,
				tickUpper: 887272,
				amount0Desired: amount0,
				amount1Desired: amount1,
				amount0Min: 0,
				amount1Min: 0,
				recipient: msg.sender,
				deadline: block.timestamp + 15 minutes
			});

		(uint256 tokenId, , , ) = nfpManager.mint(params);
		return tokenId;
	}

	function getSqrtPriceX96(
		uint256 amount0,
		uint256 amount1
	) internal pure returns (uint160 sqrtPriceX96) {
		require(amount0 > 0 && amount1 > 0, "Amounts must be greater than zero");

		// Calculate the price ratio
		uint256 priceRatio = (amount1 * (1 << 96)) / amount0;

		// Calculate the square root of the price ratio (scaled by 2^96)
		sqrtPriceX96 = uint160(sqrt(priceRatio));
	}

	// Babylonian method to calculate square root
	function sqrt(uint256 x) internal pure returns (uint256) {
		if (x == 0) return 0;
		uint256 z = (x + 1) / 2;
		uint256 y = x;
		while (z < y) {
			y = z;
			z = (x / z + z) / 2;
		}
		return z;
	}
}