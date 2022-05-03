/// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.11;

import "../RcaShieldNormalized.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ISingleSidedInsurancePool } from "../../external/SingleSidedInsurancePool.sol";
import "hardhat/console.sol";

contract RcaShieldAres is RcaShieldNormalized {
    using SafeERC20 for IERC20Metadata;
    using SafeERC20 for IERC20;

    ISingleSidedInsurancePool public immutable SSIPContract;

    // Check our SSIPContract against this to call the correct functions.
    address private constant MCV1 = 0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd;

    constructor(
        string memory _name,
        string memory _symbol,
        address _uToken,
        uint256 _uTokenDecimals,
        address _governance,
        address _controller,
        ISingleSidedInsurancePool _SSIPContract
    ) RcaShieldNormalized(_name, _symbol, _uToken, _uTokenDecimals, _governance, _controller) {
        SSIPContract = _SSIPContract;
        console.log("[uToken 0]", address(this), address(_SSIPContract));
        console.log(
            "[uToken 1]",
            address(uToken),
            IERC20(address(uToken)).allowance(address(this), address(_SSIPContract))
        );
        IERC20(address(uToken)).approve(address(_SSIPContract), type(uint256).max);
        // TransferHelper.safeApprove(address(uToken), address(_SSIPContract), type(uint256).max);
    }

    function getReward() external {
        SSIPContract.harvest(address(this));
    }

    function purchase(
        address _token,
        uint256 _amount, // token amount to buy
        uint256 _tokenPrice,
        bytes32[] calldata _tokenPriceProof,
        uint256 _underlyingPrice,
        bytes32[] calldata _underlyinPriceProof
    ) external {
        console.log("[purchase contract]", _token, address(uToken));
        require(_token != address(uToken), "cannot buy underlying token");
        controller.verifyPrice(_token, _tokenPrice, _tokenPriceProof);
        controller.verifyPrice(address(uToken), _underlyingPrice, _underlyinPriceProof);
        uint256 underlyingAmount = (_amount * _tokenPrice) / _underlyingPrice;
        if (discount > 0) {
            underlyingAmount -= (underlyingAmount * discount) / DENOMINATOR;
        }

        IERC20Metadata token = IERC20Metadata(_token);
        // normalize token amount to transfer to the user so that it can handle different decimals
        _amount = (_amount * 10**token.decimals()) / BUFFER;

        token.safeTransfer(msg.sender, _amount);
        uToken.safeTransferFrom(msg.sender, address(this), _normalizedUAmount(underlyingAmount));

        SSIPContract.enterInPool(underlyingAmount);
    }

    function redeem() external {
        SSIPContract.leaveFromPending();
    }

    function _uBalance() internal view override returns (uint256) {
        (uint256 unoAmount, uint256 lpAmount) = SSIPContract.getStakedAmountPerUser(address(this));
        return ((uToken.balanceOf(address(this)) + unoAmount) * BUFFER) / BUFFER_UTOKEN;
    }

    function _afterMint(uint256 _uAmount) internal override {
        SSIPContract.enterInPool(_uAmount);
    }

    function _afterRedeem(uint256 _uAmount) internal override {
        SSIPContract.leaveFromPoolInPending(_uAmount);
    }
}
