import type { HardhatUserConfig } from "hardhat/config";

import "@nomicfoundation/hardhat-toolbox-viem";
import "@nomicfoundation/hardhat-verify";

require("dotenv").config();

const config: HardhatUserConfig = {
	networks: {
		mantle: {
			url: process.env["RPC_MANTLE"],
			accounts: [process.env["PRIVATE_KEY"]!],
			chainId: 5000,
		},
		mantle_sepolia: {
			url: process.env["RPC_MANTLE_SEPOLIA"],
			accounts: [process.env["PRIVATE_KEY"]!],
			chainId: 5003,
		},
	},
	solidity: {
		version: "0.8.18",
		settings: {
			optimizer: {
				enabled: true,
				runs: 1337,
			},
			viaIR: true,
		},
	},
};

export default config;
