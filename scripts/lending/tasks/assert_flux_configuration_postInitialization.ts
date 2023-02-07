import { assert } from "console";
import { FAILURE_CROSS } from "../../utils/shell";
import mainnet_config from "./config/mainnet.config";
import { task, subtask } from "hardhat/config";
import { Contract } from "ethers";
import { assertAgainstBlockchain, assertRoleMembers } from "./helpers";

async function assertMarketWithinComptroller(
  comptrollerContract: Contract,
  cTokenAddress: string,
  market: any
) {
  assert(
    (await comptrollerContract.borrowCaps(cTokenAddress)) == market.borrowCap,
    `Borrow cap mismatch for ${cTokenAddress}`
  );
  assert(
    (await comptrollerContract.mintGuardianPaused(cTokenAddress)) ==
      market["mintGuardianPaused"],
    `Mint guardian paused mismatch for ${cTokenAddress}`
  );
  assert(
    (await comptrollerContract.borrowGuardianPaused(cTokenAddress)) ==
      market["borrowGuardianPaused"],
    `Borrow guardian paused mismatch for ${cTokenAddress}`
  );
  assert(
    (await comptrollerContract.compSpeeds(cTokenAddress)) ==
      market["compSpeeds"],
    `Comp speeds mismatch for ${cTokenAddress}`
  );
  assert(
    (await comptrollerContract.compBorrowSpeeds(cTokenAddress)) ==
      market["compBorrowSpeeds"],
    `Comp borrow speeds mismatch for ${cTokenAddress}`
  );
  assert(
    (await comptrollerContract.compSupplySpeeds(cTokenAddress)) ==
      market["compSupplySpeeds"],
    `Comp supply speeds mismatch for ${cTokenAddress}`
  );
}

subtask(
  "check-comptrollerProxied",
  "checks unitroller storage pertaining to comptroller"
)
  .addParam("data", "configuration data to check against")
  .setAction(async ({ data }, hre) => {
    const ethers = hre.ethers;
    const jsonData = JSON.parse(data);
    const comptrollerProxiedContract = await ethers.getContractAt(
      "Comptroller",
      jsonData.unitrollerAddress
    );

    for (const entry in jsonData.comptrollerProxiedStorage) {
      await assertAgainstBlockchain(
        comptrollerProxiedContract,
        entry,
        jsonData.comptrollerProxiedStorage
      );
    }

    const markets = jsonData.comptrollerProxiedMarkets.markets;
    for (let i = 0; i < markets.length - 1; ++i) {
      const cTokenAddress = await comptrollerProxiedContract.allMarkets(i);
      assert(cTokenAddress == markets[i].address, `Market mismatch index ${i}`);
      await assertMarketWithinComptroller(
        comptrollerProxiedContract,
        cTokenAddress,
        markets[i]
      );
    }
  });

subtask("check-collateralFactors", "checks collateral factors")
  .addParam("data", "configuration data to check against")
  .setAction(async ({ data }, hre) => {
    const ethers = hre.ethers;
    const jsonData = JSON.parse(data);
    const markets = jsonData.comptrollerProxiedMarkets.markets;
    const comptrollerProxiedContract = await ethers.getContractAt(
      "Comptroller",
      jsonData.unitrollerAddress
    );

    for (let i = 0; i < markets.length; ++i) {
      const cTokenAddress = await comptrollerProxiedContract.allMarkets(i);
      const collateralFactor = markets[i].collateralFactor;
      const marketsRet = await comptrollerProxiedContract.markets(
        cTokenAddress
      );
      assert(marketsRet.isListed, `Market not listed for ${cTokenAddress}`);
      assert(
        marketsRet.collateralFactorMantissa.toString() == collateralFactor,
        `Collateral factor mismatch for ${cTokenAddress}`
      );
    }
  });

// Passing as of block: 16443362
// TODO: Update the parameters post-initialization when in prod
task(
  "check-flux-postInitialization",
  "Checks if flux contracts have been properly initialized"
).setAction(async ({}, hre) => {
  let config;
  console.log("hre.network.name ", hre.network.name);
  if (hre.network.name == "mainnet") {
    config = mainnet_config;
  } else {
    console.log(FAILURE_CROSS + " invalid blockchain name");
    process.exit(1);
  }
  // Sanity check the comptroller implementation, should still
  // have the same storage params
  await hre.run("check-comptrollerImpl", {
    data: JSON.stringify(config.flux),
  });
  await hre.run("check-comptrollerProxied", {
    data: JSON.stringify(config.flux),
  });
  await hre.run("check-collateralFactors", {
    data: JSON.stringify(config.flux),
  });
});
