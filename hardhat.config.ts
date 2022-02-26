import 'hardhat-typechain';
import 'solidity-coverage';
import '@nomiclabs/hardhat-waffle';
import 'hardhat-typechain';
import '@typechain/ethers-v5';
import '@nomiclabs/hardhat-web3';
import "@nomiclabs/hardhat-etherscan";
import "hardhat-gas-reporter";

import { HardhatUserConfig } from 'hardhat/config';
import * as dotenv from 'dotenv';
import { accounts } from './test/shared/accounts';


dotenv.config();

const RINKEBY_PRIVATE_KEY=process.env.RINKEBY_PRIVATE_KEY;
const MAINNET_PRIVATE_KEY=process.env.MAINNET_PRIVATE_KEY;

const config: HardhatUserConfig = {
	solidity: {
		compilers: [
			{
				version: '0.8.0',
				settings: {
					optimizer: {
						enabled: true,
						runs: 200,
					},
				},
			},
			{
				version: '0.8.0',
				settings: {
					optimizer: {
						enabled: true,
						runs: 200,
					},
				},
			},
		],
	},

	gasReporter: {
		currency: 'CHF',
		gasPrice: 21
	},

	networks: {
		hardhat: {
			gas: 10000000,
			gasPrice: 1,
			blockGasLimit: 10000000,
			allowUnlimitedContractSize: true,
			accounts: accounts,
		},
		testnet: {
			url: `https://testnet.veblocks.net`,
			// accounts: [secret],
		},
		mainnet: {
			url: `https://mainnet.infura.io/v3/3f05772998774c6a86b0803a6aed75c3`,
			accounts: [`0x${MAINNET_PRIVATE_KEY}`]
		},
		rinkeby: {
			url: `https://rinkeby.infura.io/v3/3f05772998774c6a86b0803a6aed75c3`,
			accounts: [`0x${RINKEBY_PRIVATE_KEY}`]
		},
		coverage: {
			url: 'http://127.0.0.1:8555', // Coverage launches its own ganache-cli client
		},
		local: {
			url: 'http://127.0.0.1:8545',
		},
	},

	etherscan: {
		// Your API key for Etherscan
		// Obtain one at https://etherscan.io/
		apiKey: "K2KYW58RBCGMX3RP134XXP82TN4VP5WSV5"
	  },

	typechain: {
		outDir: 'typechain',
		target: 'ethers-v5',
	},
};

export default config;