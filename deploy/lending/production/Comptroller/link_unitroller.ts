import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { Unitroller } from "../../../../typechain/Unitroller";
import { Comptroller } from "../../../../typechain/Comptroller";
import { FLUX_GOVERNANCE_MULTISIG } from "../constants";
const link: DeployFunction = async function (_hre: HardhatRuntimeEnvironment) {
  const comptroller: Comptroller = await ethers.getContract("Comptroller");
  const unitroller: Unitroller = await ethers.getContract("Unitroller");
  console.log("setting pending implementation");
  await unitroller
    .connect(FLUX_GOVERNANCE_MULTISIG)
    ._setPendingImplementation(comptroller.address);
  console.log("accepting pending implementation");
  await comptroller
    .connect(FLUX_GOVERNANCE_MULTISIG)
    ._become(unitroller.address);
  console.log("Admin set in Unitroller");
};

export default link;
link.tags = ["Prod-Link-comptroller"];
link.dependencies = ["Prod-Comptroller", "Prod-Unitroller"];
