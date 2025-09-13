// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.24;

import "openzeppelin-contracts-upgradeable/contracts/access/Ownable2StepUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

import "./Interfaces/ITroveManager.sol";
import "./Interfaces/IBoldToken.sol";
import "./Interfaces/IParameters.sol";
import "./Dependencies/Constants.sol";
import "./Dependencies/LiquityMath.sol";

import "./Interfaces/ICollateralRegistry.sol";

contract CollateralRegistry is Ownable2StepUpgradeable, ICollateralRegistry {
    // See: https://github.com/ethereum/solidity/issues/12587
    uint256 public totalCollaterals;

    IERC20MetadataUpgradeable[] public tokens;
    ITroveManager[] public troveManagers;
    mapping(IERC20MetadataUpgradeable _token => IndexContainer _index) public arrayIndex;
    
    IBoldToken public boldToken;
    IParameters public parameters;

    uint256 public baseRate;

    // The timestamp of the latest fee operation (redemption or new Bold issuance)
    uint256 public lastFeeOperationTime = block.timestamp;

    struct IndexContainer {
        uint256 index;
        bool set;
    }

    event BaseRateUpdated(uint256 _baseRate);
    event LastFeeOpTimeUpdated(uint256 _lastFeeOpTime);
    event CollateralShutdown(IERC20MetadataUpgradeable indexed _tokens);
    event CollateralResumed(IERC20MetadataUpgradeable indexed _tokens);
    event CollateralAdded(IERC20MetadataUpgradeable indexed _token);
    event CollateralRemoved(IERC20MetadataUpgradeable indexed _token);

    function initialize(address _owner, IBoldToken _boldToken, IParameters _parameters, IERC20MetadataUpgradeable[] memory _tokens, ITroveManager[] memory _troveManagers) external initializer {
        
        __Ownable2Step_init();
        if (msg.sender != _owner) {
            _transferOwnership(_owner);
        }
        
        uint256 numTokens = _tokens.length;
        require(numTokens > 0, "Collateral list cannot be empty");
        require(_tokens.length == _troveManagers.length, "Length mistmatch");
        totalCollaterals = numTokens;

        boldToken = _boldToken;
        parameters = _parameters;

        for (uint256 i = 0; i < numTokens; i++) {
            _requireNotAlreadyAdded(_tokens[i]);
            tokens.push(_tokens[i]);
            troveManagers.push(_troveManagers[i]);
            arrayIndex[_tokens[i]] = IndexContainer(tokens.length - 1, true);
            emit CollateralAdded(_tokens[i]);
        }

        // Initialize the baseRate state variable
        baseRate = INITIAL_BASE_RATE;
        emit BaseRateUpdated(INITIAL_BASE_RATE);
    }

    // add/remove/shutdown/resume collaterals

    function addCollaterals(IERC20MetadataUpgradeable[] memory _tokens, ITroveManager[] memory _troveManagers) external onlyOwner {
        uint256 numTokens = _tokens.length;
        require(numTokens > 0, "Collateral list cannot be empty");
        require(_tokens.length == _troveManagers.length, "Length mistmatch");
        totalCollaterals += _tokens.length;

        for (uint256 i = 0; i < numTokens; i++) {

            _requireNotAlreadyAdded(_tokens[i]);
            tokens.push(_tokens[i]);
            troveManagers.push(_troveManagers[i]);
            arrayIndex[_tokens[i]] = IndexContainer(tokens.length - 1, true);

            emit CollateralAdded(_tokens[i]);
        }
    }

    function removeCollaterals(IERC20MetadataUpgradeable[] memory _tokens, bool _forced) external onlyOwner {
        uint256 numTokens = _tokens.length;
        require(numTokens > 0, "Collateral list cannot be empty");
        totalCollaterals -= _tokens.length;

        for (uint256 i = 0; i < numTokens; i++) {
            uint256 index = arrayIndex[_tokens[i]].index;
            _requireAlreadyAdded(_tokens[i]);

            if (!_forced) {
                require(troveManagers[index].getTroveIdsCount() == 0, "No troves must be present");
            }
            require(troveManagers[index].shutdownTime() != 0, "Branch is live");

            tokens[index] = tokens[tokens.length - 1];
            troveManagers[index] = troveManagers[troveManagers.length - 1];
            
            arrayIndex[tokens[index]] = IndexContainer(index, true);
            delete arrayIndex[_tokens[i]];

            tokens.pop();
            troveManagers.pop();

            emit CollateralRemoved(_tokens[i]);
        }
    }

    function shutdownCollaterals(IERC20MetadataUpgradeable[] memory _tokens) external onlyOwner {
        
        for (uint256 i = 0; i < _tokens.length; i++) {

            _requireAlreadyAdded(_tokens[i]);

            uint256 index = arrayIndex[_tokens[i]].index;
            troveManagers[index].shutdownForcefully();

            emit CollateralShutdown(_tokens[i]);
        }
    }

    function resumeCollaterals(IERC20MetadataUpgradeable[] memory _tokens) external onlyOwner {
        
        for (uint256 i = 0; i < _tokens.length; i++) {

            _requireAlreadyAdded(_tokens[i]);

            uint256 index = arrayIndex[_tokens[i]].index;
            troveManagers[index].resumeForcefully();

            emit CollateralResumed(_tokens[i]);
        }
    }

    struct RedemptionTotals {
        uint256 numCollaterals;
        uint256 boldSupplyAtStart;
        uint256 unbacked;
        uint256 redeemedAmount;
    }

    function redeemCollateral(uint256 _boldAmount, uint256 _maxIterationsPerCollateral, uint256 _maxFeePercentage)
        external
    {
        _requireValidMaxFeePercentage(_maxFeePercentage);
        _requireAmountGreaterThanZero(_boldAmount);

        RedemptionTotals memory totals;

        totals.numCollaterals = totalCollaterals;
        uint256[] memory unbackedPortions = new uint256[](totals.numCollaterals);
        uint256[] memory prices = new uint256[](totals.numCollaterals);

        // Gather and accumulate unbacked portions
        for (uint256 index = 0; index < totals.numCollaterals; index++) {
            ITroveManager troveManager = getTroveManager(index);
            (uint256 unbackedPortion, uint256 price, bool redeemable) =
                troveManager.getUnbackedPortionPriceAndRedeemability();
            prices[index] = price;
            if (redeemable && _isBelowThreshold(index)) {
                totals.unbacked += unbackedPortion;
                unbackedPortions[index] = unbackedPortion;
            }
        }

        // There’s an unlikely scenario where all the normally redeemable branches (i.e. having TCR > SCR) have 0 unbacked
        // In that case, we redeem proportionally to branch size
        if (totals.unbacked == 0) {
            unbackedPortions = new uint256[](totals.numCollaterals);
            for (uint256 index = 0; index < totals.numCollaterals; index++) {
                ITroveManager troveManager = getTroveManager(index);
                (,, bool redeemable) = troveManager.getUnbackedPortionPriceAndRedeemability();
                if (redeemable && _isBelowThreshold(index)) {
                    uint256 unbackedPortion = troveManager.getEntireBranchDebt();
                    totals.unbacked += unbackedPortion;
                    unbackedPortions[index] = unbackedPortion;
                }
            }
        } else {
            // Don't allow redeeming more than the total unbacked in one go, as that would result in a disproportionate
            // redemption (see CS-BOLD-013). Instead, truncate the redemption to total unbacked. If this happens, the
            // redeemer can call `redeemCollateral()` a second time to redeem the remainder of their BOLD.
            if (_boldAmount > totals.unbacked) {
                _boldAmount = totals.unbacked;
            }
        }

        totals.boldSupplyAtStart = boldToken.totalSupply();
        // Decay the baseRate due to time passed, and then increase it according to the size of this redemption.
        // Use the saved total Bold supply value, from before it was reduced by the redemption.
        // We only compute it here, and update it at the end,
        // because the final redeemed amount may be less than the requested amount
        // Redeemers should take this into account in order to request the optimal amount to not overpay
        uint256 redemptionRate =
            _calcRedemptionRate(_getUpdatedBaseRateFromRedemption(_boldAmount, totals.boldSupplyAtStart));
        require(redemptionRate <= _maxFeePercentage, "CR: Fee exceeded provided maximum");
        // Implicit by the above and the _requireValidMaxFeePercentage checks
        //require(newBaseRate < DECIMAL_PRECISION, "CR: Fee would eat up all collateral");

        // Compute redemption amount for each collateral and redeem against the corresponding TroveManager
        for (uint256 index = 0; index < totals.numCollaterals; index++) {
            //uint256 unbackedPortion = unbackedPortions[index];
            if (unbackedPortions[index] > 0) {
                uint256 redeemAmount = _boldAmount * unbackedPortions[index] / totals.unbacked;
                if (redeemAmount > 0) {
                    ITroveManager troveManager = getTroveManager(index);
                    uint256 redeemedAmount = troveManager.redeemCollateral(
                        msg.sender, redeemAmount, prices[index], redemptionRate, _maxIterationsPerCollateral
                    );
                    totals.redeemedAmount += redeemedAmount;
                }

                // Ensure that per-branch redeems add up to `_boldAmount` exactly
                _boldAmount -= redeemAmount;
                totals.unbacked -= unbackedPortions[index];
            }
        }

        _updateBaseRateAndGetRedemptionRate(totals.redeemedAmount, totals.boldSupplyAtStart);

        // Burn the total Bold that is cancelled with debt
        if (totals.redeemedAmount > 0) {
            boldToken.burn(msg.sender, totals.redeemedAmount);
        }
    }

    // --- Internal fee functions ---

    // Update the last fee operation time only if time passed >= decay interval. This prevents base rate griefing.
    function _updateLastFeeOpTime() internal {
        uint256 minutesPassed = _minutesPassedSinceLastFeeOp();

        if (minutesPassed > 0) {
            lastFeeOperationTime += ONE_MINUTE * minutesPassed;
            emit LastFeeOpTimeUpdated(lastFeeOperationTime);
        }
    }

    function _minutesPassedSinceLastFeeOp() internal view returns (uint256) {
        return (block.timestamp - lastFeeOperationTime) / ONE_MINUTE;
    }

    // Updates the `baseRate` state with math from `_getUpdatedBaseRateFromRedemption`
    function _updateBaseRateAndGetRedemptionRate(uint256 _boldAmount, uint256 _totalBoldSupplyAtStart) internal {
        uint256 newBaseRate = _getUpdatedBaseRateFromRedemption(_boldAmount, _totalBoldSupplyAtStart);

        //assert(newBaseRate <= DECIMAL_PRECISION); // This is already enforced in `_getUpdatedBaseRateFromRedemption`

        // Update the baseRate state variable
        baseRate = newBaseRate;
        emit BaseRateUpdated(newBaseRate);

        _updateLastFeeOpTime();
    }

    /*
     * This function calculates the new baseRate in the following way:
     * 1) decays the baseRate based on time passed since last redemption or Bold borrowing operation.
     * then,
     * 2) increases the baseRate based on the amount redeemed, as a proportion of total supply
     */
    function _getUpdatedBaseRateFromRedemption(uint256 _redeemAmount, uint256 _totalBoldSupply)
        internal
        view
        returns (uint256)
    {
        // decay the base rate
        uint256 decayedBaseRate = _calcDecayedBaseRate();

        // get the fraction of total supply that was redeemed
        uint256 redeemedBoldFraction = _redeemAmount * DECIMAL_PRECISION / _totalBoldSupply;

        uint256 newBaseRate = decayedBaseRate + redeemedBoldFraction / parameters.REDEMPTION_BETA();
        newBaseRate = LiquityMath._min(newBaseRate, DECIMAL_PRECISION); // cap baseRate at a maximum of 100%

        return newBaseRate;
    }

    function _calcDecayedBaseRate() internal view returns (uint256) {
        uint256 minutesPassed = _minutesPassedSinceLastFeeOp();
        uint256 decayFactor = LiquityMath._decPow(parameters.REDEMPTION_MINUTE_DECAY_FACTOR(), minutesPassed);

        return baseRate * decayFactor / DECIMAL_PRECISION;
    }

    function _calcRedemptionRate(uint256 _baseRate) internal view returns (uint256) {
        return LiquityMath._min(
            parameters.REDEMPTION_FEE_FLOOR() + _baseRate,
            DECIMAL_PRECISION // cap at a maximum of 100%
        );
    }

    function _calcRedemptionFee(uint256 _redemptionRate, uint256 _amount) internal pure returns (uint256) {
        uint256 redemptionFee = _redemptionRate * _amount / DECIMAL_PRECISION;
        return redemptionFee;
    }

    // external redemption rate/fee getters

    function getRedemptionRate() external view override returns (uint256) {
        return _calcRedemptionRate(baseRate);
    }

    function getRedemptionRateWithDecay() public view override returns (uint256) {
        return _calcRedemptionRate(_calcDecayedBaseRate());
    }

    function getRedemptionRateForRedeemedAmount(uint256 _redeemAmount) external view returns (uint256) {
        uint256 totalBoldSupply = boldToken.totalSupply();
        uint256 newBaseRate = _getUpdatedBaseRateFromRedemption(_redeemAmount, totalBoldSupply);
        return _calcRedemptionRate(newBaseRate);
    }

    function getRedemptionFeeWithDecay(uint256 _ETHDrawn) external view override returns (uint256) {
        return _calcRedemptionFee(getRedemptionRateWithDecay(), _ETHDrawn);
    }

    function getEffectiveRedemptionFeeInBold(uint256 _redeemAmount) external view override returns (uint256) {
        uint256 totalBoldSupply = boldToken.totalSupply();
        uint256 newBaseRate = _getUpdatedBaseRateFromRedemption(_redeemAmount, totalBoldSupply);
        return _calcRedemptionFee(_calcRedemptionRate(newBaseRate), _redeemAmount);
    }

    // getters

    function getToken(uint256 _index) external view returns (IERC20MetadataUpgradeable) {
        if (_index < tokens.length) return tokens[_index];
        else revert("Invalid index");
    }

    function getTroveManager(uint256 _index) public view returns (ITroveManager) {
        if (_index < tokens.length) return troveManagers[_index];
        else revert("Invalid index");
    }

    // require functions

    function _requireValidMaxFeePercentage(uint256 _maxFeePercentage) internal view {
        require(
            _maxFeePercentage >= parameters.REDEMPTION_FEE_FLOOR() && _maxFeePercentage <= DECIMAL_PRECISION,
            "Max fee percentage must be between 0.5% and 100%"
        );
    }

    function _requireAmountGreaterThanZero(uint256 _amount) internal pure {
        require(_amount > 0, "CollateralRegistry: Amount must be greater than zero");
    }

    function _requireNotAlreadyAdded(IERC20MetadataUpgradeable _token) internal view {
        require(!arrayIndex[_token].set, "Already added");
    }

    function _requireAlreadyAdded(IERC20MetadataUpgradeable _token) internal view {
        require(arrayIndex[_token].set, "Not added");
    }

    function _isBelowThreshold(uint256 _index) internal view returns (bool) {

        ITroveManager tm = troveManagers[_index];
        IERC20MetadataUpgradeable t = tokens[_index];
        
        uint256 _threshold = parameters.REDEMPTION_THRESHOLD(address(t));
        if (_threshold == 0) return true;

        uint256 lowestTroveID = tm.sortedTroves().getLast();
        uint256 lowestInterestRate = tm.getTroveAnnualInterestRate(lowestTroveID);
        return _threshold >= lowestInterestRate;
    }
}
