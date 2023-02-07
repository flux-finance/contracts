import { parseUnits } from "ethers/lib/utils";

const hre = require("hardhat");
async function main() {
  const signers = await hre.ethers.getSigners();
  const charlie = signers[1];
  const alice = signers[2];
  const dai = await hre.ethers.getContract("mockDai_local");
  const cash = await hre.ethers.getContract("mockCash_local");
  const fCASH = await hre.ethers.getContract("fCASH");
  const fDAI = await hre.ethers.getContract("fDAI");
  const oracle = await hre.ethers.getContract("OndoPriceOracle");
  const uni = await hre.ethers.getContract("Unitroller");
  const trollerProxied = await hre.ethers.getContractAt(
    "Comptroller",
    uni.address
  );

  await dai.connect(alice).approve(fDAI.address, parseUnits("10", 18));
  await fDAI
    .connect(alice)
    .liquidateBorrow(charlie.address, parseUnits("10", 18), fCASH.address, {
      gasLimit: 6000000,
    });
  await hre.network.provider.send("evm_mine", []);
  console.log(
    `Alice: ${alice.address}, has liquidated charlie: ${charlie.address}`
  );
  console.log(
    `Alice's balance of fCASH is ${(
      await fCASH.balanceOf(alice.address)
    ).toString()}`
  );
  console.log(
    `Alice's balance in underlying ${(
      await fCASH.callStatic.balanceOfUnderlying(alice.address)
    ).toString()}`
  );
}
main();
