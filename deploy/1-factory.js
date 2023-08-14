module.exports = async ({
  getNamedAccounts,
  deployments: { deploy, getOrNull },
  ethers,
  network,
}) => {
  const { deployer } = await getNamedAccounts();
  let factoryDeploy = await getOrNull("UniswapV2Factory");
  console.log(factoryDeploy?.address);
  if (!factoryDeploy) {
    await deploy("UniswapV2Factory", {
      from: deployer,
      log: true,
      contract: "contracts/UniswapV2Factory.sol:UniswapV2Factory",
      args: [deployer],
    });
  } else {
    console.log(
      `UniswapV2Factory already deployed at ${factoryDeploy.address}`
    );
  }
};

module.exports.tags = ["uniswapV2Factory"];
