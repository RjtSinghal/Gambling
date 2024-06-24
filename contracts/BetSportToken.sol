// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract BetSportToken is ERC20, ERC20Permit {
    constructor() ERC20("BetSportToken", "BST") ERC20Permit("BetSportToken") {
        _mint(msg.sender, 100000 * 10 ** decimals());
    }
}
