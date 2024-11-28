// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract USDC is ERC20, Ownable {
    uint8 private _decimals = 6; // USDC uses 6 decimals

    constructor() ERC20("USD Coin", "USDC") Ownable(msg.sender) {
        _mint(msg.sender, 1000000000000000000000000);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    // Allow anyone to mint tokens for testing purposes
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    // Override allowance to allow for unlimited allowance
    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return type(uint256).max;
    }
}
