const { expect } = require("chai");
const { parseEther, formatEther } = require("ethers/lib/utils");
const { deployments } = require("hardhat");
require("dotenv").config();

describe("Greeter", function () {
  it("Should return the new greeting once it's changed", async function () {
    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: ["0x13ee97D6C6236022600aFf83DCb7AB7fb64f6786"],
    });
    
    const signer = await hre.ethers.getSigner("0x13ee97D6C6236022600aFf83DCb7AB7fb64f6786");
    const UniswapV2Factory = await ethers.getContractFactory(
      "UniswapV2Factory"
    );
    const UniswapV2Router02 = await ethers.getContractFactory(
      "UniswapV2Router02"
    );

    const DummyToken = await ethers.getContractFactory("DummyToken");

    const uniswapV2Factory = await UniswapV2Factory.deploy(signer.address);
    await uniswapV2Factory.deployed();


    // const uniswapV2Router02 = await UniswapV2Router02.deploy(
    //   uniswapV2Factory.address,
    //   process.env.WETH || "0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
    // );
    // await uniswapV2Router02.deployed();

    const uniswapV2Router02Deploy = await deployments.get("UniswapV2Router02")
    console.log(uniswapV2Router02Deploy.address);

    const uniswapV2Router02 = await ethers.getContractAt(
      "UniswapV2Router02",
      uniswapV2Router02Deploy.address
    );

    console.log(uniswapV2Factory.address);

    // const dummyToken = await DummyToken.deploy();
    // await dummyToken.deployed();

    const wbnb = await await ethers.getContractAt(
      "XBS",
      "0x4200000000000000000000000000000000000006"
    );

    const xbs = await await ethers.getContractAt(
      "XBS",
      "0xC5e008934C078DDf5F5178C84E0B670FB9EeDB49"
    );
    // console.log("OK");

    // // await dummyToken2.deployed();
    // console.log("OK");
    
    // const dummyToken2 = await DummyToken.deploy();
    // await dummyToken2.deployed();
    // console.log("OK");

    await (
      await wbnb.approve(uniswapV2Router02Deploy.address, parseEther("100.0"))
    ).wait();

    await (
      await xbs.approve(uniswapV2Router02Deploy.address, parseEther("100.0"))
    ).wait();
    console.log("OK");
    await (
      await uniswapV2Router02.addLiquidity(
        wbnb.address,
        xbs.address,
        parseEther("0.01"),
        parseEther("0.01"),
        parseEther("0.01"),
        parseEther("0.01"),
        signer.address,
        "99999999999",
        {gasLimit: 8000000}
      )
    ).wait();
    console.log("OK");

    const pair = await uniswapV2Factory.getPair(
      dummyToken.address,
      dummyToken2.address
    );

    await (
      await uniswapV2Router02.swapExactTokensForTokens(
        parseEther("0.1"),
        parseEther("0"),
        [dummyToken.address, dummyToken2.address],
        signer.address,
        "99999999999"
      )
    ).wait();
    const token1Balance = await dummyToken.balanceOf(signer.address);
    const token2Balance = await dummyToken2.balanceOf(signer.address);
    console.log("after token1Balance", formatEther(token1Balance));
    console.log("after token2Balance", formatEther(token2Balance));
    console.log("swap OK");

    const abi = ["function approve(address, uint256) returns (bool)"];

    const lp = new ethers.Contract(pair, abi, signer);
    await (
      await lp.approve(uniswapV2Router02.address, parseEther("1000.0"))
    ).wait();
    await (
      await uniswapV2Router02.removeLiquidity(
        dummyToken.address,
        dummyToken2.address,
        parseEther("0.000000001"),
        parseEther("0.0"),
        parseEther("0.0"),
        signer.address,
        "99999999999"
      )
    ).wait();
  });
});
