const { parseEther } = require("ethers/lib/utils");
const { deployments } = require("hardhat");

module.exports = async ({
  getNamedAccounts,
  deployments: { deploy, getOrNull },
  ethers,
  network,
}) => {
  const { deployer } = await getNamedAccounts();
  let masterChefDeploy = await getOrNull("MasterChef");
  let xbsDeploy = await deployments.get("XBS");
  const xbsPerBlock = "10.0";
  const startBlock = 9999999999;
  if (!masterChefDeploy) {
    await deploy("MasterChef", {
      from: deployer,
      log: true,
      contract: "contracts/MasterChef.sol:MasterChef",
      args: [
        xbsDeploy.address,
        deployer,
        deployer,
        parseEther(xbsPerBlock),
        startBlock,
      ],
    });
  } else {
    console.log(`MasterChef already deployed at ${masterChefDeploy.address}`);
  }
};

module.exports.tags = ["MasterChef"];