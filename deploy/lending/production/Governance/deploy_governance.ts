import { BigNumber } from "ethers";
import { parseUnits } from "ethers/lib/utils";
import { ethers } from "hardhat";
import { DeployFunction } from "hardhat-deploy/types";
import { FLUX_GOVERNANCE_MULTISIG, ONDO_TOKEN_ADDRESS } from "../constants";

// Initial Governance Parameters
export const TIMELOCK_DELAY = 1 * 24 * 60 * 60; // 1 day in seconds
export const VOTING_PERIOD = 21600; // 3 days in blocks
export const PROPOSAL_PENDING = 1; // in blocks
export const PROPOSAL_THRESHOLD = parseUnits("100000000", 18); // 100 million in tokens [18 decimals]
const deployFunc: DeployFunction = async (hre) => {
  const { deployments, getNamedAccounts, network } = hre;
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  /**
   *
   * 1. deploy timelock with EOA admin
   * 2. deploy governerbravo with timelock as admin
   * 3. queue transaction in timelock to set pending admin of timelock to governerbravo
   * 4. queue transaction in timelock to call initiate which will accept admin in timelock
   * 5. execute transaction for pending admin
   * 6. execute transation for initiate in timelock
   */
  //deploy Timelock
  await deploy("Timelock", {
    from: deployer,
    args: [
      FLUX_GOVERNANCE_MULTISIG, // admin
      TIMELOCK_DELAY, // execution delay in seconds
    ],
    log: true,
  });

  const timelock = await ethers.getContract("Timelock");

  // deploy DAO implementation
  await deploy("GovernorBravoDelegate", {
    from: deployer,
    log: true,
  });
  const daoImpl = await ethers.getContract("GovernorBravoDelegate");

  // deploy DAO delegator
  await deploy("GovernorBravoDelegator", {
    from: deployer,
    args: [
      timelock.address, // timelock
      ONDO_TOKEN_ADDRESS, // Ondo token
      timelock.address, // admin
      daoImpl.address, // implementation
      VOTING_PERIOD, // voting period in blocks
      PROPOSAL_PENDING, // proposal pending period in blocks
      PROPOSAL_THRESHOLD, // proposal threshold in Ondos
    ],
    log: true,
  });
};

deployFunc.tags = ["Prod-Dao"];

export default deployFunc;
