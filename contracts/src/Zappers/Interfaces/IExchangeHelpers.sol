// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "openzeppelin-contracts-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";

interface IExchangeHelpers {
    function getCollFromBold(uint256 _boldAmount, IERC20Upgradeable _collToken, uint256 _desiredCollAmount)
        external /* view */
        returns (uint256, uint256);
}
