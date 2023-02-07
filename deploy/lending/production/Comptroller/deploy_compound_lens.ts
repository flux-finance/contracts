import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
const { ethers } = require("hardhat");

const deployCompoundLens: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const { deployments, getNamedAccounts } = hre;
  const { deployer } = await getNamedAccounts();
  const { deploy } = deployments;

  await deploy("CompoundLens", {
    from: deployer,
    args: [],
    log: true,
  });
  console.log("Lens deployed");
};

export default deployCompoundLens;
deployCompoundLens.tags = ["Prod-CompoundLens", "Prod"];
