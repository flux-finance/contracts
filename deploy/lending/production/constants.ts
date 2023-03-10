import { keccak256 } from "ethers/lib/utils";

export const GUARDIAN_MULTISIG_ADDRESS =
  "0xAEd4caF2E535D964165B4392342F71bac77e8367";
export const FLUX_GOVERNANCE_MULTISIG =
  "0x118919e891D0205A7492650AD32E727617FA9452";
export const FLUX_TEAM_MULTISIG = "0xD2e6E930E25456fFcD4Df0124563cC334F3284f4";
export const CASH_ADDRESS = "0x1B19C19393e2d034D8Ff31ff34c81252FcBbee92";
export const KYC_REGISTRY_ADDRESS =
  "0x7cE91291846502D50D635163135B2d40a602dc70";
export const KYC_REQUIREMENT_GROUP = "1";

// Governance
export const DAO_ADDRESS = "0x336505EC1BcC1A020EeDe459f57581725D23465A";
export const TIMELOCK_ADDRESS = "0x2c5898da4DF1d45EAb2B7B192a361C3b9EB18d9c";
export const BURN_ADDRESS = "0x000000000000000000000000000000000000dEaD";

// Roles
export const MINTER_ROLE = keccak256(Buffer.from("MINTER_ROLE", "utf-8"));

// Token Addresses
export const DAI_ADDRESS = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
export const USDC_ADDRESS = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
export const USDT_ADDRESS = "0xdAC17F958D2ee523a2206206994597C13D831ec7";
export const FRAX_ADDRESS = "0x853d955aCEf822Db058eb8505911ED77F175b99e";
export const LUSD_ADDRESS = "0x5f98805A4E8be255a32880FDeC7F6728C6568bA0";
export const ONDO_TOKEN_ADDRESS = "0xfAbA6f8e4a5E8Ab82F62fe7C39859FA577269BE3";
export const COMPOUNDS_CDAI_ADDRESS =
  "0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643";
export const COMPOUNDS_CUSDC_ADDRESS =
  "0x39AA39c021dfbaE8faC545936693aC917d5E7563";
