import { assert } from "console";
import {
  ADMIN_SLOT,
  ROLLBACK_SLOT,
  IMPLEMENTATION_SLOT,
  BEACON_SLOT,
} from "./config/constants";
import {
  assertAgainstBlockchain,
  assertRoleMembers,
  addressFromStorageSlot,
} from "./helpers";

import { task, subtask } from "hardhat/config";
import { FAILURE_CROSS } from "../../utils/shell";

import mainnet_config from "./config/mainnet.config";

subtask("check-ousg-cashManager", "checks OUSG's CashManager configuration")
  .addParam("data", "configuration data to check against")
  .setAction(async ({ data }, hre) => {
    const ethers = hre.ethers;
    const jsonData = JSON.parse(data);
    const cashManagerContract = await ethers.getContractAt(
      "CashManager",
      jsonData.cashManagerAddress
    );
    // Assert Cash manager
    const cashManagerData = jsonData["cashManager"];
    for (const name in cashManagerData) {
      await assertAgainstBlockchain(cashManagerContract, name, cashManagerData);
    }
    const cashManagerRoleMembers = jsonData["cashManagerRoleMembers"];
    await assertRoleMembers(
      cashManagerContract,
      cashManagerData["DEFAULT_ADMIN_ROLE"],
      cashManagerRoleMembers.defaultAdminRoleMembers
    );

    await assertRoleMembers(
      cashManagerContract,
      cashManagerData["MANAGER_ADMIN"],
      cashManagerRoleMembers.managerAdminRoleMembers
    );

    await assertRoleMembers(
      cashManagerContract,
      cashManagerData["PAUSER_ADMIN"],
      cashManagerRoleMembers.pauserAdminRoleMembers
    );

    await assertRoleMembers(
      cashManagerContract,
      cashManagerData["SETTER_ADMIN"],
      cashManagerRoleMembers.setterAdminRoleMembers
    );
  });

subtask("check-ousg-cash", "checks OUSG configuration")
  .addParam("data", "configuration data to check against")
  .setAction(async ({ data }, hre) => {
    const ethers = hre.ethers;
    const jsonData = JSON.parse(data);
    const cashProxyData = jsonData["cashProxy"];

    // Asssert Proxy Admin slots
    assert(
      (await addressFromStorageSlot(
        jsonData["cashProxyAddress"],
        ADMIN_SLOT
      )) == cashProxyData.proxyAdmin,
      FAILURE_CROSS + "proxy admin mismatch"
    );

    assert(
      (await addressFromStorageSlot(
        jsonData["cashProxyAddress"],
        ROLLBACK_SLOT
      )) == cashProxyData.rollback,
      FAILURE_CROSS + "proxy rollback mismatch"
    );

    assert(
      (await addressFromStorageSlot(
        jsonData["cashProxyAddress"],
        BEACON_SLOT
      )) == cashProxyData.beacon,
      FAILURE_CROSS + "proxy beacon mismatch"
    );

    assert(
      (await addressFromStorageSlot(
        jsonData["cashProxyAddress"],
        IMPLEMENTATION_SLOT
      )) == cashProxyData.implementation,
      FAILURE_CROSS + "proxy impl mismatch"
    );

    // Assert Cash Proxy Admin
    const cashProxyAdminContract = await ethers.getContractAt(
      "ProxyAdmin",
      cashProxyData.proxyAdmin
    );

    assert(
      (await cashProxyAdminContract.getProxyAdmin(jsonData.cashProxyAddress)) ==
        cashProxyAdminContract.address,
      "getProxyAdmin failed on the proxy admin contract"
    );

    assert(
      (await cashProxyAdminContract.getProxyImplementation(
        jsonData.cashProxyAddress
      )) == cashProxyData.implementation,
      "getProxyImplementation failed on the proxy admin contract"
    );

    assert(
      (await cashProxyAdminContract.owner()) == jsonData.cashProxyAdmin.owner,
      "Proxy admin owner check failed on the proxy admin contract"
    );

    const cashProxyContract = await ethers.getContractAt(
      "CashKYCSenderReceiver",
      jsonData.cashProxyAddress
    );

    // Assert the storage values for the proxy contract that pertain to
    // implementation contract
    for (const name in cashProxyData.implementationStorage) {
      await assertAgainstBlockchain(
        cashProxyContract,
        name,
        cashProxyData.implementationStorage
      );
    }
  });

task(
  "check-ousg",
  "Checks if CashManager and OUSG contracts has been properly initialized"
).setAction(async ({}, hre) => {
  let config;
  console.log("hre.network.name: ", hre.network.name);
  if (hre.network.name == "mainnet") {
    config = mainnet_config;
  } else {
    console.log(FAILURE_CROSS + " invalid evm network");
    process.exit(1);
  }

  await hre.run("check-ousg-cashManager", {
    data: JSON.stringify(config.ousg),
  });

  await hre.run("check-ousg-cash", {
    data: JSON.stringify(config.ousg),
  });
});
