// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const { deployments, ethers } = require("hardhat");
require("dotenv").config();
const pools = require("../constants/pools");

async function main() {
  const masterChefDeploy = await deployments.get("MasterChef");
  const masterchef = await ethers.getContractAt(
    "MasterChef",
    masterChefDeploy.address
  );
  await masterchef.add(
    pools[0].allocPoint,
    "0x8437fB41FF22E6EF5e14a3712011bbc5a584a2f3",
    pools[0].depositFeeBP,
    false,
    {
      gasLimit: 1000000,
    }
  );
  //   pools.forEach(async (pool) => {
  //     await masterchef.add(
  //       pool.allocPoint,
  //       pool.lpTokenAddr,
  //       pool.depositFeeBP,
  //       pool.withUpdate
  //     );
  //   });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
