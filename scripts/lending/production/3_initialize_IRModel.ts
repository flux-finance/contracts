import { task } from "hardhat/config";
import { SUCCESS_CHECK } from "../../utils/shell";
import {
  addContract,
  BaseProposalRequestParams,
  proposeFunctionCall,
} from "./helpers/defender-helper";
import { FLUX_GOVERNANCE_MULTISIG } from "../../../deploy/lending/production/constants";
import { HardhatRuntimeEnvironment } from "hardhat/types";

task(
  "Initialize_IRModel",
  "Initialize IR Model by Transferring Ownership"
).setAction(async ({}, hre: HardhatRuntimeEnvironment) => {
  // Get params for IR Model
  const irModel = await hre.ethers.getContract("JumpRateModelV2");
  const irModelImplementationAbi = await hre.run("getDeployedContractABI", {
    contract: "JumpRateModelV2",
  });

  const network = await hre.run("getCurrentNetwork");
  let params: BaseProposalRequestParams = {
    via: FLUX_GOVERNANCE_MULTISIG,
    viaType: "Gnosis Safe",
  };
  let contract = {
    network: network,
    address: irModel.address,
  };

  // Add IR Model to defender
  await addContract(
    network,
    irModel.address,
    "Interest Rate Model",
    irModelImplementationAbi
  );
  console.log(SUCCESS_CHECK + "Added IRModel to Defender");

  // Accept Ownership of IR Model
  params.title = "Accept Ownership of IRModel";
  await proposeFunctionCall({
    contract: contract,
    params: params,
    functionName: "acceptOwnership",
    functionInterface: [],
    functionInputs: [],
  });
  console.log(SUCCESS_CHECK + "Proposed acceptOwnership on IRModel");
});
