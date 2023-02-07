import { task } from "hardhat/config";
import { SUCCESS_CHECK } from "../../utils/shell";
import {
  BaseProposalRequestParams,
  proposeFunctionCall,
} from "./helpers/defender-helper";
import {
  DAO_ADDRESS,
  FLUX_GOVERNANCE_MULTISIG,
} from "../../../deploy/lending/production/constants";
import { HardhatRuntimeEnvironment } from "hardhat/types";

task("test", "Set Proposals to DAO").setAction(
  async ({}, hre: HardhatRuntimeEnvironment) => {
    const network = await hre.run("getCurrentNetwork");
    const ethers = hre.ethers;
    const abi = new ethers.utils.AbiCoder();
    let params: BaseProposalRequestParams = {
      via: FLUX_GOVERNANCE_MULTISIG,
      viaType: "Gnosis Safe",
    };
    let contract = {
      network: network,
      address: DAO_ADDRESS,
    };

    // Remove old unitroller and add unitroller with comptroller ABI to defender
    let targets = [];
    let values = [];
    let signatures = [];
    let calldatas = [];

    targets.push(DAO_ADDRESS);
    values.push("0");
    signatures.push("_setVotingPeriod(uint256)");
    calldatas.push(abi.encode(["uint256"], [100]));

    params.title = "Set voting period to 100 blocks";
    params.description = "Set voting period to 100 blocks";
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
