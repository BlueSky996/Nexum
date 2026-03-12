// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./CreditToken.sol";

contract CreditVault {

    CreditToken public credit;

    mapping(address => uint256) public collateral;
    mapping(address => uint256) public debt;

    constructor() {
        credit = new CreditToken();
    }

    function deposit() external payable {
        collateral[msg.sender] += msg.value;
    }

    function mint(uint256 amount) external {
        require(amount <= collateral[msg.sender] / 2 - debt[msg.sender], "Exceeds borrow limit");
        debt[msg.sender] += amount;
        credit.mint(msg.sender, amount);
    }

    function repay(uint256 amount) external {
        credit.transferFrom(msg.sender, address(this), amount);
        debt[msg.sender] -= amount;
        credit.burn(address(this), amount);
    }

    function withdraw(uint256 amount) external {
        require(collateral[msg.sender] - amount >= debt[msg.sender] * 2, "Would break collateral ratio");
        
        collateral[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

}