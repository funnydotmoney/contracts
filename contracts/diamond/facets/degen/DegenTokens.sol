// SPDX-License-Identifier: UNKNOWN
pragma solidity ^0.8.18;

import { LibDegen } from "../../libraries/LibDegen.sol";
import { LibUtils } from "../../libraries/LibUtils.sol";
import { LibPools } from "../../libraries/LibPools.sol";
import { LibTokens } from "../../libraries/LibTokens.sol";
import { LibDiamond } from "../../libraries/LibDiamond.sol";
import { LibClone } from "solady/src/utils/LibClone.sol";
import { ILlamaVesting } from "../../interfaces/ILlamaVesting.sol";
import { IUniV2Router } from "../../interfaces/IUniV2Router.sol";
import { IUniV2Pair } from "../../interfaces/IUniV2Pair.sol";
import { IwETH } from "../../interfaces/IwETH.sol";
import { Ownable } from "../../Ownable.sol";
import { Token } from "../../../Token.sol";
import { Pools } from "./Pools.sol";

enum TokenType {
	Pool
}

contract DegenTokens is Ownable {
	event TokenCreated(address creator, address token, TokenType t, uint256 supply, string name, string symbol, string imageCid, string description, string[] links, uint256 price);
	event TokenLaunched(address creator, address token, address pair);

	function create(TokenType t, string calldata name, string calldata symbol, string calldata imageCid, string calldata description, string[] calldata links, bytes calldata data, uint256 initialBuy) external payable {
		require(
			bytes(name).length <= 18 &&
			bytes(symbol).length <= 18 &&
			bytes(description).length <= 512,
			"Invalid params"
		);

		require(links.length < 5, "5 links max");
		for (uint8 i = 0; i < links.length; i++) {
			require(bytes(links[i]).length <= 128, "link too long");
		}

		LibDegen.Storage storage d = LibDegen.store();
		uint256 supply = d.tokenSupply;

		address tokenAddress = LibClone.cloneDeterministic(
			d.blueprintToken,
			keccak256(abi.encode(msg.sender, name, symbol, description, block.timestamp))
		);
		Token token = Token(tokenAddress);
		token.emboss(name, symbol, supply, address(this));

		uint256 price;
		if (t == TokenType.Pool) {
			price = Pools(address(this))._create_Pool(tokenAddress, supply, data);
		} else {
			revert("invalid token type");
		}

		LibTokens.Storage storage ts = LibTokens.store();

		ts.creatorMap[tokenAddress] = msg.sender;

		emit TokenCreated(msg.sender, tokenAddress, t, d.tokenSupply, name, symbol, imageCid, description, links, price);

		uint256 eth = msg.value;

		uint256 usdEthPrice = LibUtils.getOraclePrice(d.usdcOracle);
		uint256 creationEth = LibUtils.usdToEth(usdEthPrice, d.creationPrice);
		require(eth >= creationEth, "Usd price changed");

		eth -= creationEth;
		LibDegen.gatherProceeds(creationEth, msg.sender);

		if (initialBuy > 0) {
			eth -= initialBuy;

			(uint256 tokensOut, uint256 newPrice) = (0, 0);
			if (t == TokenType.Pool) {
				(tokensOut, newPrice) = Pools(address(this))._buy_Pool{ value: initialBuy }(tokenAddress, msg.sender);
			}

			Token(token).transfer(msg.sender, tokensOut); // Transfer tokens to buyer
			emit Bought(msg.sender, tokenAddress, initialBuy, tokensOut, newPrice);
		}

		if (eth > 0) {
			(bool sent,) = msg.sender.call{ value: eth }(""); // refund dust
			require(sent);
		}
	}

	function quote(address token, TokenType t, uint256 amount, bool ethOut) public view returns(uint256) {
		if (t == TokenType.Pool) {
			return Pools(address(this))._quote_Pool(token, amount, ethOut);
		} else {
			revert("invalid token type");
		}
	}

	event Bought(address buyer, address token, uint256 ethIn, uint256 tokensOut, uint256 newPrice);
	event Sold(address seller, address token, uint256 ethOut, uint256 tokensIn, uint256 newPrice);
	event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to); // UNIV2 event for tracking

	function buy(address token, TokenType t, uint256 min) external payable {
		(uint256 tokensOut, uint256 newPrice) = (0, 0);

		if (t == TokenType.Pool) {
			(tokensOut, newPrice) = Pools(address(this))._buy_Pool{ value: msg.value }(token, msg.sender);
		} else {
			revert("invalid token type");
		}

		if (min != 0) require(tokensOut >= min, "amount out lower than min");

		Token(token).transfer(msg.sender, tokensOut); // Transfer tokens to buyer
		emit Bought(msg.sender, token, msg.value, tokensOut, newPrice);
		emit Swap(address(this), msg.value, 0, 0, tokensOut, msg.sender);
	}

	function sell(address token, TokenType t, uint256 amount, uint256 min) external {
		(uint256 ethOut, uint256 newPrice) = (0, 0);

		if (t == TokenType.Pool) {
			(ethOut, newPrice) = Pools(address(this))._sell_Pool(token, amount, msg.sender);
		} else {
			revert("invalid token type");
		}

		if (min != 0) require(ethOut >= min, "amount out lower than min");

		Token(token).transferFrom(msg.sender, address(this), amount); // Transfer tokens from seller
		(bool sent,) = msg.sender.call{ value: ethOut }(""); require(sent); // Transfer eth to seller
		emit Sold(msg.sender, token, ethOut, amount, newPrice);
		emit Swap(msg.sender, 0, amount, ethOut, 0, address(this));
	}

	function launch(address token, TokenType t) external onlyOwner payable {
		(uint256 eth, uint256 tokens) = (0, 0);

		if (t == TokenType.Pool) {
			(eth, tokens) = Pools(address(this))._launchstats_Pool(token);
		} else {
			revert("invalid token type");
		}

		LibDegen.Storage storage d = LibDegen.store();

		uint256 launchFee = LibUtils.calculatePercentage(d.launchFee, eth);
		LibDegen.gatherProceeds(launchFee, msg.sender);
		eth -= launchFee;

		Token(token).approve(address(d.router), tokens);
		Token(token).launch();

		LibTokens.Storage storage ts = LibTokens.store();

		address wETH = d.router.WETH();

		address pair = d.router.factory().getPair(token, wETH);
		if (pair == address(0)) {
			pair = d.router.factory().createPair(token, wETH);
		}

		Token(token).transfer(pair, tokens);
		IwETH(wETH).deposit{ value: eth }();
		Token(wETH).transfer(pair, eth);

		IUniV2Pair(pair).mint(address(this));

		address[] memory route = new address[](2);
		route[0] = wETH;
		route[1] = token;
		d.router.swapExactETHForTokens{ value: msg.value }(0, route, address(this), block.timestamp);

		LibPools.Pool storage pool = LibPools.store().poolMap[token];
		pool.locked = true;
		pool.pair = pair;

		emit TokenLaunched(ts.creatorMap[token], token, pair);
	}

}
