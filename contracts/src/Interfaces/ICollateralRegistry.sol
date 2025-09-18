// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "./IBoldToken.sol";
import "./IParameters.sol";
import "./ITroveManager.sol";

interface ICollateralRegistry {

    struct IndexContainer {
        uint256 index;
        bool set;
    }

    function baseRate() external view returns (uint256);
    function lastFeeOperationTime() external view returns (uint256);

    function redeemCollateral(uint256 _boldamount, uint256 _maxIterations, uint256 _maxFeePercentage) external;
    // getters
    function totalCollaterals() external view returns (uint256);
    function getToken(uint256 _index) external view returns (IERC20MetadataUpgradeable);
    function getTroveManager(uint256 _index) external view returns (ITroveManager);
    function boldToken() external view returns (IBoldToken);
    function parameters() external view returns (IParameters);

    function getRedemptionRate() external view returns (uint256);
    function getRedemptionRateWithDecay() external view returns (uint256);
    function getRedemptionRateForRedeemedAmount(uint256 _redeemAmount) external view returns (uint256);

    function getRedemptionFeeWithDecay(uint256 _ETHDrawn) external view returns (uint256);
    function getEffectiveRedemptionFeeInBold(uint256 _redeemAmount) external view returns (uint256);

    function addCollaterals(IERC20MetadataUpgradeable[] memory _tokens, ITroveManager[] memory _troveManagers) external;
    function removeCollaterals(IERC20MetadataUpgradeable[] memory _tokens, bool _forced) external;
    function shutdownCollaterals(IERC20MetadataUpgradeable[] memory _tokens) external;
    function resumeCollaterals(IERC20MetadataUpgradeable[] memory _tokens) external;
    function arrayIndex(IERC20MetadataUpgradeable) external view returns (uint256, bool);
}
