const { parseEther } = require("ethers/lib/utils");

module.exports = async ({
  getNamedAccounts,
  deployments: { deploy, getOrNull },
  ethers,
  network,
}) => {
  const { deployer } = await getNamedAccounts();
  let xbaseDeploy = await getOrNull("Xbase");
  console.log(xbaseDeploy?.address);
  if (!xbaseDeploy) {
    await deploy("Xbase", {
      from: deployer,
      log: true,
      contract: "contracts/Xbase.sol:Xbase",
      args: [parseEther("10000000"), deployer],
    });
  } else {
    console.log(`Xbase already deployed at ${xbaseDeploy.address}`);
  }
};

module.exports.tags = ["Xbase"];
