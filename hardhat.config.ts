import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "dotenv/config";
import "hardhat-contract-sizer";
import "hardhat-deploy";
import "hardhat-gas-reporter";
import "solidity-coverage";

import { task, HardhatUserConfig } from "hardhat/config";

// Cash Tasks

//Flux Tasks
import "./scripts/lending/tasks/assert_ousg_related_configuration";
import "./scripts/lending/tasks/assert_kyc_configuration";
import "./scripts/lending/tasks/assert_flux_governance_configuration";
import "./scripts/lending/tasks/assert_flux_configuration_preInitialiation";
import "./scripts/lending/tasks/assert_flux_configuration_postInitialization";
import "./scripts/lending/tasks/assert_flux_fDAI_configuration";
import "./scripts/lending/tasks/assert_flux_fOUSG_configuration";
import "./scripts/lending/tasks/assert_flux_fUSDC_configuration";
import "./scripts/lending/production/1_link_unitroller";
import "./scripts/lending/production/2_initialize_OracleV1";
import "./scripts/lending/production/2_initialize_OracleV2";
import "./scripts/lending/production/3_initialize_IRModel";
import "./scripts/lending/production/4_daoProposalpt1";
import "./scripts/lending/production/5_daoProposalpt2";
import "./scripts/lending/production/helpers/prod-subtasks";
// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (_args, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more
const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.8.16",
        settings: {
          optimizer: {
            enabled: true,
            runs: 100,
          },
        },
      },
      {
        version: "0.8.7",
        settings: {
          optimizer: {
            enabled: true,
            runs: 100,
          },
        },
      },
      {
        version: "0.5.17",
        settings: {
          optimizer: {
            enabled: true,
            runs: 100,
          },
        },
      },
      {
        version: "0.6.12",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
  networks: {
    hardhat: {
      accounts: { mnemonic: process.env.MNEMONIC },
      forking: {
        url: process.env.ETHEREUM_RPC_URL!,
        blockNumber: parseInt(process.env.FORK_FROM_BLOCK_NUMBER!),
      },
      chainId: process.env.CHAIN_ID ? parseInt(process.env.CHAIN_ID) : 1337,
    },
    mainnet: {
      accounts: [process.env.MAINNET_PRIVATE_KEY!],
      url: process.env.ETHEREUM_RPC_URL!,
      gas: 6000000,
    },
  },
  mocha: {
    timeout: 60 * 30 * 1000,
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
  namedAccounts: {
    deployer: 0,
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS ? true : false,
  },
};

export default config;
