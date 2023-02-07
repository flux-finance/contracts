import { DeployFunction } from "hardhat-deploy/types";

const deployFunc: DeployFunction = async (hre) => {
  const { deployments, getNamedAccounts, network } = hre;
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  await deploy("GovernerAlpha", {
    from: deployer,
    args: [
      1, // proposalCount
    ],
    log: true,
  });
};

deployFunc.tags = ["Prod-GovernerAlpha"];

export default deployFunc;
