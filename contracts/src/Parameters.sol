// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.24;

import "openzeppelin-contracts-upgradeable/contracts/access/Ownable2StepUpgradeable.sol";

import "./interfaces/IParameters.sol";
import "./Dependencies/Constants.sol";

// For comments please refer to (https://github.com/liquity/bold/blob/main/contracts/src/Dependencies/Constants.sol)
contract Parameters is IParameters, Ownable2StepUpgradeable {

    // --- Data ---
    // Global
    uint256 public ETH_GAS_COMPENSATION;
    uint256 public COLL_GAS_COMPENSATION_DIVISOR;
    uint256 public COLL_GAS_COMPENSATION_CAP;

    uint256 public MIN_LIQUIDATION_PENALTY_SP;
    uint256 public MAX_LIQUIDATION_PENALTY_REDISTRIBUTION;

    uint256 public MIN_DEBT;
    uint256 public MIN_BOLD_IN_SP;

    uint256 public MIN_ANNUAL_INTEREST_RATE;
    uint256 public MAX_ANNUAL_INTEREST_RATE;
    uint128 public MAX_ANNUAL_BATCH_MANAGEMENT_FEE;
    uint128 public MIN_INTEREST_RATE_CHANGE_PERIOD;
    uint256 public INTEREST_RATE_ADJ_COOLDOWN;
    uint256 public UPFRONT_INTEREST_PERIOD;

    uint256 public REDEMPTION_FEE_FLOOR;
    uint256 public REDEMPTION_MINUTE_DECAY_FACTOR;
    uint256 public REDEMPTION_BETA;
    uint256 public URGENT_REDEMPTION_BONUS;
    uint256 public MAX_BATCH_SHARES_RATIO;

    uint256 public SP_YIELD_SPLIT;

    // Branch
    mapping(address => uint256) public CCR;
    mapping(address => uint256) public MCR;
    mapping(address => uint256) public SCR;
    mapping(address => uint256) public BCR;
    mapping(address => uint256) public LIQUIDATION_PENALTY_SP;
    mapping(address => uint256) public LIQUIDATION_PENALTY_REDISTRIBUTION;

    // --- Events ---
    event DefaultGlobalsSet();
    event GasCompensationsSet(CompensationParams indexed _params);
    event LiquidationParamsSet(LiquidationParams indexed _params);
    event MinParamsSet(MinParams indexed _params);
    event InterestParamsSet(InterestParams indexed _params);
    event RedemptionParamsSet(RedemptionParams indexed _params);
    event YieldSplitSet(uint256 indexed _old, uint256 indexed _new);
    event BranchParamsSet(BranchParams indexed _params);

    // --- Errors ---
    error InvalidCCR();
    error InvalidMCR();
    error InvalidBCR();
    error InvalidSCR();
    error SPPenaltyTooLow();
    error SPPenaltyGtRedist();
    error RedistPenaltyTooHigh();

    // --- Init ---
    function initialize(address _owner) external initializer {

        __Ownable2Step_init();
        setGlobalsToDefault();
        if (msg.sender != _owner) {
            _transferOwnership(_owner);
        }
    }

    // --- Admin ---
    function setGlobalsToDefault() public onlyOwner {

        ETH_GAS_COMPENSATION = 0.0375 ether;
        COLL_GAS_COMPENSATION_DIVISOR = 200; // 0.5%
        COLL_GAS_COMPENSATION_CAP = 2 ether;
        
        MIN_LIQUIDATION_PENALTY_SP = 5e16;              // 5%
        MAX_LIQUIDATION_PENALTY_REDISTRIBUTION = 20e16; // 20%
        
        MIN_DEBT = 2000e18;
        MIN_BOLD_IN_SP = 1e18;
        
        MIN_ANNUAL_INTEREST_RATE = _1pct / 2;                    // 0.5%
        MAX_ANNUAL_INTEREST_RATE = 250 * _1pct;                  // 250%
        MAX_ANNUAL_BATCH_MANAGEMENT_FEE = uint128(_100pct / 10); // 10%
        MIN_INTEREST_RATE_CHANGE_PERIOD = 1 hours;               // batch managers / batched Troves
        INTEREST_RATE_ADJ_COOLDOWN = 7 days;
        UPFRONT_INTEREST_PERIOD = 7 days;

        REDEMPTION_FEE_FLOOR = _1pct / 2;                     // 0.5%
        REDEMPTION_MINUTE_DECAY_FACTOR = 998076443575628800;
        REDEMPTION_BETA = 1;
        URGENT_REDEMPTION_BONUS = 2e16;                       // 2%
        MAX_BATCH_SHARES_RATIO = 1e9;
        
        SP_YIELD_SPLIT = 75 * _1pct; // 100%

        emit DefaultGlobalsSet();
    }
    function setCompensationParams(CompensationParams calldata _params) external onlyOwner {

        ETH_GAS_COMPENSATION = _params.ETH_GAS_COMPENSATION;
        COLL_GAS_COMPENSATION_DIVISOR = _params.COLL_GAS_COMPENSATION_DIVISOR;
        COLL_GAS_COMPENSATION_CAP = _params.COLL_GAS_COMPENSATION_CAP;

        emit GasCompensationsSet(_params);
    }
    function setLiquidationParams(LiquidationParams calldata _params) external onlyOwner {

        MIN_LIQUIDATION_PENALTY_SP = _params.MIN_LIQUIDATION_PENALTY_SP;
        MAX_LIQUIDATION_PENALTY_REDISTRIBUTION = _params.MAX_LIQUIDATION_PENALTY_REDISTRIBUTION;

        emit LiquidationParamsSet(_params);
    }
    function setMinParams(MinParams calldata _params) external onlyOwner {

        MIN_DEBT = _params.MIN_DEBT;
        MIN_BOLD_IN_SP = _params.MIN_BOLD_IN_SP;

        emit MinParamsSet(_params);
    }
    function setInterestParams(InterestParams calldata _params) external onlyOwner {

        MIN_ANNUAL_INTEREST_RATE = _params.MIN_ANNUAL_INTEREST_RATE;
        MAX_ANNUAL_INTEREST_RATE = _params.MAX_ANNUAL_INTEREST_RATE;
        MAX_ANNUAL_BATCH_MANAGEMENT_FEE = _params.MAX_ANNUAL_BATCH_MANAGEMENT_FEE;
        MIN_INTEREST_RATE_CHANGE_PERIOD = _params.MIN_INTEREST_RATE_CHANGE_PERIOD;
        INTEREST_RATE_ADJ_COOLDOWN = _params.INTEREST_RATE_ADJ_COOLDOWN;
        UPFRONT_INTEREST_PERIOD = _params.UPFRONT_INTEREST_PERIOD;

        emit InterestParamsSet(_params);
    }
    function setRedemptionParams(RedemptionParams calldata _params) external onlyOwner {

        REDEMPTION_FEE_FLOOR = _params.REDEMPTION_FEE_FLOOR;
        REDEMPTION_MINUTE_DECAY_FACTOR = _params.REDEMPTION_MINUTE_DECAY_FACTOR;
        REDEMPTION_BETA = _params.REDEMPTION_BETA;
        URGENT_REDEMPTION_BONUS = _params.URGENT_REDEMPTION_BONUS;
        MAX_BATCH_SHARES_RATIO = _params.MAX_BATCH_SHARES_RATIO;

        emit RedemptionParamsSet(_params);
    }
    function setYieldSplit(uint256 _SP_YIELD_SPLIT) external onlyOwner {

        emit YieldSplitSet(SP_YIELD_SPLIT, _SP_YIELD_SPLIT);

        SP_YIELD_SPLIT = _SP_YIELD_SPLIT;
    }
    function setBranchParams(BranchParams calldata _params) external onlyOwner {

        if (_params.CCR <= 1e18 || _params.CCR >= 2e18)  revert InvalidCCR();  
        if (_params.MCR <= 1e18 || _params.MCR >= 2e18)  revert InvalidMCR();
        if (_params.BCR <  5e16 || _params.BCR >= 50e16) revert InvalidBCR();
        if (_params.SCR <= 1e18 || _params.SCR >= 2e18)  revert InvalidSCR();
        if (_params.LIQUIDATION_PENALTY_SP < MIN_LIQUIDATION_PENALTY_SP) revert SPPenaltyTooLow();
        if (_params.LIQUIDATION_PENALTY_SP > _params.LIQUIDATION_PENALTY_REDISTRIBUTION) revert SPPenaltyGtRedist();
        if (_params.LIQUIDATION_PENALTY_REDISTRIBUTION > MAX_LIQUIDATION_PENALTY_REDISTRIBUTION) revert RedistPenaltyTooHigh();

        CCR[_params.collToken] = _params.CCR;
        MCR[_params.collToken] = _params.MCR;
        SCR[_params.collToken] = _params.SCR;
        BCR[_params.collToken] = _params.BCR;
        LIQUIDATION_PENALTY_SP[_params.collToken] = _params.LIQUIDATION_PENALTY_SP;
        LIQUIDATION_PENALTY_REDISTRIBUTION[_params.collToken] = _params.LIQUIDATION_PENALTY_REDISTRIBUTION;

        emit BranchParamsSet(_params);
    }

    // --- Views ---
    function getBranchParams(address _collToken) external view returns (BranchParams memory _params) {
        _params.CCR = CCR[_collToken];
        _params.MCR = MCR[_collToken];
        _params.SCR = SCR[_collToken];
        _params.BCR = BCR[_collToken];
        _params.LIQUIDATION_PENALTY_SP = LIQUIDATION_PENALTY_SP[_collToken];
        _params.LIQUIDATION_PENALTY_REDISTRIBUTION = LIQUIDATION_PENALTY_REDISTRIBUTION[_collToken];
    }
}