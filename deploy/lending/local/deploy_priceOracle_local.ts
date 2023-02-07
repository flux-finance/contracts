import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { parseUnits } from "ethers/lib/utils";
import {
  COMPOUNDS_CDAI_ADDRESS,
  COMPOUNDS_CUSDC_ADDRESS,
} from "../production/constants";
import { Comptroller } from "../../../typechain";
const { ethers } = require("hardhat");

const deployPriceOracle: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const { deployments, getNamedAccounts } = hre;
  const { deployer } = await getNamedAccounts();
  const { deploy } = deployments;

  const fCASH = await ethers.getContract("fCASH");
  const fUSDC = await ethers.getContract("fUSDC");
  const fDAI = await ethers.getContract("fDAI");

  await deploy("OndoPriceOracle", {
    from: deployer,
    log: true,
  });

  // Post Deployment Scripts
  const oracleContract = await ethers.getContract("OndoPriceOracle");
  await oracleContract.setPrice(fCASH.address, parseUnits("1", 18));
  await oracleContract.setFTokenToCToken(fDAI.address, COMPOUNDS_CDAI_ADDRESS);
  await oracleContract.setFTokenToCToken(
    fUSDC.address,
    COMPOUNDS_CUSDC_ADDRESS
  );

  // Set Price Oracle
  const unitroller = await ethers.getContract("Unitroller");
  const comptroller: Comptroller = await ethers.getContractAt(
    "Comptroller",
    unitroller.address
  );
  await comptroller._setPriceOracle(oracleContract.address);

  // Support Markets and Set CF
  await comptroller._supportMarket(fCASH.address);
  await comptroller._setCollateralFactor(fCASH.address, parseUnits("92", 16));
  await comptroller._setBorrowPaused(fCASH.address, true);

  await comptroller._supportMarket(fDAI.address);
  await comptroller._setCollateralFactor(fDAI.address, parseUnits("83", 16));

  await comptroller._supportMarket(fUSDC.address);
  await comptroller._setCollateralFactor(fUSDC.address, parseUnits("85", 16));
};

export default deployPriceOracle;
deployPriceOracle.tags = ["PriceOracle", "Local"];
deployPriceOracle.dependencies = ["Comptroller", "fCASH", "fDAI", "fUSDC"];
