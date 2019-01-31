pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/utils/ReentrancyGuard.sol";
import "./GovChecker.sol";


contract Staking is GovChecker, ReentrancyGuard {
    using SafeMath for uint256;

    mapping(address => uint256) private balance;
    mapping(address => uint256) private lockedBalance;
    uint256 private totalLockedBalance;
    
    event Staked(address indexed payee, uint256 amount, uint256 total, uint256 available);
    event Unstaked(address indexed payee, uint256 amount, uint256 total, uint256 available);
    event Locked(address indexed payee, uint256 amount, uint256 total, uint256 available);
    event Unlocked(address indexed payee, uint256 amount, uint256 total, uint256 available);

    constructor(address registry) public {
        totalLockedBalance = 0;
        setRegistry(registry);
    }

    function balanceOf(address payee) public view returns (uint256) {
        return balance[payee];
    }

    function lockedBalanceOf(address payee) public view returns (uint256) {
        return lockedBalance[payee];
    }

    function availableBalance(address payee) public view returns (uint256) {
        return balance[payee].sub(lockedBalance[payee]);
    }

    /**
    * @dev Calculate voting weight which range between 0 and 100.
    * @param payee The address whose funds were locked.
    */
    function calcVotingWeight(address payee) public view returns (uint256) {
        return calcVotingWeightWithScaleFactor(payee, 1e2);
    }

    /**
    * @dev Calculate voting weight with a scale factor.
    * @param payee The address whose funds were locked.
    * @param factor The scale factor for weight. For instance:
    *               if 1e1, result range is between 0 ~ 10
    *               if 1e2, result range is between 0 ~ 100
    *               if 1e3, result range is between 0 ~ 1000
    */
    function calcVotingWeightWithScaleFactor(address payee, uint32 factor) public view returns (uint256) {
        if (lockedBalance[payee] == 0 || factor == 0) return 0;
        return lockedBalance[payee].mul(factor).div(totalLockedBalance);
    }

    function () external payable {
        revert();
    }

    /**
    * @dev Deposit from a sender.
    */
    function deposit() external nonReentrant payable {
        require(msg.value > 0, "Deposit amount should be greater than zero");

        balance[msg.sender] = balance[msg.sender].add(msg.value);

        emit Staked(msg.sender, msg.value, balance[msg.sender], availableBalance(msg.sender));
    }

    /**
    * @dev Withdraw for a sender.
    * @param amount The amount of funds will be withdrawn and transferred to.
    */
    function withdraw(uint256 amount) external nonReentrant {
        require(amount <= availableBalance(msg.sender), "Withdraw amount should be equal or less than balance");

        balance[msg.sender] = balance[msg.sender].sub(amount);
        msg.sender.transfer(amount);

        emit Unstaked(msg.sender, amount, balance[msg.sender], availableBalance(msg.sender));
    }

    /**
    * @dev Lock fund
    * @param payee The address whose funds will be locked.
    * @param lockAmount The amount of funds will be locked.
    */
    function lock(address payee, uint256 lockAmount) external onlyGov {
        require(balance[payee] >= lockAmount, "Lock amount should be equal or less than balance");
        require(availableBalance(payee) >= lockAmount, "Insufficient balance that can be locked");

        lockedBalance[payee] = lockedBalance[payee].add(lockAmount);
        totalLockedBalance = totalLockedBalance.add(lockAmount);

        emit Locked(payee, lockAmount, balance[payee], availableBalance(payee));
    }

    /**
    * @dev Unlock fund
    * @param payee The address whose funds will be unlocked.
    * @param unlockAmount The amount of funds will be unlocked.
    */
    function unlock(address payee, uint256 unlockAmount) external onlyGov {
        require(lockedBalance[payee] >= unlockAmount, "Unlock amount should be equal or less than balance locked");

        lockedBalance[payee] = lockedBalance[payee].sub(unlockAmount);
        totalLockedBalance = totalLockedBalance.sub(unlockAmount);

        emit Unlocked(payee, unlockAmount, balance[payee], availableBalance(payee));
    }
}