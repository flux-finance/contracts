# Introduction to Flux

Flux Protocol is a Compound V2 fork that supports both permissioned and permissionless assets. The Flux protocol will support lending markets for USDC, DAI and OUSG (subject to governance vote [here](https://www.tally.xyz/gov/ondo-dao)). Users will be able to supply USDC, DAI and OUSG but only be able to borrow DAI and USDC.

# Directory Overview

The directory structure of this repo splits the contracts, tests, and scripts based on whether they are a part of the Cash or Flux protocol.

- Directory locations for Flux related contracts can be found under `contracts/lending`.
- We utilize the Foundry framework for tests. Tests for Flux can be found inside `forge-tests/`
- We utilize the hardhat framework for scripting and deployments under `scripts/` and `deploy/`

## Interaction Diagram

[Link to Slides](https://drive.google.com/file/d/18cXjQaI2kA-YkAAHPwGTjBsIs5KWd3VM)

# Flux Contracts

Flux is a fork of Compound V2. The comptroller and contracts in the `contracts/lending/compound` and `contracts/lending/tokens/cErc20Delegate` folders are unchanged from Compound's on-chain lending market deployments. The primary changes to the protocol are in the cToken contracts (cTokenCash and cTokenModified), which add sanctions and KYC checks to specific functions in the markets. The contracts are forked directly from etherscan. For reference, the deployed cToken contract can be found at this [commit](https://github.com/compound-finance/compound-protocol/tree/a3214f67b73310d547e00fc578e8355911c9d376). All other contracts (Comptroller, CErc20Delegator, InterestRateModel, etc.) are found in the previous [commit](https://github.com/compound-finance/compound-protocol/tree/3affca87636eecd901eb43f81a4813186393905d). Note that we linted our contracts and have different import paths.

## cToken (fDAI, fUSDT, fUSDC, fFRAX, fLUSD)

Each of the upgradeable fToken contracts consists of 4 primary contracts: `CErc20DelegatorKYC` (Proxy), `CTokenDelegate` (Implementation), which inherits from `cTokenInterfacesModified`, and `CTokenModified`. These contracts are forked with minor changes from Compound's [on-chain cDAI contract](https://etherscan.io/token/0x5d3a536e4d6dbd6114cc1ead35777bab948e3643#code). `CTokenModified` and `cTokenInterfacesModified` are also forked from Compound's cDAI contract, but they add storage and logic for KYC/sanctions checks. In addition `cTokenInterfacesModified` changes the [`protocolSeizeShareMantissa`](https://github.com/ondoprotocol/compound/blob/main/contracts/lending/tokens/cToken/CTokenInterfacesModified.sol#L113) from 2.8% to 1.75%. `CTokenModified` guards the following functions with checks:

| Function       | Check    |
| -------------- | -------- |
| transferTokens | Sanction |
| mint           | Sanction |
| redeem         | Sanction |
| borrow         | KYC      |
| repayBorrow    | KYC      |
| seize          | Sanction |

_Note: `liquidateBorrow` has no checks on it since it calls into `seize` on the collateral and `repayBorrow` on the borrowed asset._

Since fTokens are clients of the KYCRegistry contract, the logic for KYC checks are added throughout various functions within the `CTokenModified` [contract](https://github.com/ondoprotocol/compound/blob/main/contracts/lending/tokens/cToken/CTokenModified.sol). The storage modifications for KYC/Sanctions checks are in `CTokenInterfacesModified` in this [section](https://github.com/ondoprotocol/compound/blob/main/contracts/lending/tokens/cToken/CTokenInterfacesModified.sol#L116-L176). The storage and logic is forked directly from `KYCRegistryClient`, without the use of custom errors.

## fOUSG (cCASH)

Like fTokens, the upgradeable fOUSG is forked from Compound's on-chain cDAI contract and consists of 4 primary contracts: `cCash`, `cCashDelegate`, `cTokenInterfacesModifiedCash`, and `CTokenCash`. `cTokenInterfacesModifiedCash` updates the [`protocolSeizeShareMantissa`](https://github.com/ondoprotocol/compound/blob/main/contracts/lending/tokens/cCash/CTokenInterfacesModifiedCash.sol#L115) from 2.8% to 0%. `CTokenCash` guards the following functions with checks:

| Function       | Check |
| -------------- | ----- |
| transferTokens | KYC   |
| mint           | KYC   |
| redeem         | KYC   |
| borrow         | KYC   |
| repayBorrow    | KYC   |
| seize          | KYC   |

_Note: cCASH is not borrowable in the MVP, so the `borrow`, `repayBorrow`, and `liquidateBorrow` functions aren't relevant._

Similar to CTokenModified, the logic changes for cCash consist of checks on various functions in the `cTokenCash` [contract](https://github.com/ondoprotocol/compound/blob/main/contracts/lending/tokens/cCash/CTokenCash.sol). The storage changes modifications for KYC checks can be found in `CTokenInterfacesModifiedCash` in this [section](https://github.com/ondoprotocol/compound/blob/main/contracts/lending/tokens/cCash/CTokenInterfacesModifiedCash.sol#L118-L178).

## cErc20ModifiedDelegator

This contract is forked from Compound's cDAI `cErc20Delegator` contract. Since this contract acts as a proxy for Flux's `cErc20` and `cCash` implementation contracts, corresponding storage updates were made in the [contract](https://github.com/ondoprotocol/compound/blob/main/contracts/lending/tokens/cErc20ModifiedDelegator.sol). As one can expect, the constructor was modified to add `kycRegistry` and `kycRequirementGroup` parameters.

## JumpRateModelV2

The JumpRateModelV2 contract is forked from Compound's cDAI InterestRateModel. The only modified value is the [`blocksPerYear`](https://github.com/ondoprotocol/compound/blob/main/contracts/lending/JumpRateModelV2.sol#L29).

## OndoPriceOracle

Acts as the price oracle for the lending market. To get the price of DAI, the contract **makes an external call** into Compound's [`UniswapAnchoredView`](https://etherscan.io/address/0x50ce56A3239671Ab62f185704Caedf626352741e#code) oracle contract with Compound's cDAI address. The oracle can support both assets with custom prices (i.e. CASH tokens) and assets listed on Compound (UNI, USDC, USDT, etc.). The price of CASH is set by a trusted off-chain party with privileged access that calculates the price based on the NAV of the RWA fund backing the CASH token, similar to the `CashManager` contract.

## OndoPriceOracleV2

This contract has all the features of `OndoPriceOracle`, but adds the ability to set price caps and retrieve prices from Chainlink oracles. To do so, an `fToken` must have one of 3 different `OracleTypes` - `Manual`, `Compound`, `Chainlink`. The oracle also contains price caps to attempt to mitigate the fallout of a stablecoin depegging upwards. Makes **external calls** to Chainlink Oracles and Compound's UniswapAnchoredView oracle contract. We intend to upgrade the oracle in the comptroller to `OndoPriceOracleV2` at a later point with markets that aren't supported by `OndoPriceOracle` (FRAX, LUSD, etc).

# Economic Scope

We invite wardens to submit bug findings for Flux based on the parameters we will set for the lending market on deployment. We will initially launch with the params in V1 Deployment and then both add markets and update the oracle to support V2 Deployment. The setup in the foundry deploy scripts mimics the exact same parameters below.

## Global Market Parameters

- LiquidationIncentive: 5%
- CTokenCash protocolSeizeShare: 0%
- CTokenModified protocolSeizeShare: 1.75%
- Interest Rate Model Params: 3.8% APY at Kink (80% Util). 10% APY at 100% Util. _The IR Model Parameters are only be in-scope for V1 Deployment assets_

## V1 Deployment

| Asset       | Lendable | Borrowable | CollateralFactor |
| ----------- | -------- | ---------- | ---------------- |
| USDC        | Yes      | Yes        | 85%              |
| OUSG (CASH) | Yes\*    | No         | 92%              |
| DAI         | Yes      | Yes        | 83%               |

_Note: If an asset has a CollateralFactor of 0, it cannot be used as collateral._
To set an asset as non-borrowable, we call `_setBorrowPaused` on the Comptroller. OUSG is lendable in the sense that it can be used to mint fTokens, which will later collateralize a borrow position. However, these fTokens will not be earning yield.

## V2 Deployment

Same assets/configuration as V1, with the following added:
| Asset | Lendable | Borrowable | CollateralFactor |
| ----------- | ----------- | ---------- | ---------- |
| USDT | Yes | Yes | 0% |
| FRAX | Yes | Yes | 0% |
| LUSD | Yes | Yes | 0% |

To support V2 Deployment assets, we must update the oracle and set the `OracleType` for all fTokens. A sample for how this will be done can be found [here](https://github.com/ondoprotocol/compound/blob/main/forge-tests/lending/fToken/fToken.base.noCollateral.t.sol#L279-L322).

# Not In Scope

- **Centralization Risk** - we are aware that our management functions and contract upgradeability results in a significantly more centralized system than Compound V2.
- **Bad debt risk from misconfiguration** - we are aware that
  - pushing to 98% the collateral factor may provoke some bad debt if `CollateralFactor + Liquidation Incentive > 100`
  - liquidators need to be on the whitelist (KYC’d), and if none decide to liquidate, the protocol can accrue bad debt
  - the protocol does not accrue reserves on some/all assets
- **Liquidation Profitability** - We understand that if `LiquidationIncentive < ProtocolSeizeShare` (as percents), then liquidations are unprofitable
- **Duplicated code** - we are aware that there are significant opportunities throughout the repo to reduce the quantity of duplicated code. This is largely due to timing and our attempts to keep the code base as similar as possible to verified Compound contract code on Etherscan.
- **Gas Optimizations** - Per [https://docs.code4rena.com/awarding/incentive-model-and-awards](https://docs.code4rena.com/awarding/incentive-model-and-awards), we only want 5% our of pool to be dedicated to gas improvements.
  - We would only like to consider custom code (not compound) for these optimizations
  - In cToken contracts, the only gas optimization considered will be for KYC/Sanctions Checks
  - There are unimplemented hooks in C\*Delegate.sol files that we have left to be consistent with Compound - these should not be considered
- **KYC/Sanction related edge cases** specifically when a user’s KYC status or Sanction status changes in between different actions, leaving them at risk of their funds being locked in the protocols or being liquidated in Flux.
  - If someone gets sanctioned they can not supply collateral (CASH or stablecoin)
  - If someone loses KYC status they can not repay borrow or have someone repay borrow on behalf of them
- **Third Party Upgradability Risk** - we assume that third parties such as other stablecoins or oracles will not make upgrades resulting in malfunctions or loss of funds.

## Scoping Details

```
- If you have a public code repo, please share it here:  N/A
- How many contracts are in scope?:   30
- Total SLoC for these contracts?:  4365
- How many external imports are there?: 4
- How many separate interfaces and struct definitions are there for the contracts within scope?:  ~15 interfaces; ~40 structs
- Does most of your code generally use composition or inheritance?: Inheritance
- How many external calls?: 2 (Chainlink and Compound oracles)
- What is the overall line coverage percentage provided by your tests?: Unknown
- Is there a need to understand a separate part of the codebase / get context in order to audit this part of the protocol?:  No
- Please describe required context:
- Does it use an oracle?:  Yes; (Compound and Chainlink oracles)
- Does the token conform to the ERC20 standard?:  Yes
- Are there any novel or unique curve logic or mathematical models?: None (Compound fork)
- Does it use a timelock function?:  No
- Is it an NFT?: No
- Does it have an AMM?:   No
- Is it a fork of a popular project?: Yes
- Does it use rollups?:   No
- Is it multi-chain?:  No
- Does it use a side-chain?: No
```

# Testing & Development

## Setup

- Install Node >= 16
- Run `yarn install`
- Install forge
- Copy `.env.example` to a new file `.env` in the root directory of the repo. Keep the `FORK_FROM_BLOCK_NUMBER` value the same. Fill in a dummy mnemonic and add a RPC_URL to populate `FORGE_API_KEY_ETHEREUM` and `ETHEREUM_RPC_URL`. These RPC urls can be the same, but be sure to remove any quotes from `FORGE_API_KEY_ETHEREUM`
- Run `yarn init-repo`

## Commands

- Start a local blockchain: `yarn local-node`
  - The scripts found under `scripts/<cash or lending>/ci/event_coverage.ts` aim to interact with the contracts in a way that maximizes the count of distinct event types emitted. For example:

```sh
yarn hardhat run --network localhost scripts/<cash or lending>/ci/event_coverage.ts
```

- Run Tests: `yarn test-forge`

  - Run Cash Tests: `yarn test-forge-cash`
  - Run Flux Tests: `yarn test-forge-lending`

- Generate Gas Report: `yarn test-forge --gas-report`

## Writing Tests and Forge Scripts

For testing with Foundry, `forge-tests/lending/DeployBasicLendingMarket.t.sol` & `forge-tests/BasicDeployment.sol` were added to allow for users to easily deploy and setup the CASH/CASH+ dapp, and Flux lending market for local testing.

To setup and write tests for contracts within foundry from a deployed state please include the following layout within your testing file. Helper functions are provided within each of these respective setup files.

```sh
pragma solidity 0.8.16;

import "forge-tests/lending/DeployBasicLendingMarket.t.sol";

contract Test_case_someDescription is BasicLendingMarket {
  function testName() public {
    console.log(fCASH.name());
    console.log(fCASH.symbol());
  }
}
```

_Note_:

- `BasicLendingMarket` inherits from `BasicDeployment`.
- Within the foundry tests `address(this)` is given certain permissioned roles. Please use a freshly generated address when writing POC's related to bypassing access controls.

## Quickstart command

`export FORK_URL="<your-mainnet-rpc-url>" && rm -Rf 2023-01-ondo || true && git clone https://github.com/ondoprotocol/compound.git --recurse-submodules && cd 2023-01-ondo && nvm install 16.0 && echo -e "FORGE_API_KEY_ETHEREUM = $FORK_URL\nETHEREUM_RPC_URL = \"$FORK_URL\"\nMNEMONIC='test test test test test test test test test test test junk'\nFORK_FROM_BLOCK_NUMBER=15958078" > .env && yarn install && foundryup && yarn init-repo && yarn test-forge --gas-report`

## VS Code

CTRL+Click in Vs Code may not work due to usage of relative and absolute import paths.

## Polygon Deployment

The entire suite of Flux and CASH contracts have been deployed to polygon. These contracts may not match exactly what is in repo as they were deployed before certain changes were made. They can be found at the following addresses:
| Contract | Link |
| ----------- | ----------- |
| OUSG (CashKYCSenderReceiver) | https://polygonscan.com/address/0xE48BB5f57aC2512FB23E62F5C6428FF57C40BAa2#code |
| CashKYCSenderReceiver Factory | https://polygonscan.com/address/0x14d79Fd4AD4b87E434f0546ecfeda8Acf71E1E2f |
| CashManager | https://polygonscan.com/address/0x2AC3FECd004be8BC61746D7B0d1C56f550e4738a |
| KYCRegistry | https://polygonscan.com/address/0xAbfB6C4a338f3780b35FdEEE11e6bB445F13BDc4 |
| Comptroller | https://polygonscan.com/address/0xC99c8D923f2fe708f25401467CD21EA6c1c51F05#code |
| fOUSG | https://polygonscan.com/address/0xF16c188c2D411627d39655A60409eC6707D3d5e8 |
| fDAI | https://polygonscan.com/address/0x14b113Ca9100DFf02641d6fcD6919B95B9f67B02 |
