// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.24;

address constant ZERO_ADDRESS = address(0);

uint256 constant MAX_UINT256 = type(uint256).max;

uint256 constant DECIMAL_PRECISION = 1e18;
uint256 constant _100pct = DECIMAL_PRECISION;
uint256 constant _1pct = DECIMAL_PRECISION / 100;

uint256 constant INITIAL_BASE_RATE = _100pct;

uint256 constant ONE_MINUTE = 1 minutes;
uint256 constant ONE_YEAR = 365 days;

// Dummy contract that lets legacy Hardhat tests query some of the constants
interface IP {
    function ETH_GAS_COMPENSATION() external view returns (uint256);
    function MIN_DEBT() external view returns (uint256);
}
contract Constants {
    uint256 public _ETH_GAS_COMPENSATION;
    uint256 public _MIN_DEBT;

    constructor(IP _parameters) {
        _ETH_GAS_COMPENSATION = _parameters.ETH_GAS_COMPENSATION();
        _MIN_DEBT = _parameters.MIN_DEBT();
    }
}
