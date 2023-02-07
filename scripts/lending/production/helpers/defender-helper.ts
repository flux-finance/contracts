require("dotenv").config();
import { AdminClient, CreateProposalRequest } from "defender-admin-client";
import { Network } from "defender-base-client";
import { BigNumber } from "ethers";

const getEnvVar = (value: string | undefined): string => {
  if (value === undefined) {
    throw new Error(value + " is undefined");
  }
  return value;
};
const getClient = async (): Promise<AdminClient> => {
  const apiKey: string = getEnvVar(process.env.ADMIN_API_KEY);
  const apiSecret: string = getEnvVar(process.env.ADMIN_API_SECRET);
  const client = new AdminClient({ apiKey: apiKey, apiSecret: apiSecret });
  return client;
};

export const addContract = async (
  network: Network,
  contract: Address,
  name: string,
  abi: string
) => {
  const client = await getClient();
  await client.addContract({
    network: network,
    address: contract,
    name: name,
    abi: abi,
  });
};

export const listContracts = async () => {
  const client = await getClient();
  const contracts = await client.listContracts();
  console.log(contracts);
};

export const deleteContract = async (name: string) => {
  const client = await getClient();
  await client.deleteContract(name);
};

export const proposeFunctionCall = async (
  request: ProposeFunctionCallRequest
) => {
  const client = await getClient();
  await client.createProposal({
    contract: request.contract,
    title: `${request.params.title}`,
    description: `${request.params.description}`,
    functionInterface: {
      name: request.functionName,
      inputs: request.functionInterface,
    },
    functionInputs: request.functionInputs,
    via: request.params.via,
    viaType: request.params.viaType,
    type: "custom",
  });
};

type Address = string;

export type BaseProposalRequestParams = {
  title?: string;
  description?: string;
  via: Address;
  viaType: CreateProposalRequest["viaType"];
};

export type ProposeFunctionCallRequest = {
  contract: CreateProposalRequest["contract"];
  params: BaseProposalRequestParams;
  functionName: string;
  functionInterface: any[];
  functionInputs: any[];
};
