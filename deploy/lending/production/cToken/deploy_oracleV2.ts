import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { FLUX_GOVERNANCE_MULTISIG } from "../constants";

const deployOndoPriceOracleV2: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const { deployments, getNamedAccounts } = hre;
  const { deployer } = await getNamedAccounts();
  const { deploy } = deployments;

  await deploy("OndoPriceOracleV2", {
    from: deployer,
    log: true,
  });

  const ondoOracleV2 = await ethers.getContract("OndoPriceOracleV2");
  await ondoOracleV2.transferOwnership(FLUX_GOVERNANCE_MULTISIG);
};

export default deployOndoPriceOracleV2;
deployOndoPriceOracleV2.tags = ["Prod-OndoPriceOracleV2"];
