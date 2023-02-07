import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { FLUX_GOVERNANCE_MULTISIG } from "../constants";
const { ethers } = require("hardhat");

const deployJumpRateModelV2: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const { deployments, getNamedAccounts } = hre;
  const { deployer } = await getNamedAccounts();
  const { deploy } = deployments;

  // OBFR as per: https://ycharts.com/indicators/overnight_federal_funds_rate_market_daily on 1/30 is 4.33%
  // Rate at kink should be OBFR - 50 bps = 3.83%
  // Rate at 100% utilization should be OBFR + 300 bps = 7.33%
  // Thus, @100% Util, the jumpMutiplierPerYear, x, is 3.83% + 1 * [util] * x = 7.33%, x = 3.5%
  await deploy("JumpRateModelV2", {
    from: deployer,
    args: [
      0, // baseRatePerYear
      "38300000000000000", // multiplierPerYear
      "350000000000000000", // jumpMultiplierPerYear
      "900000000000000000", // kink
    ],
    log: true,
  });

  const jumpRateModelV2 = await ethers.getContract("JumpRateModelV2");
  await jumpRateModelV2.transferOwnership(FLUX_GOVERNANCE_MULTISIG);
};

export default deployJumpRateModelV2;
deployJumpRateModelV2.tags = ["Prod-JumpRateModelV2"];
