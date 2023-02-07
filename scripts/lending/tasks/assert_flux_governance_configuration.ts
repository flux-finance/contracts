import { assertAgainstBlockchain, assertRoleMembers } from "./helpers";
import { task } from "hardhat/config";
import { FAILURE_CROSS } from "../../utils/shell";

import mainnet_config from "./config/mainnet.config";

// Passing as of block: 16521308
task(
  "check-flux-governance",
  "Checks if the flux governance contracts have been properly initialized"
).setAction(async ({}, hre) => {
  let config;
  const ethers = hre.ethers;
  console.log("hre.network.name: ", hre.network.name);
  if (hre.network.name == "mainnet") {
    config = mainnet_config;
  } else {
    console.log(FAILURE_CROSS + " invalid evm network");
    process.exit(1);
  }
  const governanceData = config.governance;
  const delegatorContract = await ethers.getContractAt(
    "GovernorBravoDelegator",
    governanceData.governorBravoDelegatorAddress
  );

  // Assert the proxy (delegator) storage as it pertains to the proxy.
  for (const entry in governanceData.governorBravoDelegatorStorage) {
    await assertAgainstBlockchain(
      delegatorContract,
      entry,
      governanceData.governorBravoDelegatorStorage
    );
  }

  // Assert the proxy (Delegator) storage as it pertains to the
  // implementation.
  const delegateProxiedContract = await ethers.getContractAt(
    "GovernorBravoDelegate",
    governanceData.governorBravoDelegatorAddress
  );

  for (const entry in governanceData.governorBravoDelegatorImplStorage) {
    await assertAgainstBlockchain(
      delegateProxiedContract,
      entry,
      governanceData.governorBravoDelegatorImplStorage
    );
  }

  // Assert the timelock contract state.
  const timelockContract = await ethers.getContractAt(
    "Timelock",
    governanceData.timelockAddress
  );
  for (const entry in governanceData.timelockStorage) {
    await assertAgainstBlockchain(
      timelockContract,
      entry,
      governanceData.timelockStorage
    );
  }
});
