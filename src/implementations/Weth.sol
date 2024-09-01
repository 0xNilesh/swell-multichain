// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Weth is ERC20, Ownable {
    constructor()
        ERC20("Weth", "weth")
        Ownable()
    {
        _mint(msg.sender, 100_000_000 ether);
    }
}