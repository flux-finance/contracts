import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { FLUX_GOVERNANCE_MULTISIG } from "../constants";
const { ethers } = require("hardhat");

const deployUnitroller: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const { deployments, getNamedAccounts } = hre;
  const { deployer } = await getNamedAccounts();
  const { deploy } = deployments;

  await deploy("Unitroller", {
    from: deployer,
    args: [FLUX_GOVERNANCE_MULTISIG],
    log: true,
  });
};

export default deployUnitroller;
deployUnitroller.tags = ["Prod-Unitroller"];
