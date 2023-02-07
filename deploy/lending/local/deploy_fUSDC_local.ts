import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { BigNumber } from "ethers";
import { KYC_REQUIREMENT_GROUP } from "./constants";
import { USDC_ADDRESS } from "../production/constants";
const { ethers } = require("hardhat");

const deploy_fUSDC: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const { deployments, getNamedAccounts } = hre;
  const { deployer } = await getNamedAccounts();
  const { deploy, save } = deployments;
  console.log(`The deployer is ${deployer}`);

  const comp = await ethers.getContract("Unitroller");

  const usdc = await ethers.getContractAt("ERC20", USDC_ADDRESS);
  const interestRateModel = await ethers.getContract("JumpRateModelV2");

  await deploy("fUSDCDelegate", {
    from: deployer,
    args: [],
    contract: "CTokenDelegate",
    log: true,
  });

  const impl = await ethers.getContract("fUSDCDelegate");

  const artifactImpl = await deployments.getExtendedArtifact("CTokenDelegate");
  const registry = await ethers.getContract("KYCRegistry");

  await deploy("CErc20DelegatorKYC", {
    from: deployer,
    args: [
      usdc.address,
      comp.address,
      interestRateModel.address,
      BigNumber.from("200000000000000"),
      "Flux USDC Coin",
      "fUSDC",
      BigNumber.from(8),
      deployer,
      impl.address,
      registry.address,
      KYC_REQUIREMENT_GROUP,
      "0x",
    ],
    log: true,
  });

  const fUSDCInstance = await ethers.getContract("CErc20DelegatorKYC");
  let fUSDCProxied = {
    address: fUSDCInstance.address,
    ...artifactImpl,
  };
  await save("fUSDC", fUSDCProxied);
};

export default deploy_fUSDC;
deploy_fUSDC.tags = ["fUSDC", "Local"];
deploy_fUSDC.dependencies = ["Comptroller", "InterestRateModel"];
