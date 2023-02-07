import { assert } from "console";
import { assertAgainstBlockchain, assertRoleMembers } from "./helpers";
import { keccak256 } from "ethers/lib/utils";
import { task, subtask } from "hardhat/config";
import { FAILURE_CROSS } from "../../utils/shell";

import mainnet_config from "./config/mainnet.config";

subtask("check-kycRegistry-state", "checks KYCRegistry contract configuration")
  .addParam("data", "configuration data to check against")
  .setAction(async ({ data }, hre) => {
    const ethers = hre.ethers;
    const jsonData = JSON.parse(data);
    const kycRegistryContract = await ethers.getContractAt(
      "KYCRegistry",
      jsonData.kycRegistryAddress
    );
    // Check the KYCRegistry configuration
    for (const entry in jsonData.storage) {
      await assertAgainstBlockchain(
        kycRegistryContract,
        entry,
        jsonData.storage
      );
    }
    // Check the hardcoded(static) role member configuration.
    await assertRoleMembers(
      kycRegistryContract,
      jsonData.storage.DEFAULT_ADMIN_ROLE,
      jsonData.roleMembers.defaultAdminRoleMembers
    );
    await assertRoleMembers(
      kycRegistryContract,
      jsonData.storage.REGISTRY_ADMIN,
      jsonData.roleMembers.registryAdminRoleMembers
    );

    assert(
      (await kycRegistryContract.getRoleAdmin(
        jsonData.storage.REGISTRY_ADMIN
      )) == jsonData.storage.DEFAULT_ADMIN_ROLE,
      FAILURE_CROSS + " : Registry role missing correct admin."
    );

    // Assert that the custom role members are set correctly.
    for (const entry in jsonData.customRoleMembers) {
      await assertRoleMembers(
        kycRegistryContract,
        entry,
        jsonData.customRoleMembers[entry]
      );
      // All admin roles of custom role should be default admin.
      assert(
        (await kycRegistryContract.getRoleAdmin(entry)) ==
          jsonData.storage.DEFAULT_ADMIN_ROLE,
        FAILURE_CROSS + " :custom role missing correct admin."
      );
    }
  });

// Passing as of block: 16521308
task(
  "check-kycRegistry",
  "Checks if KYCRegistry has been properly initialized"
).setAction(async ({}, hre) => {
  let config;
  console.log("hre.network.name: ", hre.network.name);
  if (hre.network.name == "mainnet") {
    config = mainnet_config;
  } else {
    console.log(FAILURE_CROSS + " invalid evm network");
    process.exit(1);
  }
  await hre.run("check-kycRegistry-state", {
    data: JSON.stringify(config.kycRegistry),
  });
  // TODO this could be a good place to compare against all
  // expected KYC user state once we have users.
});
