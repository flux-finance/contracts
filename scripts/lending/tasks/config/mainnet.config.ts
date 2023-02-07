import { ethers } from "ethers";
import { keccak256 } from "ethers/lib/utils";
import { parseUnits } from "ethers/lib/utils";
import { DAI_ADDRESS } from "../../../../deploy/lending/production/constants";

//**** Constants that we do not expect to have to change ***//
const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";
const ZERO_ROLE =
  "0x0000000000000000000000000000000000000000000000000000000000000000";
const EXPECTED_BLOCKS_PER_YEAR = 2628000;
const OUSG_CASH_MANAGER_ADDRESS = "0x70b45A68ca257Db49DEC455af6c725F7F1C904e8";
const OUSG_CASH_PROXY_ADMIN_ADDRESS =
  "0xBA80Aa44cC25E85CC30359150dfB1C7D041CF6d5";
const OUSG_CASH_PROXY_ADDRESS = "0x1B19C19393e2d034D8Ff31ff34c81252FcBbee92";
const OUSG_CASH_IMPL_ADDRESS = "0xDB77d0d3d9bf850E38282eD8B5Fb410D02E75d2D";
const USDC_ADDRESS = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
const KYC_REGISTRY_ADDRESS = "0x7cE91291846502D50D635163135B2d40a602dc70";
const SANCTIONS_ORACLE_ADDRESS = "0x40C57923924B5c5c5455c48D93317139ADDaC8fb";
// Initial Governance Parameters
const TIMELOCK_DELAY = 1 * 24 * 60 * 60; // 1 day in seconds
const VOTING_PERIOD = 21600; // 3 days in blocks
const PROPOSAL_PENDING = 1; // in blocks
const PROPOSAL_THRESHOLD = parseUnits("100000000", 18); // 100 million in tokens [18 decimals]
const ONDO_TOKEN_ADDRESS = "0xfAbA6f8e4a5E8Ab82F62fe7C39859FA577269BE3";
const GOVERNOR_DELEGATOR_ADDRESS = "0x336505EC1BcC1A020EeDe459f57581725D23465A";
const GOVERNOR_DELEGATE_ADDRESS = "0x8886344A1b9B840Bed590F2Ef7379DD37e169c8e";
const TIMELOCK_ADDRESS = "0x2c5898da4DF1d45EAb2B7B192a361C3b9EB18d9c";
const INTEREST_RATE_MODEL_ADDRESS =
  "0xFD3Ffbb58bc27406BBe51918bE3c6B2E48380570";

// Constants that we expect to have to change after deployment
const CASH_MULTISIG = "0xAEd4caF2E535D964165B4392342F71bac77e8367";

// Initialized Unitroller/Comptroller + Corresponding Guardian
const FLUX_GOVERNANCE_MULTISIG = "0x118919e891D0205A7492650AD32E727617FA9452";
const UNITROLLER_ADDRESS = "0x95Af143a021DF745bc78e845b54591C53a8B3A51";
const COMPTROLLER_ADDRESS = "0xdc7b90593CafE7a919D22B903fEd21BF27da9719";
const ORACLE_ADDRESS = "0xba9b10f90b0ef26711373a0d8b6e7741866a7ef2";

// FToken Addresses
const fDAI_PROXY_ADDRESS = "0xe2bA8693cE7474900A045757fe0efCa900F6530b";
const fDAI_IMPLEMENTATION_ADDRESS =
  "0x690Ef7cD8Af50179fBBD09AbC4017e59C2AE7d82";
const fOUSG_PROXY_ADDRESS = "0x1dD7950c266fB1be96180a8FDb0591F70200E018";
const fOUSG_IMPLEMENTATION_ADDRESS =
  "0x159d359b55a6D0cBE9b306862D13515fa1992d0a";
const fUSDC_PROXY_ADDRESS = "0x465a5a630482f3abD6d3b84B39B29b07214d19e5";
const fUSDC_IMPLEMENTATION_ADDRESS =
  "0xb521dcf5B12E878811e079C2159EC56d5eDAfbc5";

const config = {
  ousg: {
    cashManagerAddress: OUSG_CASH_MANAGER_ADDRESS,
    cashManager: {
      BPS_DENOMINATOR: 10_000,
      DEFAULT_ADMIN_ROLE: ZERO_ROLE,
      MANAGER_ADMIN: keccak256(Buffer.from("MANAGER_ADMIN", "utf-8")),
      PAUSER_ADMIN: keccak256(Buffer.from("PAUSER_ADMIN", "utf-8")),
      SETTER_ADMIN: keccak256(Buffer.from("SETTER_ADMIN", "utf-8")),
      assetRecipient: "0xD3d9f0399Fd868935347D1146A618668726d1bB1", // Coinbase custody
      assetSender: CASH_MULTISIG,
      cash: OUSG_CASH_PROXY_ADDRESS,
      collateral: USDC_ADDRESS,
      // 10 ** (decimals of OUSG - decimals of USDC) = 1e12
      decimalsMultiplier: parseUnits("1", 12).toString(),
      epochDuration: 86400,
      exchangeRateDeltaLimit: 100,
      feeRecipient: CASH_MULTISIG,
      kycRegistry: KYC_REGISTRY_ADDRESS,
      kycRequirementGroup: 1,
      minimumDepositAmount: 100000000, // 100 USDC for now.
      minimumRedeemAmount: 10000000000000000000000, // 10k CASH for now.
      mintFee: 0,
      mintLimit: 1000000000000000, // 1 Billion USDC
      paused: false,
      redeemLimit: 1000000000000000000000000000, // 1 Billion CASH for now.
    },
    cashManagerRoleMembers: {
      defaultAdminRoleMembers: [CASH_MULTISIG],
      managerAdminRoleMembers: [CASH_MULTISIG],
      pauserAdminRoleMembers: [CASH_MULTISIG],
      setterAdminRoleMembers: [], // for now.
    },
    cashProxyAddress: OUSG_CASH_PROXY_ADDRESS,
    cashProxy: {
      proxyAdmin: OUSG_CASH_PROXY_ADMIN_ADDRESS,
      rollback: ZERO_ADDRESS,
      beacon: ZERO_ADDRESS,
      implementation: OUSG_CASH_IMPL_ADDRESS,
      implementationStorage: {
        DEFAULT_ADMIN_ROLE: ZERO_ROLE,
        KYC_CONFIGURER_ROLE: keccak256(
          Buffer.from("KYC_CONFIGURER_ROLE", "utf-8")
        ),
        MINTER_ROLE: keccak256(Buffer.from("MINTER_ROLE", "utf-8")),
        PAUSER_ROLE: keccak256(Buffer.from("PAUSER_ROLE", "utf-8")),
        decimals: 18,
        kycRegistry: KYC_REGISTRY_ADDRESS,
        kycRequirementGroup: 1,
        name: "Ondo Short-Term U.S. Government Bond Fund",
        paused: false,
        symbol: "OUSG",
      },
    },
    cashProxyRoleMembers: {
      defaultAdminRoleMembers: [CASH_MULTISIG],
      pauserRoleMembers: [CASH_MULTISIG],
      minterRoleMembers: [OUSG_CASH_MANAGER_ADDRESS],
    },
    cashProxyAdmin: {
      getProxyAdmin: OUSG_CASH_PROXY_ADMIN_ADDRESS,
      getProxyImplementation: OUSG_CASH_IMPL_ADDRESS,
      owner: CASH_MULTISIG,
    },
  },
  kycRegistry: {
    kycRegistryAddress: KYC_REGISTRY_ADDRESS,
    storage: {
      _APPROVAL_TYPEHASH: keccak256(
        Buffer.from(
          "KYCApproval(uint256 kycRequirementGroup,address user,uint256 deadline)",
          "utf-8"
        )
      ),
      DEFAULT_ADMIN_ROLE: ZERO_ROLE,
      REGISTRY_ADMIN: keccak256(Buffer.from("REGISTRY_ADMIN", "utf-8")),
      sanctionsList: "0x40C57923924B5c5c5455c48D93317139ADDaC8fb",
    },
    customRoleMembers: {
      [keccak256(Buffer.from("KYC_GROUP_1", "utf-8"))]: [CASH_MULTISIG],
    },
    roleMembers: {
      defaultAdminRoleMembers: [CASH_MULTISIG],
      registryAdminRoleMembers: [CASH_MULTISIG],
    },
  },
  governance: {
    governorBravoDelegatorAddress: GOVERNOR_DELEGATOR_ADDRESS,
    governorBravoDelegatorStorage: {
      admin: TIMELOCK_ADDRESS,
      implementation: GOVERNOR_DELEGATE_ADDRESS,
      pendingAdmin: ZERO_ADDRESS,
    },
    governorBravoDelegatorImplStorage: {
      MAX_PROPOSAL_THRESHOLD: parseUnits("1000000000", 18).toString(),
      MAX_VOTING_DELAY: 50400,
      MIN_PROPOSAL_THRESHOLD: parseUnits("1000000", 18).toString(),
      MIN_VOTING_DELAY: 1,
      MIN_VOTING_PERIOD: 5760,
      MAX_VOTING_PERIOD: 80640,
      admin: TIMELOCK_ADDRESS,
      comp: ONDO_TOKEN_ADDRESS,
      implementation: GOVERNOR_DELEGATE_ADDRESS,
      name: "Compound Governor Bravo",
      pendingAdmin: ZERO_ADDRESS,
      proposalMaxOperations: 10,
      proposalThreshold: PROPOSAL_THRESHOLD.toString(),
      quorumVotes: parseUnits("1000000", 18).toString(),
      timelock: TIMELOCK_ADDRESS,
      votingDelay: 1,
      votingPeriod: 21600,
      whitelistGuardian: ZERO_ADDRESS,
    },
    timelockAddress: TIMELOCK_ADDRESS,
    timelockStorage: {
      // 14 days.
      GRACE_PERIOD: 14 * 24 * 60 * 60,
      // 30 days
      MAXIMUM_DELAY: 30 * 24 * 60 * 60,
      // 1 day
      MINIMUM_DELAY: 1 * 24 * 60 * 60,
      admin: GOVERNOR_DELEGATOR_ADDRESS,
      delay: TIMELOCK_DELAY,
      pendingAdmin: ZERO_ADDRESS,
    },
  },
  flux: {
    // JumpRateModelV2
    // - Params:
    //        0, // baseRatePerYear
    //       '38000000000000000', // multiplierPerYear
    //       '1090000000000000000', // jumpMultiplierPerYear
    //       '800000000000000000', // kink
    jumpRateModelV2Address: INTEREST_RATE_MODEL_ADDRESS,
    jumpRateModelV2: {
      baseRatePerBlock: "0",
      // 3.83% borrow rate at the kink point of 90% utilization
      // (38300000000000000 * 1e18)/ (900000000000000000 * 2628000)
      multiplierPerBlock: "16193133773", //
      jumpMultiplierPerBlock: "133181126331",
      kink: "900000000000000000",
      blocksPerYear: EXPECTED_BLOCKS_PER_YEAR.toString(),
      owner: FLUX_GOVERNANCE_MULTISIG,
    },
    // Unitroller
    unitrollerAddress: UNITROLLER_ADDRESS,
    unitrollerStorage: {
      admin: FLUX_GOVERNANCE_MULTISIG,
      pendingAdmin: TIMELOCK_ADDRESS,
      // Still unlinked
      comptrollerImplementation: COMPTROLLER_ADDRESS,
      pendingComptrollerImplementation: ZERO_ADDRESS,
    },
    // This is an implementation contract so storage should be unused/uninitialized
    comptrollerAddress: COMPTROLLER_ADDRESS,
    comptrollerImplStorage: {
      admin: FLUX_GOVERNANCE_MULTISIG,
      oracle: ZERO_ADDRESS,
      closeFactorMantissa: "0",
      liquidationIncentiveMantissa: "0",
      maxAssets: "0",
      pauseGuardian: ZERO_ADDRESS,
      _mintGuardianPaused: false,
      _borrowGuardianPaused: false,
      transferGuardianPaused: false,
      seizeGuardianPaused: false,
      compRate: 0,
      borrowCapGuardian: ZERO_ADDRESS,
    },
    // This is storage that is delegated from the unitroller
    // To the comptroller
    comptrollerProxiedStorage: {
      oracle: ORACLE_ADDRESS,
      closeFactorMantissa: parseUnits("0.5", 18).toString(),
      liquidationIncentiveMantissa: parseUnits("1.05", 18).toString(),
      maxAssets: 0,
      pauseGuardian: FLUX_GOVERNANCE_MULTISIG,
      _mintGuardianPaused: false,
      _borrowGuardianPaused: false,
      transferGuardianPaused: false,
      seizeGuardianPaused: false,
      compRate: 0,
      borrowCapGuardian: ZERO_ADDRESS,
      proposal65FixExecuted: false,
    },
    comptrollerProxiedMarkets: {
      markets: [
        //    {
        //     Example format
        //     address: "",
        //     borrowCap: 0,
        //     mintGuardianPaused: false,
        //     borrowGuardianPaused: true,
        //     compSpeeds: 0, // Deprecated
        //     compBorrowSpeeds: 0,
        //     compSupplySpeeds: 0,
        //     // TODO should we activate rewards.
        //     // compSupplyState:
        //     // compBorrowState:
        //     // compSupplierIndex:
        //     // compBorrowerIndex:
        //     // compContributorSpeeds:
        //     // lastContributorBlock:
        //    }
        {
          address: fOUSG_PROXY_ADDRESS,
          borrowCap: 0,
          mintGuardianPaused: false,
          borrowGuardianPaused: true,
          compSpeeds: 0, // Deprecated
          compBorrowSpeeds: 0,
          compSupplySpeeds: 0,
          collateralFactor: parseUnits("0.92", 18).toString(),
        },
        {
          address: fUSDC_PROXY_ADDRESS,
          borrowCap: 0,
          mintGuardianPaused: false,
          borrowGuardianPaused: false,
          compSpeeds: 0, // Deprecated
          compBorrowSpeeds: 0,
          compSupplySpeeds: 0,
          collateralFactor: parseUnits("0.85", 18).toString(),
        },
        {
          address: fDAI_PROXY_ADDRESS,
          borrowCap: 0,
          mintGuardianPaused: false,
          borrowGuardianPaused: false,
          compSpeeds: 0, // Deprecated
          compBorrowSpeeds: 0,
          compSupplySpeeds: 0,
          collateralFactor: parseUnits("0.83", 18).toString(),
        },
      ],
    },

    // fUSDC
    fUSDC_PROXY_ADDRESS: fUSDC_PROXY_ADDRESS,
    fUSDCProxyStorage: {
      admin: TIMELOCK_ADDRESS,
      implementation: fUSDC_IMPLEMENTATION_ADDRESS,
      name: "Flux USDC",
      symbol: "fUSDC",
      decimals: "8",
      pendingAdmin: ZERO_ADDRESS,
      comptroller: UNITROLLER_ADDRESS,
      interestRateModel: INTEREST_RATE_MODEL_ADDRESS,
      reserveFactorMantissa: "0",
      // accrualBlockNumber: "",
      // borrowIndex: "",
      totalBorrows: "0",
      totalReserves: "0",
      totalSupply: "0",
      protocolSeizeShareMantissa: parseUnits("1.75", 16).toString(),
      exchangeRateStored: parseUnits("2", 14).toString(),
      isCToken: true,
      underlying: USDC_ADDRESS,
      sanctionsList: SANCTIONS_ORACLE_ADDRESS,
      kycRegistry: KYC_REGISTRY_ADDRESS,
      kycRequirementGroup: 1,
    },
    fUSDC_IMPLEMENTATION_ADDRESS: fUSDC_IMPLEMENTATION_ADDRESS,
    fUSDCImplementationStorage: {
      admin: ZERO_ADDRESS,
      name: "",
      symbol: "",
      decimals: "",
      pendingAdmin: ZERO_ADDRESS,
      comptroller: ZERO_ADDRESS,
      interestRateModel: ZERO_ADDRESS,
      reserveFactorMantissa: "0",
      accrualBlockNumber: "0",
      borrowIndex: "0",
      totalBorrows: "0",
      totalReserves: "0",
      totalSupply: "0",
      protocolSeizeShareMantissa: parseUnits("1.75", 16).toString(),
      exchangeRateStored: "0",
      isCToken: true,
      underlying: ZERO_ADDRESS,
      sanctionsList: SANCTIONS_ORACLE_ADDRESS,
      kycRegistry: ZERO_ADDRESS,
      kycRequirementGroup: 0,
    },

    // fDAI
    fDAI_PROXY_ADDRESS: fDAI_PROXY_ADDRESS,
    fDAIProxyStorage: {
      admin: TIMELOCK_ADDRESS,
      implementation: fDAI_IMPLEMENTATION_ADDRESS,
      name: "Flux DAI",
      symbol: "fDAI",
      decimals: "8",
      pendingAdmin: ZERO_ADDRESS,
      comptroller: UNITROLLER_ADDRESS,
      interestRateModel: INTEREST_RATE_MODEL_ADDRESS,
      reserveFactorMantissa: "0",
      // accrualBlockNumber: "",
      // borrowIndex: "",
      totalBorrows: "0",
      totalReserves: "0",
      totalSupply: "0",
      protocolSeizeShareMantissa: parseUnits("1.75", 16).toString(),
      exchangeRateStored: parseUnits("2", 26).toString(),
      isCToken: true,
      underlying: DAI_ADDRESS,
      sanctionsList: SANCTIONS_ORACLE_ADDRESS,
      kycRegistry: KYC_REGISTRY_ADDRESS,
      kycRequirementGroup: 1,
    },
    fDAI_IMPLEMENTATION_ADDRESS: fDAI_IMPLEMENTATION_ADDRESS,
    fDAIImplementationStorage: {
      admin: ZERO_ADDRESS,
      name: "",
      symbol: "",
      decimals: "",
      pendingAdmin: ZERO_ADDRESS,
      comptroller: ZERO_ADDRESS,
      interestRateModel: ZERO_ADDRESS,
      reserveFactorMantissa: "0",
      accrualBlockNumber: "0",
      borrowIndex: "0",
      totalBorrows: "0",
      totalReserves: "0",
      totalSupply: "0",
      protocolSeizeShareMantissa: parseUnits("1.75", 16).toString(),
      exchangeRateStored: "0",
      isCToken: true,
      underlying: ZERO_ADDRESS,
      sanctionsList: SANCTIONS_ORACLE_ADDRESS,
      kycRegistry: ZERO_ADDRESS,
      kycRequirementGroup: 0,
    },

    // fOUSG
    fOUSG_PROXY_ADDRESS: fOUSG_PROXY_ADDRESS,
    fOUSGProxyStorage: {
      admin: TIMELOCK_ADDRESS,
      implementation: fOUSG_IMPLEMENTATION_ADDRESS,
      name: "Flux OUSG",
      symbol: "fOUSG",
      decimals: "8",
      pendingAdmin: ZERO_ADDRESS,
      comptroller: UNITROLLER_ADDRESS,
      interestRateModel: INTEREST_RATE_MODEL_ADDRESS,
      reserveFactorMantissa: "0",
      // accrualBlockNumber: "",
      // borrowIndex: "",
      totalBorrows: "0",
      totalReserves: "0",
      totalSupply: "0",
      protocolSeizeShareMantissa: "0",
      exchangeRateStored: parseUnits("2", 26).toString(),
      isCToken: true,
      underlying: OUSG_CASH_PROXY_ADDRESS,
      sanctionsList: SANCTIONS_ORACLE_ADDRESS,
      kycRegistry: KYC_REGISTRY_ADDRESS,
      kycRequirementGroup: 1,
    },
    fOUSG_IMPLEMENTATION_ADDRESS: fOUSG_IMPLEMENTATION_ADDRESS,
    fOUSGImplementationStorage: {
      admin: ZERO_ADDRESS,
      name: "",
      symbol: "",
      decimals: "",
      pendingAdmin: ZERO_ADDRESS,
      comptroller: ZERO_ADDRESS,
      interestRateModel: ZERO_ADDRESS,
      reserveFactorMantissa: "0",
      accrualBlockNumber: "0",
      borrowIndex: "0",
      totalBorrows: "0",
      totalReserves: "0",
      totalSupply: "0",
      protocolSeizeShareMantissa: "0",
      exchangeRateStored: "0",
      isCToken: true,
      underlying: ZERO_ADDRESS,
      sanctionsList: SANCTIONS_ORACLE_ADDRESS,
      kycRegistry: ZERO_ADDRESS,
      kycRequirementGroup: 0,
    },
  },
};
export default config;
