import { BigNumber } from "ethers";

const hre = require("hardhat");
async function main() {
  const signers = await hre.ethers.getSigners();
  const dai = await hre.ethers.getContract("mockDai_local");
  const fDAI = await hre.ethers.getContract("fDAI");
  const uni = await hre.ethers.getContract("Unitroller");
  const trollerProxied = await hre.ethers.getContractAt(
    "Comptroller",
    uni.address
  );
  const result = await trollerProxied.getAccountLiquidity(signers[0].address);
  console.log(
    `The Dai balance of this address before borrow is ${(
      await dai.balanceOf(signers[0].address)
    ).toString()}`
  );
  await fDAI.borrow(BigNumber.from("50000000000000000000"));
  console.log(`The address of the signer is: ${signers[0].address}`);
  console.log(
    `The Dai balance of this address after borrow is ${(
      await dai.balanceOf(signers[0].address)
    ).toString()}`
  );
}
main();
