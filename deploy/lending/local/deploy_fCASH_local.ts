import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { BigNumber } from "ethers";
import { KYC_REQUIREMENT_GROUP } from "./constants";

const { ethers } = require("hardhat");

const deploy_fCASH: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const { deployments, getNamedAccounts } = hre;
  const { deployer } = await getNamedAccounts();
  const { deploy, save } = deployments;

  const unitroller = await ethers.getContract("Unitroller");

  const cash = await ethers.getContract("CashKYCSenderReceiver");
  const interestRateModel = await ethers.getContract("JumpRateModelV2");

  await deploy("fCASHDelegate", {
    from: deployer,
    args: [],
    log: true,
    contract: "CCashDelegate",
  });

  const impl = await ethers.getContract("fCASHDelegate");
  const registry = await ethers.getContract("KYCRegistry");
  const artifactImpl = await deployments.getExtendedArtifact("CCashDelegate");

  await deploy("CErc20DelegatorKYC", {
    from: deployer,
    args: [
      cash.address,
      unitroller.address,
      interestRateModel.address,
      BigNumber.from("200000000000000000000000000"),
      "Flux Ondo Cash",
      "fCASH",
      BigNumber.from("8"),
      deployer,
      impl.address,
      registry.address,
      KYC_REQUIREMENT_GROUP,
      "0x",
    ],
    log: true,
  });

  const fCASHInstance = await ethers.getContract("CErc20DelegatorKYC");
  let fCASHProxied = {
    address: fCASHInstance.address,
    ...artifactImpl,
  };

  await save("fCASH", fCASHProxied);
};

export default deploy_fCASH;
deploy_fCASH.tags = ["fCASH", "Local"];
deploy_fCASH.dependencies = ["Comptroller", "InterestRateModel"];
