import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import {
  CASH_ADDRESS,
  TIMELOCK_ADDRESS,
  KYC_REGISTRY_ADDRESS,
  KYC_REQUIREMENT_GROUP,
} from "../constants";

const deployfOUSG: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const { deployments, getNamedAccounts } = hre;
  const { deployer } = await getNamedAccounts();
  const { deploy } = deployments;

  const Unitroller = await ethers.getContract("Unitroller");
  const interestRateModel = await ethers.getContract("JumpRateModelV2");

  await deploy("fOUSGDelegate", {
    from: deployer,
    log: true,
    contract: "CCashDelegate",
  });

  const fOUSG = await ethers.getContract("fOUSGDelegate");

  console.log("Got fOUSG Impl");

  // https://etherscan.io/address/0xD8EC56013EA119E7181d231E5048f90fBbe753c0#code
  await deploy("fOUSG", {
    from: deployer,
    args: [
      CASH_ADDRESS, // underlying_
      Unitroller.address, // comptroller_
      interestRateModel.address, // interestRateModel_
      "200000000000000000000000000", // initialExchangeRateMantissa_
      "Flux OUSG", // name_
      "fOUSG", // symbol_
      8, // decimals_
      TIMELOCK_ADDRESS, // admin_
      fOUSG.address, // implementation_
      KYC_REGISTRY_ADDRESS, // kycRegistry_
      KYC_REQUIREMENT_GROUP, // kycRequirementGroup_
      "0x", // becomeImplementationData
    ],
    log: true,
    contract: "CErc20DelegatorKYC",
  });
  console.log("Deployed fOUSG");
};

export default deployfOUSG;
deployfOUSG.tags = ["Prod-fOUSG"];
