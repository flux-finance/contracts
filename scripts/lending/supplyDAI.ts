import { BigNumber } from "ethers";

const hre = require("hardhat");
async function main() {
  const signers = await hre.ethers.getSigners();
  const dai = await hre.ethers.getContract("mockDai_local");
  const fDAI = await hre.ethers.getContract("fDAI");
  await dai.approve(fDAI.address, BigNumber.from("100000000000000000000"));
  await fDAI.mint(BigNumber.from("100000000000000000000"));
  console.log(`The signers address is: ${signers[0].address}`);
  console.log(
    `The fDAI balance is: ${(
      await fDAI.balanceOf(signers[0].address)
    ).toString()}`
  );
}
main();
