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
  let xbaseDeploy = await deployments.get("Xbase");
  console.log(masterChefDeploy?.address);
  const xbasePerBlock = "10.0";
  const startBlock = 9999999999;
  if (!masterChefDeploy) {
    await deploy("MasterChef", {
      from: deployer,
      log: true,
      contract: "contracts/MasterChef.sol:MasterChef",
      args: [
        xbaseDeploy.address,
        deployer,
        deployer,
        parseEther(xbasePerBlock),
        startBlock,
      ],
    });
  } else {
    console.log(`MasterChef already deployed at ${masterChefDeploy.address}`);
  }
};

module.exports.tags = ["MasterChef"];
