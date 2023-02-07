import { FAILURE_CROSS } from "../../utils/shell";
import mainnet_config from "./config/mainnet.config";
import { task, subtask } from "hardhat/config";
import { Contract } from "ethers";
import { assertAgainstBlockchain, assertRoleMembers } from "./helpers";

subtask("check-fDAIProxy", "Checks the storage layout of fDAIProxy")
  .addParam("data", "configuration data to check against")
  .setAction(async ({ data }, hre) => {
    const ethers = hre.ethers;
    const jsonData = JSON.parse(data);
    const fDAIProxy = await ethers.getContractAt(
      "CTokenDelegate",
      jsonData.fDAI_PROXY_ADDRESS
    );
    for (const entry in jsonData.fDAIProxyStorage) {
      await assertAgainstBlockchain(
        fDAIProxy,
        entry,
        jsonData.fDAIProxyStorage
      );
    }
  });

subtask(
  "check-fDAIImplementation",
  "Checks the storage layout of fDAIImplementation"
)
  .addParam("data", "configuration data to check against")
  .setAction(async ({ data }, hre) => {
    const ethers = hre.ethers;
    const jsonData = JSON.parse(data);
    const fDAIImplementation = await ethers.getContractAt(
      "CTokenDelegate",
      jsonData.fDAI_IMPLEMENTATION_ADDRESS
    );
    for (const entry in jsonData.fDAIImplementationStorage) {
      await assertAgainstBlockchain(
        fDAIImplementation,
        entry,
        jsonData.fDAIImplementationStorage
      );
    }
  });

// Passing as of block: 16521308
task(
  "check-flux-fDAI-configuration",
  "Checks if the flux fDAI contract has been properly deployed"
).setAction(async ({}, hre) => {
  let config;
  console.log("hre.network.name: ", hre.network.name);
  if (hre.network.name == "mainnet") {
    config = mainnet_config;
  } else {
    console.log(FAILURE_CROSS + " invalid evm network");
    process.exit(1);
  }
  await hre.run("check-fDAIProxy", {
    data: JSON.stringify(config.flux),
  });
  await hre.run("check-fDAIImplementation", {
    data: JSON.stringify(config.flux),
  });
});
