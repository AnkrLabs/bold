// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.24;

import "openzeppelin-contracts-upgradeable/contracts/access/Ownable2StepUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./Interfaces/IAddressesRegistry.sol";
import "./Interfaces/ICollateralVault.sol";

contract CollateralVault is Ownable2StepUpgradeable, ICollateralVault {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IERC20Upgradeable collToken;
    // debt is negative when owner has returned more than withdrawed before
    int256 public ownerDebt;

    function initialize(
        address _owner,
        IAddressesRegistry _addressesRegistry
    ) external initializer {
        __Ownable2Step_init();
        _transferOwnership(_owner);

        collToken = _addressesRegistry.collToken();

        // Allow funds movements between Liquity contracts
        address activePool = address(_addressesRegistry.activePool());
        collToken.approve(activePool, type(uint256).max);
        address borrowerOps = address(_addressesRegistry.borrowerOperations());
        collToken.approve(borrowerOps, type(uint256).max);
        address defaultPool = address(_addressesRegistry.defaultPool());
        collToken.approve(defaultPool, type(uint256).max);
    }

    // only owner can withdraw
    function withdraw(uint256 amount) external onlyOwner {
        _requireBalanceIsEnough(amount);
        ownerDebt += int256(amount);
        collToken.approve(owner(), amount);
        collToken.safeTransfer(owner(),  amount);
    }

    // anyone can top up
    function topUp(uint256 amount) external {
        ownerDebt -= int256(amount);
        collToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    function _requireBalanceIsEnough(uint256 amount) internal view {
        require(amount <= collToken.balanceOf(address(this)), "CollateralVault: Too big withdraw");
    }
}