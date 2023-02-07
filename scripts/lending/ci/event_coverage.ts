import { BigNumber } from "ethers";
import { parseUnits } from "ethers/lib/utils";
import { ethers } from "hardhat";
import {
  getImpersonatedSigner,
  waitNSecondsUntilNodeUp,
} from "../../utils/util";
import {
  DAI_ADDRESS,
  MINTER_ROLE,
} from "../../../deploy/lending/production/constants";
const hre = require("hardhat");

// MUST BE RAN AGAINST A LOCAL NODE FORKED FROM MAINNET BLOCK 16227003+

async function main() {
  // This script is assumes you have an eth node hosted at localhost ip.
  await waitNSecondsUntilNodeUp("http://127.0.0.1:8545", 30);
  // Read in signers
  const signers = await hre.ethers.getSigners();
  const guardian = signers[1];
  const alice = signers[2];
  const charlie = signers[3];
  const daiWhale = await getImpersonatedSigner(
    "0xf977814e90da44bfa03b6295a0616a897441acec"
  );

  // Read in Contracts
  const usdc = await hre.ethers.getContractAt("ERC20", DAI_ADDRESS);
  const cash = await hre.ethers.getContract("CashKYCSenderReceiver");
  const fCASH = await hre.ethers.getContract("fCASH");
  const fDAI = await hre.ethers.getContract("fDAI");
  {
    const kycRegistry = await hre.ethers.getContract("KYCRegistry");
    await kycRegistry
      .connect(guardian)
      .addKYCAddresses(BigNumber.from(3), [
        alice.address,
        charlie.address,
        fCASH.address,
        signers[0].address,
        guardian.address,
      ]);
  }
  await cash.connect(guardian).grantRole(MINTER_ROLE, guardian.address);
  await cash
    .connect(guardian)
    .mint(signers[0].address, parseUnits("1000000", 18));
  await usdc
    .connect(daiWhale)
    .transfer(signers[0].address, parseUnits("50000", 18));

  const oracle = await hre.ethers.getContract("OndoPriceOracle");

  const uni = await hre.ethers.getContract("Unitroller");
  const trollerProxied = await hre.ethers.getContractAt(
    "Comptroller",
    uni.address
  );

  // Setup Markets
  await trollerProxied._supportMarket(fDAI.address);
  await trollerProxied._supportMarket(fCASH.address);

  await trollerProxied._setCloseFactor(BigNumber.from("1000000000000000000"));
  await trollerProxied._setLiquidationIncentive(
    BigNumber.from("1100000000000000000")
  );

  await trollerProxied._setPriceOracle(oracle.address);
  await trollerProxied._setCollateralFactor(fDAI.address, "830000000000000000");
  await trollerProxied._setCollateralFactor(
    fCASH.address,
    "920000000000000000"
  );

  // Seed users
  await usdc.transfer(alice.address, parseUnits("1000", 18));
  await cash.transfer(charlie.address, parseUnits("1000", 18));
  await usdc.transfer(alice.address, parseUnits("1", 18));

  // Have alice deposit and withdraw from the usdc pool
  await usdc.connect(alice).approve(fDAI.address, parseUnits("100", 18));
  await fDAI.connect(alice).mint(parseUnits("100", 18));
  await fDAI.connect(alice).redeemUnderlying(parseUnits("100", 18));

  // Have charlie deposit and withdraw from the cash pool
  await cash.connect(charlie).approve(fCASH.address, parseUnits("100", 18));
  await fCASH.connect(charlie).mint(parseUnits("100", 18));
  await fCASH.connect(charlie).redeemUnderlying(parseUnits("100", 18));

  // Have alice deposit usdc
  await usdc.connect(alice).approve(fDAI.address, parseUnits("100", 18));
  await fDAI.connect(alice).mint(parseUnits("100", 18));

  // Have charlie deposit and borrow max USDC against his position
  await cash.connect(charlie).approve(fCASH.address, parseUnits("100", 18));
  await fCASH.connect(charlie).mint(parseUnits("100", 18));
  await trollerProxied.connect(charlie).enterMarkets([fCASH.address]);

  await fDAI.connect(charlie).borrow(parseUnits("50", 18));
  const result = await usdc.balanceOf(charlie.address);

  // Have charlie make a partial repayment
  await usdc.connect(charlie).approve(fDAI.address, parseUnits("1", 18));
  await fDAI.connect(charlie).repayBorrow(parseUnits("1", 18));

  // Crash the price of cash through the oracle
  await oracle.setPrice(fCASH.address, "250000000000000000");
  const val = await trollerProxied.getAccountLiquidity(charlie.address);

  // Have Alice Liquidate bobs collateral
  await usdc.connect(alice).approve(fDAI.address, parseUnits("10", 18));
  await fDAI
    .connect(alice)
    .liquidateBorrow(charlie.address, parseUnits("10", 18), fCASH.address);
  const fCASHAlice = await fCASH.balanceOf(alice.address);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
