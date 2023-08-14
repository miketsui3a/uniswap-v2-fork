### Deploy

calculate deploy hash for uniswapv2pair and put it into UniswapV2Library.sol
keccak256(type(UniswapV2Pair).creationCode);

npx hardhat deploy -- network <network>
