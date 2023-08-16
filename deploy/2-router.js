const { deployments } = require("hardhat");
const constants = require("../constants/constants.js");

module.exports = async ({
  getNamedAccounts,
  deployments: { deploy, getOrNull },
  ethers,
  network,
}) => {
  const { deployer } = await getNamedAccounts();
  let routerDeploy = await getOrNull("UniswapV2Router02");
  console.log(routerDeploy?.address);
  const weth = constants[network.name]?.WETH;

  const factoryDeploy = await deployments.get("UniswapV2Factory");

  if (!routerDeploy) {
    await deploy("UniswapV2Router02", {
      from: deployer,
      log: true,
      contract: "contracts/UniswapV2Router02.sol:UniswapV2Router02",
      args: [
        factoryDeploy.address,
        "0x4200000000000000000000000000000000000006",
      ],
    });
  } else {
    console.log(
      `UniswapV2Router02 already deployed at ${routerDeploy.address}`
    );
  }
};

module.exports.tags = ["uniswapV2Router02"];
