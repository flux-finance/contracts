import { task } from "hardhat/config";
import { SUCCESS_CHECK } from "../../utils/shell";
import {
  BaseProposalRequestParams,
  proposeFunctionCall,
} from "./helpers/defender-helper";
import {
  DAO_ADDRESS,
  FLUX_TEAM_MULTISIG,
  USDC_ADDRESS,
  DAI_ADDRESS,
  BURN_ADDRESS,
} from "../../../deploy/lending/production/constants";
import { HardhatRuntimeEnvironment } from "hardhat/types";

task("daoProposal_pt2", "Set Proposals to DAO").setAction(
  async ({}, hre: HardhatRuntimeEnvironment) => {
    const ethers = hre.ethers;
    const abi = new ethers.utils.AbiCoder();
    const network = await hre.run("getCurrentNetwork");
    let params: BaseProposalRequestParams = {
      via: FLUX_TEAM_MULTISIG,
      viaType: "Gnosis Safe",
    };
    let contract = {
      network: network,
      address: DAO_ADDRESS,
    };

    // Gov Proposal Lists
    let targets = [];
    let values = [];
    let signatures = [];
    let calldatas = [];

    // Get fUSDC and fDAI
    const fUSDC = await ethers.getContract("fUSDC");
    const fDAI = await ethers.getContract("fDAI");

    const unitroller = await ethers.getContract("Unitroller");

    // 9. Support fUSDC market
    targets.push(unitroller.address);
    values.push("0");
    signatures.push("_supportMarket(address)");
    calldatas.push(abi.encode(["address"], [fUSDC.address]));

    // 10. Set CollateralFactor for USDC
    targets.push(unitroller.address), values.push("0");
    signatures.push("_setCollateralFactor(address,uint256)");
    calldatas.push(
      abi.encode(
        ["address", "uint256"],
        [fUSDC.address, ethers.utils.parseUnits("85", 16).toString()]
      )
    );

    // 11. Approve USDC to fUSDC contract
    targets.push(USDC_ADDRESS);
    values.push("0");
    signatures.push("approve(address,uint256)");
    calldatas.push(
      abi.encode(
        ["address", "uint256"],
        [fUSDC.address, ethers.utils.parseUnits("10", 6).toString()]
      )
    );

    // 12. Mint fUSDC
    targets.push(fUSDC.address);
    values.push("0");
    signatures.push("mint(uint256)");
    calldatas.push(
      abi.encode(["uint256"], [ethers.utils.parseUnits("10", 6).toString()])
    );

    // 13. Burn fUSDC
    targets.push(fUSDC.address);
    values.push("0");
    signatures.push("transfer(address,uint256)");
    calldatas.push(
      abi.encode(
        ["address", "uint256"],
        [BURN_ADDRESS, ethers.utils.parseUnits("500", 8).toString()]
      )
    );

    // 14. Support DAI Market
    targets.push(unitroller.address);
    values.push("0");
    signatures.push("_supportMarket(address)");
    calldatas.push(abi.encode(["address"], [fDAI.address]));

    // 15. Set CollateralFactor For DAI
    targets.push(unitroller.address);
    values.push("0");
    signatures.push("_setCollateralFactor(address,uint256)");
    calldatas.push(
      abi.encode(
        ["address", "uint256"],
        [fDAI.address, ethers.utils.parseUnits("83", 16).toString()]
      )
    );

    // 16. Approve DAI to fDAI contract
    targets.push(DAI_ADDRESS);
    values.push("0");
    signatures.push("approve(address,uint256)");
    calldatas.push(
      abi.encode(
        ["address", "uint256"],
        [fDAI.address, ethers.utils.parseUnits("10", 18).toString()]
      )
    );

    // 17. Mint fDAI
    targets.push(fDAI.address);
    values.push("0");
    signatures.push("mint(uint256)");
    calldatas.push(
      abi.encode(["uint256"], [ethers.utils.parseUnits("10", 18).toString()])
    );

    // 18. Burn fDAI
    targets.push(fDAI.address);
    values.push("0");
    signatures.push("transfer(address,uint256)");
    calldatas.push(
      abi.encode(
        ["address", "uint256"],
        [BURN_ADDRESS, ethers.utils.parseUnits("500", 8).toString()]
      )
    );

    // Propose
    params.title = "DAO Governance Proposal pt. 2";
    params.description = "Initialize USDC & DAI markets";
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
    console.log(SUCCESS_CHECK + "Proposed DAO Governance Proposal pt. 2");
  }
);
