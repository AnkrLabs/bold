// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

interface IWETH is IERC20MetadataUpgradeable {
    function deposit() external payable;
    function withdraw(uint256 wad) external;
}
