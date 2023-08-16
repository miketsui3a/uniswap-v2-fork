const { parseEther } = require("ethers/lib/utils");

module.exports = async ({
  getNamedAccounts,
  deployments: { deploy, getOrNull },
  ethers,
  network,
}) => {
  const { deployer } = await getNamedAccounts();
  let xbnbDeploy = await getOrNull("XBNB");
  console.log(xbnbDeploy?.address);
  if (!xbnbDeploy) {
    await deploy("XBNB", {
      from: deployer,
      log: true,
      contract: "contracts/XBNB.sol:XBNB",
      args: [parseEther("10000000"), deployer],
    });
  } else {
    console.log(`XBNB already deployed at ${xbnbDeploy.address}`);
  }
};

module.exports.tags = ["XBNB"];