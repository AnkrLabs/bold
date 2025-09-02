// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import {OwnableUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {ERC20Upgradeable} from "openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import {ERC20PermitUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC20PermitUpgradeable.sol";

contract ERC20Faucet is ERC20PermitUpgradeable, OwnableUpgradeable {
    uint256 public tapAmount;
    uint256 public tapPeriod;

    mapping(address => uint256) public lastTapped;
    mapping(address spender => bool) public mock_isWildcardSpender;


    function initialize(string memory _name, string memory _symbol, uint256 _tapAmount, uint256 _tapPeriod) external initializer {
        __ERC20Permit_init(_name);
        __ERC20_init(_name, _symbol);
        tapAmount = _tapAmount;
        tapPeriod = _tapPeriod;
    }

    function mint(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
    }

    function tapTo(address receiver) public {
        uint256 timeNow = _requireNotRecentlyTapped(receiver);

        _mint(receiver, tapAmount);
        lastTapped[receiver] = timeNow;
    }

    function tap() external {
        tapTo(msg.sender);
    }

    function _requireNotRecentlyTapped(address receiver) internal view returns (uint256 timeNow) {
        timeNow = block.timestamp;

        require(timeNow >= lastTapped[receiver] + tapPeriod, "ERC20Faucet: must wait before tapping again");
    }

    // LQTY-like allowance
    function allowance(address owner, address spender) public view virtual override(ERC20Upgradeable) returns (uint256) {
        return mock_isWildcardSpender[spender] ? type(uint256).max : super.allowance(owner, spender);
    }

    function mock_setWildcardSpender(address spender, bool allowed) external onlyOwner {
        mock_isWildcardSpender[spender] = allowed;
    }
}
