import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { BigNumber } from "ethers";
import { Comptroller } from "../../../typechain";
const { ethers } = require("hardhat");

const deployComptroller: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const { deployments, getNamedAccounts } = hre;
  const { deployer } = await getNamedAccounts();
  const { deploy } = deployments;

  await deploy("Unitroller", {
    from: deployer,
    args: [deployer],
    log: true,
  });

  await deploy("Comptroller", {
    from: deployer,
    args: [deployer],
    log: true,
  });

  const comp = await ethers.getContract("Comptroller");
  const unitroller = await ethers.getContract("Unitroller");

  await unitroller._setPendingImplementation(comp.address);
  await comp._become(unitroller.address);

  console.log(`Unitroller is deployed @: ${unitroller.address}`);
  console.log(`Compound Implementation is deployed @ ${comp.address}`);
  console.log(
    `The impl of the proxy ${await unitroller.comptrollerImplementation()}`
  );
  console.log(
    `The admin of the unitroller contract is ${await unitroller.admin()}`
  );

  // Post Deployment Setup
  const comptroller: Comptroller = await ethers.getContractAt(
    "Comptroller",
    unitroller.address
  );
  await comptroller._setCloseFactor(BigNumber.from("500000000000000000"));
  await comptroller._setLiquidationIncentive(
    BigNumber.from("1050000000000000000")
  );
};

export default deployComptroller;
deployComptroller.tags = ["Comptroller", "Local"];
