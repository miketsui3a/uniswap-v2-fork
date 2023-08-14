pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DummyToken is ERC20("DUM", "DUM") {
    constructor() {
        _mint(msg.sender, 1000000000000000000);
    }
}
