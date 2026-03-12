// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./CreditToken.sol";
import "../lib/openzeppelin-contracts-master/contracts/utils/ReentrancyGuard.sol";

error ZeroAmount();
error ExceedsBorrowLimit(uint256 requested, uint256 max);
error InsufficientCollateral(uint256 requestedWithdraw, uint256 avaliable);
error RepayTooLarge(uint256 repay, uint256 debt);
error SendFailed();


contract CreditVault is ReentrancyGuard {


    CreditToken public immutable credit;

    mapping(address => uint256) public collateral;
    mapping(address => uint256) public debt;

    uint8 public constant MAX_LTV_PERCENT = 50; // max borrow = 50% of collateral (loan to value)

    event Deposit(address indexed user, uint256 amount);
    event Mint(address indexed user, uint256 amount);
    event Repay(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    constructor() {
        credit = new CreditToken(address(this));
    }

    // receive ETH
    receive() external payable {
        deposit();
    }

    function deposit() public payable {
        if (msg.value == 0) revert ZeroAmount();
        collateral[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function mint(uint256 amount) external {
        if (amount == 0) revert ZeroAmount();

        uint256 _coll = collateral[msg.sender];
        uint256 _allowable = (_coll * MAX_LTV_PERCENT) / 100;
        uint256 newDebt = debt[msg.sender] + amount;

        if (newDebt > _allowable) revert ExceedsBorrowLimit(amount, _allowable - debt[msg.sender]);

        debt[msg.sender] = newDebt;

        // mint Bond to borrower (allowed)
        credit.mint(msg.sender, amount);
        emit Mint(msg.sender, amount);
    }


    function repay(uint256 amount) external nonReentrant {
        if (amount == 0) revert ZeroAmount();

        uint256 userDebt = debt[msg.sender];
        if (amount > userDebt) revert RepayTooLarge(amount, userDebt);

        // pull tokens from user
        bool ok = credit.transferFrom(msg.sender, address(this), amount);
        if (!ok) revert SendFailed();

        debt[msg.sender] = userDebt - amount;

        // burn from vault balance
        credit.burn(address(this), amount);

        emit Repay(msg.sender, amount);
    }


    function withdraw(uint256 amount) external nonReentrant {
        if (amount == 0) revert ZeroAmount();
        
        uint256 userColl = collateral[msg.sender];
        if(amount > userColl) revert InsufficientCollateral(amount, userColl);

        uint256 newColl = userColl - amount;
        if (debt[msg.sender] > 0 && newColl * MAX_LTV_PERCENT < debt[msg.sender] * 100) {
            revert InsufficientCollateral(amount, userColl - ((debt[msg.sender] * 100 / MAX_LTV_PERCENT)));
        }  

        collateral[msg.sender] = newColl;

        // send Eth (or corressponding tokens)
        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        if (!sent) revert SendFailed();

        emit Withdraw(msg.sender, amount);
    }

}