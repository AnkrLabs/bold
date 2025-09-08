// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IParameters {

    // --- Data ---
    struct CompensationParams {
        uint256 ETH_GAS_COMPENSATION;
        uint256 COLL_GAS_COMPENSATION_DIVISOR;
        uint256 COLL_GAS_COMPENSATION_CAP;
    }
    struct LiquidationParams {
        uint256 MIN_LIQUIDATION_PENALTY_SP;
        uint256 MAX_LIQUIDATION_PENALTY_REDISTRIBUTION;
    }
    struct MinParams {
        uint256 MIN_DEBT;
        uint256 MIN_BOLD_IN_SP;
    }
    struct InterestParams {
        uint256 MIN_ANNUAL_INTEREST_RATE;
        uint256 MAX_ANNUAL_INTEREST_RATE;
        uint128 MAX_ANNUAL_BATCH_MANAGEMENT_FEE;
        uint128 MIN_INTEREST_RATE_CHANGE_PERIOD;
        uint256 INTEREST_RATE_ADJ_COOLDOWN;
        uint256 UPFRONT_INTEREST_PERIOD;
    }
    struct RedemptionParams {
        uint256 REDEMPTION_FEE_FLOOR;
        uint256 REDEMPTION_MINUTE_DECAY_FACTOR;
        uint256 REDEMPTION_BETA;
        uint256 URGENT_REDEMPTION_BONUS;
        uint256 MAX_BATCH_SHARES_RATIO;
    }
    struct BranchParams {
        address collToken;
        uint256 CCR;
        uint256 MCR;
        uint256 SCR;
        uint256 BCR;
        uint256 LIQUIDATION_PENALTY_SP;
        uint256 LIQUIDATION_PENALTY_REDISTRIBUTION;
    }

    // --- Functions ---
    function setGlobalsToDefault() external;

    // --- Views ---
    function ETH_GAS_COMPENSATION() external view returns (uint256);
    function COLL_GAS_COMPENSATION_DIVISOR() external view returns (uint256);
    function COLL_GAS_COMPENSATION_CAP() external view returns (uint256);
    function MIN_LIQUIDATION_PENALTY_SP() external view returns (uint256);
    function MAX_LIQUIDATION_PENALTY_REDISTRIBUTION() external view returns (uint256);
    function MIN_DEBT() external view returns (uint256);
    function MIN_BOLD_IN_SP() external view returns (uint256);
    function MIN_ANNUAL_INTEREST_RATE() external view returns (uint256);
    function MAX_ANNUAL_INTEREST_RATE() external view returns (uint256);
    function MAX_ANNUAL_BATCH_MANAGEMENT_FEE() external view returns (uint128);
    function MIN_INTEREST_RATE_CHANGE_PERIOD() external view returns (uint128);
    function INTEREST_RATE_ADJ_COOLDOWN() external view returns (uint256);
    function UPFRONT_INTEREST_PERIOD() external view returns (uint256);
    function REDEMPTION_FEE_FLOOR() external view returns (uint256);
    function REDEMPTION_MINUTE_DECAY_FACTOR() external view returns (uint256);
    function REDEMPTION_BETA() external view returns (uint256);
    function URGENT_REDEMPTION_BONUS() external view returns (uint256);
    function MAX_BATCH_SHARES_RATIO() external view returns (uint256);
    function SP_YIELD_SPLIT() external view returns (uint256);

    function CCR(address) external view returns(uint256);
    function MCR(address) external view returns(uint256);
    function SCR(address) external view returns(uint256);
    function BCR(address) external view returns(uint256);
    function LIQUIDATION_PENALTY_SP(address) external view returns(uint256);
    function LIQUIDATION_PENALTY_REDISTRIBUTION(address) external view returns(uint256);

    function getBranchParams(address _collToken) external view returns (BranchParams memory _params);
}
