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

enum OracleType {
  UNINITIALIZED = "0",
  MANUAL = "1",
  COMPOUND = "2",
  CHAINLINK = "3",
}

task(
  "initializeOracleV2",
  "Initialize Oracle V2 with OUSG, DAI, USDC"
).setAction(async (args, hre: HardhatRuntimeEnvironment) => {
  // Get params for Oracle
  const ethers = hre.ethers;
  const oracle = await ethers.getContract("OndoPriceOracleV2");
  const oracleImplementationAbi = await hre.run("getDeployedContractABI", {
    contract: "OndoPriceOracleV2",
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
    "OndoOracleV2",
    oracleImplementationAbi
  );
  console.log(SUCCESS_CHECK + "Added OndoOracleV2 to Defender");

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
  const fDAIAbi = await hre.run("getDeployedContractABI", {
    contract: "fDAIDelegate",
  });
  await addContract(network, fDAI.address, "fDAI", fDAIAbi);
  console.log(SUCCESS_CHECK + "Added fDAI to Defender");

  // Set fOUSG Type
  params.title = "Set OUSG Type";
  await proposeFunctionCall({
    contract: contract,
    params: params,
    functionName: "setFTokenToOracleType",
    functionInterface: [
      {
        type: "address",
        name: "fToken",
      },
      {
        type: "uint8",
        name: "oracleType",
      },
    ],
    functionInputs: [fOUSG.address, OracleType.MANUAL],
  });
  console.log(SUCCESS_CHECK + "Proposed setFTokenToOracleType for OUSG");

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

  // Set fDAI Oracle Type
  params.title = "Set fDAI Type";
  await proposeFunctionCall({
    contract: contract,
    params: params,
    functionName: "setFTokenToOracleType",
    functionInterface: [
      {
        type: "address",
        name: "fToken",
      },
      {
        type: "uint8",
        name: "oracleType",
      },
    ],
    functionInputs: [fDAI.address, OracleType.COMPOUND],
  });
  console.log(SUCCESS_CHECK + "Proposed setFTokenToOracleType for fDAI");

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

  // Set fUSDC Oracle Type
  params.title = "Set fUSDC Type";
  await proposeFunctionCall({
    contract: contract,
    params: params,
    functionName: "setFTokenToOracleType",
    functionInterface: [
      {
        type: "address",
        name: "fToken",
      },
      {
        type: "uint8",
        name: "oracleType",
      },
    ],
    functionInputs: [fUSDC.address, OracleType.COMPOUND],
  });
  console.log(SUCCESS_CHECK + "Proposed setFTokenToOracleType for fUSDC");

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
