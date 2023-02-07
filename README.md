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

# Economic Parameters

We invite wardens to submit bug findings for Flux based on the parameters we will set for the lending market on deployment. We will initially launch with the params in V1 Deployment and then both add markets and update the oracle to support V2 Deployment. The setup in the foundry deploy scripts mimics the exact same parameters below.

## Global Market Parameters

- LiquidationIncentive: 5%
- CTokenCash protocolSeizeShare: 0%
- CTokenModified protocolSeizeShare: 1.75%
- Interest Rate Model Params: OBFR - 50bps APY at Kink (90% Util). OBFR + 300bps at 100% Util

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


# Testing & Development

## Setup

- Install Node >= 16
- Run `yarn install`
- Install forge
- Copy `.env.example` to a new file `.env` in the root directory of the repo. Keep the `FORK_FROM_BLOCK_NUMBER` value the same. Fill in a dummy mnemonic and add a RPC_URL to populate `FORGE_API_KEY_ETHEREUM` and `ETHEREUM_RPC_URL`. These RPC urls can be the same, but be sure to remove any quotes from `FORGE_API_KEY_ETHEREUM`
- Run `yarn init-repo`

## Commands
- Run Tests: `yarn test-forge`
- Generate Gas Report: `yarn test-forge --gas-report`

## Writing Tests and Forge Scripts

For testing with Foundry, `forge-tests/lending/DeployBasicLendingMarket.t.sol` was added to allow for users to easily deploy and setup the Flux lending market for local testing.

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
- Within the foundry tests `address(this)` is given certain permissioned roles. Please use a freshly generated address when writing POC's related to bypassing access controls.

## Quickstart command

`export FORK_URL="<your-mainnet-rpc-url>" && rm -Rf 2023-01-ondo || true && git clone https://github.com/flux-finance/contracts --recurse-submodules && cd 2023-01-ondo && nvm install 16.0 && echo -e "FORGE_API_KEY_ETHEREUM = $FORK_URL\nETHEREUM_RPC_URL = \"$FORK_URL\"\nMNEMONIC='test test test test test test test test test test test junk'\nFORK_FROM_BLOCK_NUMBER=15958078" > .env && yarn install && foundryup && yarn init-repo && yarn test-forge --gas-report`

## VS Code

CTRL+Click in Vs Code may not work due to usage of relative and absolute import paths.
