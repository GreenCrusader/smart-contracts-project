// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract VestingWallet is Ownable, ReentrancyGuard {

    struct VestingSchedule {
        address beneficiary;
        uint256 cliff;
        uint256 duration;
        uint256 totalAmount;
        uint256 releasedAmount;
    }

    IERC20 public immutable token;
    mapping(address => VestingSchedule) public vestingSchedules;

    constructor(address tokenAddress) Ownable(msg.sender) {
        token = IERC20(tokenAddress);
    }

    function createVestingSchedule(address _beneficiary, uint256 _totalAmount, uint256 _cliff, uint256 _duration) public onlyOwner {
        uint256 balanceBefore = token.balanceOf(address(this));
        bool ok = token.transferFrom(msg.sender, address(this), _totalAmount);
        require(ok, "Transfer failed"); // error on transfer not returning true
        uint256 balanceAfter = token.balanceOf(address(this));
        require(balanceAfter - balanceBefore == _totalAmount, "Incorrect amount received"); // error if balance amount incorrect after transaction

        vestingSchedules[_beneficiary] = VestingSchedule({
            beneficiary: _beneficiary,
            cliff: _cliff,
            duration: _duration,
            totalAmount: _totalAmount,
            releasedAmount: 0
        });
    }

    function claimVestedTokens() public nonReentrant {
        VestingSchedule storage schedule = vestingSchedules[msg.sender];

        uint256 vested = _vestedAmount(schedule, block.timestamp);
        uint256 releasable = vested - schedule.releasedAmount;
        require(releasable > 0, "Nothing to claim"); // here nothing owed

        schedule.releasedAmount += releasable;
        bool ok = token.transfer(msg.sender, releasable);
        require(ok, "Transfer failed");
    }

    function getVestedAmount(address _beneficiary) public view returns (uint256) {
        if (vestingSchedules[_beneficiary].beneficiary == address(0)) {
            return 0; // here nothing owed
        }
        return _vestedAmount(vestingSchedules[_beneficiary], block.timestamp);

        // Attention : la libération est linéaire après le cliff.
    }

    function _vestedAmount(VestingSchedule storage schedule, uint256 currentTime) internal view returns (uint256) {
        if (currentTime < schedule.cliff) { return 0; } // nothing owed (yet)
        uint256 timeSinceCliff = currentTime - schedule.cliff;
        if (timeSinceCliff >= schedule.duration) {
            return schedule.totalAmount; // everything owed
        }
        return (schedule.totalAmount * timeSinceCliff) / schedule.duration; // partially owed
    }

}