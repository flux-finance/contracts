import { task } from "hardhat/config";
import { SUCCESS_CHECK } from "../../utils/shell";
import {
  addContract,
  BaseProposalRequestParams,
  proposeFunctionCall,
} from "./helpers/defender-helper";
import {
  FLUX_GOVERNANCE_MULTISIG,
  TIMELOCK_ADDRESS,
} from "../../../deploy/lending/production/constants";
import { HardhatRuntimeEnvironment } from "hardhat/types";

task("link-unitroller", "Link Unitroller and Proxy to one another").setAction(
  async ({}, hre: HardhatRuntimeEnvironment) => {
    // Get params for unitroller + comptroller
    const unitroller = await hre.ethers.getContract("Unitroller");
    const unitrollerAbi = await hre.run("getDeployedContractABI", {
      contract: "Unitroller",
    });
    const comptroller = await hre.ethers.getContract("Comptroller");
    const comptrollerAbi = await hre.run("getDeployedContractABI", {
      contract: "Comptroller",
    });

    const network = await hre.run("getCurrentNetwork");
    let params: BaseProposalRequestParams = {
      via: FLUX_GOVERNANCE_MULTISIG,
      viaType: "Gnosis Safe",
    };

    // Add unitroller and comptroller to defender
    await addContract(network, unitroller.address, "Unitroller", unitrollerAbi);
    console.log(SUCCESS_CHECK + "Added Unitroller to Defender");
    await addContract(
      network,
      comptroller.address,
      "Comptroller",
      comptrollerAbi
    );
    console.log(SUCCESS_CHECK + "Added Comptroller to Defender");

    // Propose Set Implementation on Unitroller
    let contract = {
      network: network,
      address: unitroller.address,
    };
    params.title = "Set Implementation on Unitroller";
    params.title = "Add Comptroller as implementation on Unitroller";
    await proposeFunctionCall({
      contract: contract,
      params: params,
      functionName: "_setPendingImplementation",
      functionInterface: [
        {
          type: "address",
          name: "newPendingImplementation",
        },
      ],
      functionInputs: [comptroller.address],
    });
    console.log(SUCCESS_CHECK + "Proposed Set Implementation on Unitroller");

    // Propose become implementation on Comptroller
    contract = {
      network: network,
      address: comptroller.address,
    };
    params.title = "Comptroller become implementation on unitroller";
    params.description = "Comptroller become implementation on unitroller";
    await proposeFunctionCall({
      contract: contract,
      params: params,
      functionName: "_become",
      functionInterface: [
        {
          type: "address",
          name: "unitroller",
        },
      ],
      functionInputs: [unitroller.address],
    });
    console.log(
      SUCCESS_CHECK + "Proposed Become Implementation on Comptroller"
    );

    // Propose _setPendingAdmin on Unitroller
    contract = {
      network: network,
      address: unitroller.address,
    };
    params.title = "Set Pending Admin on Unitroller to Timelock";
    params.description = "Set Pending Admin on Unitroller to Timelock";
    await proposeFunctionCall({
      contract: contract,
      params: params,
      functionName: "_setPendingAdmin",
      functionInterface: [
        {
          type: "address",
          name: "newPendingAdmin",
        },
      ],
      functionInputs: [TIMELOCK_ADDRESS],
    });
    console.log(
      SUCCESS_CHECK + "Proposed Set Pending Admin on Unitroller to Timelock"
    );
  }
);
