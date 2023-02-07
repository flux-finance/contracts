import { FAILURE_CROSS } from "../../utils/shell";
import mainnet_config from "./config/mainnet.config";
import { task, subtask } from "hardhat/config";
import { Contract } from "ethers";
import { assertAgainstBlockchain, assertRoleMembers } from "./helpers";

subtask("check-fUSDCProxy", "Checks the storage layout of fUSDCProxy")
  .addParam("data", "configuration data to check against")
  .setAction(async ({ data }, hre) => {
    const ethers = hre.ethers;
    const jsonData = JSON.parse(data);
    const fUSDCProxy = await ethers.getContractAt(
      "CTokenDelegate",
      jsonData.fUSDC_PROXY_ADDRESS
    );
    for (const entry in jsonData.fUSDCProxyStorage) {
      await assertAgainstBlockchain(
        fUSDCProxy,
        entry,
        jsonData.fUSDCProxyStorage
      );
    }
  });

subtask(
  "check-fUSDCImplementation",
  "Checks the storage layout of fUSDCImplementation"
)
  .addParam("data", "configuration data to check against")
  .setAction(async ({ data }, hre) => {
    const ethers = hre.ethers;
    const jsonData = JSON.parse(data);
    const fUSDCImplementation = await ethers.getContractAt(
      "CTokenDelegate",
      jsonData.fUSDC_IMPLEMENTATION_ADDRESS
    );
    for (const entry in jsonData.fUSDCImplementationStorage) {
      await assertAgainstBlockchain(
        fUSDCImplementation,
        entry,
        jsonData.fUSDCImplementationStorage
      );
    }
  });

// Passing as of block: 16521308
task(
  "check-flux-fUSDC-configuration",
  "Checks if the flux fUSDC contract has been properly deployed"
).setAction(async ({}, hre) => {
  let config;
  console.log("hre.network.name: ", hre.network.name);
  if (hre.network.name == "mainnet") {
    config = mainnet_config;
  } else {
    console.log(FAILURE_CROSS + " invalid evm network");
    process.exit(1);
  }
  await hre.run("check-fUSDCProxy", {
    data: JSON.stringify(config.flux),
  });
  await hre.run("check-fUSDCImplementation", {
    data: JSON.stringify(config.flux),
  });
});
