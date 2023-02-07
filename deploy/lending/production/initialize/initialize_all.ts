import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { Comptroller } from "../../../../typechain/Comptroller";

const initialize: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const BigNumber = ethers.BigNumber;

  const unitroller: Comptroller = await ethers.getContractAt(
    "Comptroller",
    "0x86324E40B386C3D5aeFcbB8aDfFBCf0554B3A409"
  );

  const fOUSG = await ethers.getContract("fOUSG");
  const fDAI = await ethers.getContract("fDAI");

  const ondoOracle = await ethers.getContract("OndoPriceOracle");

  await unitroller._supportMarket(fOUSG.address);
  await unitroller._supportMarket(fDAI.address);

  await unitroller._setCloseFactor(BigNumber.from("500000000000000000"));
  await unitroller._setPriceOracle(ondoOracle.address);
  await unitroller._setLiquidationIncentive(
    BigNumber.from("1050000000000000000")
  );

  await unitroller._setCollateralFactor(fOUSG.address, "920000000000000000");
  await unitroller._setBorrowPaused(fOUSG.address, true);
};

export default initialize;
initialize.tags = ["Prod-init"];
initialize.dependencies = [
  "Prod-JumpRateModelV2",
  "Prod-Link-comptroller",
  "Prod-fOUSG",
  "Prod-fDAI",
  "Prod-OndoPriceOracle",
];
