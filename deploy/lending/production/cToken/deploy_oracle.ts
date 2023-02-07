import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { FLUX_GOVERNANCE_MULTISIG } from "../constants";

const deployOndoPriceOracle: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const { deployments, getNamedAccounts } = hre;
  const { deployer } = await getNamedAccounts();
  const { deploy } = deployments;

  await deploy("OndoPriceOracle", {
    from: deployer,
    log: true,
  });

  const ondoOracle = await ethers.getContract("OndoPriceOracle");
  ondoOracle.transferOwnership(FLUX_GOVERNANCE_MULTISIG);
};

export default deployOndoPriceOracle;
deployOndoPriceOracle.tags = ["Prod-OndoPriceOracle"];
