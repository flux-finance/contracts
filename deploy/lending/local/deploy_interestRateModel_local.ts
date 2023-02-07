import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { BigNumber } from "ethers";

const deployInterestRateModel: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const { deployments, getNamedAccounts } = hre;
  const { deployer } = await getNamedAccounts();
  const { deploy } = deployments;
  // OBFR as per: https://ycharts.com/indicators/overnight_federal_funds_rate_market_daily on 1/25 is 4.33%
  // Rate at kink should be OBFR - 50 bps = 3.83%
  // Rate at 100% utilization should be OBFR + 300 bps = 7.33%
  // Thus, @100% Util, the jumpMutiplierPerYear, x, is 3.83% + 1 * [util] * x = 7.33%, x = 3.5%
  await deploy("JumpRateModelV2", {
    args: [
      0, // baseRatePerYear
      "38300000000000000", // multiplierPerYear
      "350000000000000000", // jumpMultiplierPerYear
      "900000000000000000", // kink
    ],
    from: deployer,
    log: true,
  });
};

export default deployInterestRateModel;
deployInterestRateModel.tags = ["InterestRateModel", "Local"];
