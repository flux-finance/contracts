import { task } from "hardhat/config";
import { SUCCESS_CHECK } from "../../utils/shell";
import {
  addContract,
  BaseProposalRequestParams,
  deleteContract,
  proposeFunctionCall,
} from "./helpers/defender-helper";
import {
  DAO_ADDRESS,
  FLUX_GOVERNANCE_MULTISIG,
} from "../../../deploy/lending/production/constants";
import { HardhatRuntimeEnvironment } from "hardhat/types";

task("daoProposal_pt1", "Set Proposals to DAO").setAction(
  async ({}, hre: HardhatRuntimeEnvironment) => {
    // Get params for unitroller
    const ethers = hre.ethers;
    const abi = new ethers.utils.AbiCoder();
    const unitroller = await ethers.getContract("Unitroller");
    const comptrollerAbi = await hre.run("getDeployedContractABI", {
      contract: "Comptroller",
    });

    const network = await hre.run("getCurrentNetwork");
    let params: BaseProposalRequestParams = {
      via: FLUX_GOVERNANCE_MULTISIG,
      viaType: "Gnosis Safe",
    };
    let contract = {
      network: network,
      address: DAO_ADDRESS,
    };

    // Remove old unitroller and add unitroller with comptroller ABI to defender
    await deleteContract(unitroller.address);
    await addContract(
      network,
      unitroller.address,
      "Unitroller",
      comptrollerAbi
    );
    console.log(SUCCESS_CHECK + "Added Unitroller to Defender");

    let targets = [];
    let values = [];
    let signatures = [];
    let calldatas = [];

    // Get fOUSG Contract
    const fOUSG = await ethers.getContract("fOUSG");

    // DAO and Timelock have already been added to defender

    // 1. Accept ownership of Comptroller
    targets.push(unitroller.address);
    values.push("0");
    signatures.push("_acceptAdmin()");
    calldatas.push("0x");

    // 2. Set Pause Guardian to Flux MSig
    targets.push(unitroller.address);
    values.push("0");
    signatures.push("_setPauseGuardian(address)");
    calldatas.push(abi.encode(["address"], [FLUX_GOVERNANCE_MULTISIG]));

    // 3. Set Close Factor
    targets.push(unitroller.address);
    values.push("0");
    signatures.push("_setCloseFactor(uint256)");
    calldatas.push(
      abi.encode(["uint256"], [ethers.utils.parseUnits("0.5", 18).toString()])
    );

    // 4. Set Liquidation Incentive
    targets.push(unitroller.address);
    values.push("0");
    signatures.push("_setLiquidationIncentive(uint256)");
    calldatas.push(
      abi.encode(["uint256"], [ethers.utils.parseUnits("1.05", 18).toString()])
    );

    // 5. Set Price Oracle
    const priceOracle = await ethers.getContract("OndoPriceOracleV2");
    targets.push(unitroller.address);
    values.push("0");
    signatures.push("_setPriceOracle(address)");
    calldatas.push(abi.encode(["address"], [priceOracle.address]));

    // 6. Support OUSG Market
    targets.push(unitroller.address);
    values.push("0");
    signatures.push("_supportMarket(address)");
    calldatas.push(abi.encode(["address"], [fOUSG.address]));

    // 7. Set OUSG Collateral Factor
    targets.push(unitroller.address);
    values.push("0");
    signatures.push("_setCollateralFactor(address,uint256)");
    calldatas.push(
      abi.encode(
        ["address", "uint256"],
        [fOUSG.address, ethers.utils.parseUnits("92", 16).toString()]
      )
    );

    // 8. Pause Borrow for OUSG
    targets.push(unitroller.address);
    values.push("0");
    signatures.push("_setBorrowPaused(address,bool)");
    calldatas.push(abi.encode(["address", "bool"], [fOUSG.address, true]));

    // Propose
    params.title = "DAO Governance Proposal pt. 1";
    params.description = "Initialize Comptroller & OUSG Market";
    await proposeFunctionCall({
      contract: contract,
      params: params,
      functionName: "propose",
      functionInterface: [
        {
          type: "address[]",
          name: "targets",
        },
        {
          type: "uint256[]",
          name: "values",
        },
        {
          type: "string[]",
          name: "signatures",
        },
        {
          type: "bytes[]",
          name: "calldatas",
        },
        {
          type: "string",
          name: "description",
        },
      ],
      functionInputs: [
        targets,
        values,
        signatures,
        calldatas,
        params.description,
      ],
    });
    console.log(SUCCESS_CHECK + "Proposed DAO Governance Proposal pt. 1");
  }
);
