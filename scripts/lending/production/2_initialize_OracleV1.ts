import { task } from "hardhat/config";
import { SUCCESS_CHECK } from "../../utils/shell";
import {
  addContract,
  BaseProposalRequestParams,
  proposeFunctionCall,
} from "./helpers/defender-helper";
import {
  COMPOUNDS_CDAI_ADDRESS,
  COMPOUNDS_CUSDC_ADDRESS,
  FLUX_GOVERNANCE_MULTISIG,
} from "../../../deploy/lending/production/constants";
import { HardhatRuntimeEnvironment } from "hardhat/types";

task(
  "initializeOracleV1",
  "Initialize Oracle V1 with OUSG, DAI, USDC"
).setAction(async ({}, hre: HardhatRuntimeEnvironment) => {
  // Get params for Oracle
  const ethers = hre.ethers;
  const oracle = await ethers.getContract("OndoPriceOracle");
  const oracleImplementationAbi = await hre.run("getDeployedContractABI", {
    contract: "OndoPriceOracle",
  });

  const network = await hre.run("getCurrentNetwork");
  let params: BaseProposalRequestParams = {
    via: FLUX_GOVERNANCE_MULTISIG,
    viaType: "Gnosis Safe",
  };
  let contract = {
    network: network,
    address: oracle.address,
  };

  // Add Oracle to defender
  await addContract(
    network,
    oracle.address,
    "OndoOracleV1",
    oracleImplementationAbi
  );
  console.log(SUCCESS_CHECK + "Added OndoOracleV1 to Defender");

  // Add fOUSG to Defender
  const fOUSG = await ethers.getContract("fOUSG");
  const fOUSGAbi = await hre.run("getDeployedContractABI", {
    contract: "fOUSGDelegate",
  });
  await addContract(network, fOUSG.address, "fOUSG", fOUSGAbi);
  console.log(SUCCESS_CHECK + "Added fOUSG to Defender");

  // Add fUSDC to Defender
  const fUSDC = await ethers.getContract("fUSDC");
  const fUSDCAbi = await hre.run("getDeployedContractABI", {
    contract: "fUSDCDelegate",
  });
  await addContract(network, fUSDC.address, "fUSDC", fUSDCAbi);
  console.log(SUCCESS_CHECK + "Added fUSDC to Defender");

  // Add fDAI to Defender
  const fDAI = await ethers.getContract("fDAI");
  const fDAIAbi = await hre.run("GetDeployedContractABI", {
    contract: "fDAIDelegate",
  });
  await addContract(network, fDAI.address, "fDAI", fDAIAbi);
  console.log(SUCCESS_CHECK + "Added fDAI to Defender");

  // Accept Ownership of oracle
  params.title = "Accept Ownership of Oracle";
  await proposeFunctionCall({
    contract: contract,
    params: params,
    functionName: "acceptOwnership",
    functionInterface: [],
    functionInputs: [],
  });
  console.log(SUCCESS_CHECK + "Proposed acceptOwnership on Oracle");

  // Set fOUSG Price
  const price = hre.ethers.utils.parseUnits("100", 18).toString();
  params.title = "Set OUSG Price";
  await proposeFunctionCall({
    contract: contract,
    params: params,
    functionName: "setPrice",
    functionInterface: [
      {
        type: "address",
        name: "fToken",
      },
      {
        type: "uint256",
        name: "price",
      },
    ],
    functionInputs: [fOUSG.address, price],
  });
  console.log(SUCCESS_CHECK + "Proposed setPrice for fOUSG");

  // Set fDAI -> cDAI relationship
  params.title = "Set fDAI -> cDAI in Oracle";
  await proposeFunctionCall({
    contract: contract,
    params: params,
    functionName: "setFTokenToCToken",
    functionInterface: [
      {
        type: "address",
        name: "fToken",
      },
      {
        type: "address",
        name: "cToken",
      },
    ],
    functionInputs: [fDAI.address, COMPOUNDS_CDAI_ADDRESS],
  });
  console.log(SUCCESS_CHECK + "Proposed setFTokenToCToken for fDAI");

  // Set fUSDC -> cUSDC relationship
  params.title = "Set fUSDC -> cUSDC in Oracle";
  await proposeFunctionCall({
    contract: contract,
    params: params,
    functionName: "setFTokenToCToken",
    functionInterface: [
      {
        type: "address",
        name: "fToken",
      },
      {
        type: "address",
        name: "cToken",
      },
    ],
    functionInputs: [fUSDC.address, COMPOUNDS_CUSDC_ADDRESS],
  });
  console.log(SUCCESS_CHECK + "Proposed setFTokenToCToken for fUSDC");
});
