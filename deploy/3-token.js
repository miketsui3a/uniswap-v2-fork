const { parseEther } = require("ethers/lib/utils");

module.exports = async ({
  getNamedAccounts,
  deployments: { deploy, getOrNull },
  ethers,
  network,
}) => {
  const { deployer } = await getNamedAccounts();
  let xbsDeploy = await getOrNull("XBS");
  console.log(xbsDeploy?.address);
  if (!xbsDeploy) {
    await deploy("XBS", {
      from: deployer,
      log: true,
      contract: "contracts/XBS.sol:XBS",
      args: [parseEther("10000000"), deployer],
    });
  } else {
    console.log(`XBS already deployed at ${xbsDeploy.address}`);
  }
};

module.exports.tags = ["XBS"];