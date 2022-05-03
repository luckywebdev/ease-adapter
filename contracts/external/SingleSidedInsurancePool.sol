// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

interface ISingleSidedInsurancePool {
    struct PoolInfo {
        uint128 lastRewardBlock;
        uint128 accUnoPerShare;
        uint256 unoMultiplierPerBlock;
    }

    struct UserInfo {
        uint256 lastWithdrawTime;
        uint256 rewardDebt;
        uint256 amount;
    }

    function userInfo(address _user) external view returns (UserInfo memory);

    function updatePool() external;

    function enterInPool(uint256 _amount) external payable;

    function leaveFromPoolInPending(uint256 _amount) external;

    function leaveFromPending() external;

    function harvest(address _to) external;

    function lpTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) external;

    function riskPool() external view returns (address);

    function getStakedAmountPerUser(address _to) external view returns (uint256 unoAmount, uint256 lpAmount);
}
