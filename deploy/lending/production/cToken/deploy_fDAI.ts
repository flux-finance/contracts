import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import {
  DAI_ADDRESS,
  KYC_REGISTRY_ADDRESS,
  KYC_REQUIREMENT_GROUP,
  TIMELOCK_ADDRESS,
} from "../constants";

const deployfDAI: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const { deployments, getNamedAccounts } = hre;
  const { deployer } = await getNamedAccounts();
  const { deploy } = deployments;

  const Unitroller = await ethers.getContract("Unitroller");
  const interestRateModel = await ethers.getContract("JumpRateModelV2");

  await deploy("fDAIDelegate", {
    from: deployer,
    log: true,
    contract: "CTokenDelegate",
  });

  const fDAI = await ethers.getContract("fDAIDelegate");

  console.log("Got fDAI Impl");

  await deploy("fDAI", {
    from: deployer,
    args: [
      DAI_ADDRESS, // underlying_
      Unitroller.address, // comptroller_
      interestRateModel.address, // interestRateModel_
      "200000000000000000000000000", // initialExchangeRateMantissa_
      "Flux DAI", // name_
      "fDAI", // symbol_
      8, // decimals_
      TIMELOCK_ADDRESS, // admin_
      fDAI.address, // implementation_
      KYC_REGISTRY_ADDRESS, // kycRegistry_
      KYC_REQUIREMENT_GROUP, // kycRequirementGroup_
      "0x", // becomeImplementationData
    ],
    log: true,
    contract: "CErc20DelegatorKYC",
  });
  console.log("Deployed fDAI");
};

export default deployfDAI;
deployfDAI.tags = ["Prod-fDAI"];
