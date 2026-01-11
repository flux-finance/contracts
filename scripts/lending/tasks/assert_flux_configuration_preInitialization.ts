import { assert } from "console";
import { FAILURE_CROSS } from "../../utils/shell";
import mainnet_config from "./config/mainnet.config";
import { task, subtask } from "hardhat/config";
import { Contract } from "ethers";
import { assertAgainstBlockchain, assertRoleMembers } from "./helpers";

subtask("check-comptrollerImpl", "checks uninitialized comptroller storage")
  .addParam("data", "configuration data to check against")
  .setAction(async ({ data }, hre) => {
    const ethers = hre.ethers;
    const jsonData = JSON.parse(data);
    const comptrollerContract = await ethers.getContractAt(
      "Comptroller",
      jsonData.comptrollerAddress
    );
    for (const entry in jsonData.comptrollerImplStorage) {
      await assertAgainstBlockchain(
        comptrollerContract,
        entry,
        jsonData.comptrollerImplStorage
      );
    }
  });

subtask("check-unitroller", "checks unitroller storage for proxy")
  .addParam("data", "configuration data to check against")
  .setAction(async ({ data }, hre) => {
    const ethers = hre.ethers;
    const jsonData = JSON.parse(data);
    const unitrollerContract = await ethers.getContractAt(
      "Unitroller",
      jsonData.unitrollerAddress
    );
    for (const entry in jsonData.unitrollerStorage) {
      await assertAgainstBlockchain(
        unitrollerContract,
        entry,
        jsonData.unitrollerStorage
      );
    }
  });

subtask("check-jumpRateModel", "checks Jump rate parameters")
  .addParam("data", "configuration data to check against")
  .setAction(async ({ data }, hre) => {
    const ethers = hre.ethers;
    const jsonData = JSON.parse(data);
    const jumpRateModelV2Contract = await ethers.getContractAt(
      "JumpRateModelV2",
      jsonData.jumpRateModelV2Address
    );
    for (const entry in jsonData.jumpRateModelV2) {
      await assertAgainstBlockchain(
        jumpRateModelV2Contract,
        entry,
        jsonData.jumpRateModelV2
      );
    }
  });

// Passing as of block: 16521308
task(
  "check-flux-preInitialization",
  "Checks if flux contracts have been properly deployed"
).setAction(async ({}, hre) => {
  let config;
  console.log("hre.network.name ", hre.network.name);
  if (hre.network.name == "mainnet") {
    config = mainnet_config;
  } else {
    console.log(FAILURE_CROSS + " invalid blockchain name");
    process.exit(1);
  }
  await hre.run("check-jumpRateModel", {
    data: JSON.stringify(config.flux),
  });
  await hre.run("check-unitroller", {
    data: JSON.stringify(config.flux),
  });
  await hre.run("check-comptrollerImpl", {
    data: JSON.stringify(config.flux),
  });
});
