// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/openzeppelin-contracts-master/contracts/token/ERC20/ERC20.sol";

error OnlyVault();

contract CreditToken is ERC20 {

    // Address that is allowed to mint and burn tokens
    address public immutable vault;

    constructor(address vault_) ERC20("Bond Token", "BND") {
        vault = vault_;
    }

    function mint(address to, uint256 amount) external {
        if (msg.sender != vault) revert OnlyVault();
        // Internal ERC20 function that creates new tokens
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        require(msg.sender == vault, "Only vault can burn tokens");
        // Internal ERC20 function that destroys tokens
        _burn(from, amount);
    }

    }
