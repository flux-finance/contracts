import { BigNumber } from "ethers";

const hre = require("hardhat");
async function main() {
  const fUSDC = await hre.ethers.getContract("fUSDC");
  const fCASH = await hre.ethers.getContract("fCASH");
  const oracle = await hre.ethers.getContract("OndoPriceOracle");

  const uni = await hre.ethers.getContract("Unitroller");
  const trollerProxied = await hre.ethers.getContractAt(
    "Comptroller",
    uni.address
  );

  await trollerProxied._supportMarket(fUSDC.address);
  await trollerProxied._supportMarket(fCASH.address);

  await trollerProxied._setCloseFactor(BigNumber.from("1000000000000000000"));
  await trollerProxied._setLiquidationIncentive(
    BigNumber.from("1100000000000000000")
  );

  await trollerProxied._setPriceOracle(oracle.address);
  await trollerProxied._setCollateralFactor(
    fUSDC.address,
    BigNumber.from("850000000000000000")
  );
  await trollerProxied._setCollateralFactor(
    fCASH.address,
    BigNumber.from("920000000000000000")
  );

  await trollerProxied.enterMarkets([fCASH.address, fUSDC.address]);
  console.log("Markets Registered w/ Comptroller");
  console.log(await trollerProxied.getAllMarkets());
}

main();
