const { parseEther } = require("ethers/lib/utils");

module.exports = async ({
  getNamedAccounts,
  deployments: { deploy, getOrNull },
  ethers,
  network,
}) => {
  const { deployer } = await getNamedAccounts();
  let multicallDeploy = await getOrNull("Multicall");
  if (!multicallDeploy) {
    await deploy("Multicall", {
      from: deployer,
      log: true,
      contract: "contracts/Multicall.sol:Multicall",
      args: [],
    });
  } else {
    console.log(`Multicall already deployed at ${multicallDeploy.address}`);
  }
};

module.exports.tags = ["Multicall"];