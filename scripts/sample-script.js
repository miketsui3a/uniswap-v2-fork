// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
require('dotenv').config()

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');`

  // We get the contract to deploy

  const signer = await hre.ethers.getSigner();

  const UniswapV2Factory = await hre.ethers.getContractFactory(
    "UniswapV2Factory"
  );
  const uniswapV2Factory = await UniswapV2Factory.deploy(signer.address);

  await uniswapV2Factory.deployed();

  const UniswapV2Router02 = await ethers.getContractFactory(
    "UniswapV2Router02"
  );
  const uniswapV2Router02 = await UniswapV2Router02.deploy(
    uniswapV2Factory.address,
    process.env.WETH
  );
  await uniswapV2Router02.deployed();

  console.log("UniswapV2Factory deployed to:", uniswapV2Factory.address);
  console.log("UniswapV2Router02 deployed to:", uniswapV2Router02.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
