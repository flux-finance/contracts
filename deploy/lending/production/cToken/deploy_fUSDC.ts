import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import {
  FLUX_GOVERNANCE_MULTISIG,
  KYC_REGISTRY_ADDRESS,
  KYC_REQUIREMENT_GROUP,
  TIMELOCK_ADDRESS,
  USDC_ADDRESS,
} from "../constants";

const deployfUSDC: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const { deployments, getNamedAccounts } = hre;
  const { deployer } = await getNamedAccounts();
  const { deploy } = deployments;

  const Unitroller = await ethers.getContract("Unitroller");
  const interestRateModel = await ethers.getContract("JumpRateModelV2");

  await deploy("fUSDCDelegate", {
    from: deployer,
    log: true,
    contract: "CTokenDelegate",
  });

  const fUSDCDelegate = await ethers.getContract("fUSDCDelegate");

  console.log("Got fUSDC Impl");

  await deploy("fUSDC", {
    from: deployer,
    args: [
      USDC_ADDRESS, // underlying_
      Unitroller.address, // comptroller_
      interestRateModel.address, // interestRateModel_
      "200000000000000", // initialExchangeRateMantissa_
      "Flux USDC", // name_
      "fUSDC", // symbol_
      8, // decimals_
      TIMELOCK_ADDRESS, // admin_
      fUSDCDelegate.address, // implementation_
      KYC_REGISTRY_ADDRESS, // kycRegistry_
      KYC_REQUIREMENT_GROUP, // kycRequirementGroup_
      "0x", // becomeImplementationData
    ],
    log: true,
    contract: "CErc20DelegatorKYC",
  });
  console.log("Deployed fUSDC");
};

export default deployfUSDC;
deployfUSDC.tags = ["Prod-fUSDC"];
