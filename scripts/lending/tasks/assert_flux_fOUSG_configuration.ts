import { FAILURE_CROSS } from "../../utils/shell";
import mainnet_config from "./config/mainnet.config";
import { task, subtask } from "hardhat/config";
import { Contract } from "ethers";
import { assertAgainstBlockchain, assertRoleMembers } from "./helpers";

subtask("check-fOUSGProxy", "Checks the storage layout of fOUSGProxy")
  .addParam("data", "configuration data to check against")
  .setAction(async ({ data }, hre) => {
    const ethers = hre.ethers;
    const jsonData = JSON.parse(data);
    const fOUSGProxy = await ethers.getContractAt(
      "CTokenDelegate",
      jsonData.fOUSG_PROXY_ADDRESS
    );
    for (const entry in jsonData.fOUSGProxyStorage) {
      await assertAgainstBlockchain(
        fOUSGProxy,
        entry,
        jsonData.fOUSGProxyStorage
      );
    }
  });

subtask(
  "check-fOUSGImplementation",
  "Checks the storage layout of fOUSGImplementation"
)
  .addParam("data", "configuration data to check against")
  .setAction(async ({ data }, hre) => {
    const ethers = hre.ethers;
    const jsonData = JSON.parse(data);
    const fOUSGImplementation = await ethers.getContractAt(
      "CTokenDelegate",
      jsonData.fOUSG_IMPLEMENTATION_ADDRESS
    );
    for (const entry in jsonData.fOUSGImplementationStorage) {
      await assertAgainstBlockchain(
        fOUSGImplementation,
        entry,
        jsonData.fOUSGImplementationStorage
      );
    }
  });

// Passing as of block: 16521308
task(
  "check-flux-fOUSG-configuration",
  "Checks if the flux fOUSG contract has been properly deployed"
).setAction(async ({}, hre) => {
  let config;
  console.log("hre.network.name: ", hre.network.name);
  if (hre.network.name == "mainnet") {
    config = mainnet_config;
  } else {
    console.log(FAILURE_CROSS + " invalid evm network");
    process.exit(1);
  }
  await hre.run("check-fOUSGProxy", {
    data: JSON.stringify(config.flux),
  });
  await hre.run("check-fOUSGImplementation", {
    data: JSON.stringify(config.flux),
  });
});
