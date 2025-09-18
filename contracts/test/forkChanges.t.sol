// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "./TestContracts/DevTestSetup.sol";
import "openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

import { ITroveManager } from "../src/Interfaces/ITroveManager.sol";
import { TroveManager  } from "src/TroveManager.sol";
import { ERC20Faucet   } from "./TestContracts/ERC20Faucet.sol";

contract ForkChanges is DevTestSetup {

    // add collateral
    function testAddCollateralsFailsForNonOwner() public {
        vm.startPrank(G);
        ITroveManager[] memory tm = new ITroveManager[](1);
        IERC20MetadataUpgradeable[] memory mu = new IERC20MetadataUpgradeable[](1);

        vm.expectRevert("Ownable: caller is not the owner");
        collateralRegistry.addCollaterals(mu, tm);

        vm.stopPrank(); 
    }
    function testAddCollateralsFailsForEmptyList() public {
        vm.startPrank(address(deployer));
        ITroveManager[] memory tm = new ITroveManager[](0);
        IERC20MetadataUpgradeable[] memory mu = new IERC20MetadataUpgradeable[](0);
        vm.expectRevert("Collateral list cannot be empty");
        collateralRegistry.addCollaterals(mu, tm);
        vm.stopPrank(); 
    }
    function testAddCollateralsFailsForMismatchArgsLength() public {
        vm.startPrank(address(deployer));
        ITroveManager[] memory tm = new ITroveManager[](0);
        IERC20MetadataUpgradeable[] memory mu = new IERC20MetadataUpgradeable[](1);
        vm.expectRevert("Length mistmatch");
        collateralRegistry.addCollaterals(mu, tm);
        vm.stopPrank(); 
    }
    function testAddCollaterals() public {
        IERC20MetadataUpgradeable collToken = new ERC20Faucet();
        ITroveManager troveManager = new TroveManager();
        ITroveManager[] memory tm = new ITroveManager[](1);
        IERC20MetadataUpgradeable[] memory mu = new IERC20MetadataUpgradeable[](1);
        tm[0] = troveManager;
        mu[0] = collToken;

        vm.startPrank(address(deployer));
        collateralRegistry.addCollaterals(mu, tm);
        vm.stopPrank(); 

        assert(troveManager == collateralRegistry.getTroveManager(1));
        assert(collToken == collateralRegistry.getToken(1));
    }
    function testAddCollateralsFailsForAlreadyAdded() public {
        IERC20MetadataUpgradeable collToken = new ERC20Faucet();
        ITroveManager troveManager = new TroveManager();
        ITroveManager[] memory tm = new ITroveManager[](1);
        IERC20MetadataUpgradeable[] memory mu = new IERC20MetadataUpgradeable[](1);
        tm[0] = troveManager;
        mu[0] = collToken;

        vm.startPrank(address(deployer));
        collateralRegistry.addCollaterals(mu, tm);
        vm.expectRevert("Already added");
        collateralRegistry.addCollaterals(mu, tm);
        vm.stopPrank(); 
    }

    // remove collateral
    function testRemoveCollateralsFailsForNonOwner() public {
        vm.startPrank(G);
        IERC20MetadataUpgradeable[] memory mu = new IERC20MetadataUpgradeable[](1);

        vm.expectRevert("Ownable: caller is not the owner");
        collateralRegistry.removeCollaterals(mu, false);

        vm.stopPrank(); 
    }
    function testRemoveCollateralsFailsForNotAlreadyAdded() public {
        IERC20MetadataUpgradeable[] memory mu = new IERC20MetadataUpgradeable[](1);

        vm.startPrank(address(deployer));
        vm.expectRevert("Not added");
        collateralRegistry.removeCollaterals(mu, false);
        vm.stopPrank(); 
    }
    function testRemoveCollateralsFailsForHavingTroves() public {
        IERC20MetadataUpgradeable[] memory mu = new IERC20MetadataUpgradeable[](1);
        mu[0] = IERC20MetadataUpgradeable(address(WETH));

        uint256 price = 2000e18;
        priceFeed.setPrice(price);
        uint256 troveDebtRequest_A = 2000e18;
        uint256 interestRate = 5e16;
        openTroveNoHints100pct(A, 5 ether, troveDebtRequest_A, interestRate);

        vm.startPrank(address(deployer));
        vm.expectRevert("No troves must be present");
        collateralRegistry.removeCollaterals(mu, false);
        vm.stopPrank(); 
    }
    function testRemoveCollateralsFailsForLiveBranch() public {
        IERC20MetadataUpgradeable[] memory mu = new IERC20MetadataUpgradeable[](1);
        mu[0] = IERC20MetadataUpgradeable(address(WETH));

        vm.startPrank(address(deployer));
        vm.expectRevert("Branch is live");
        collateralRegistry.removeCollaterals(mu, false);
        vm.stopPrank(); 
    }
    function testRemoveCollaterals() public {
        IERC20MetadataUpgradeable[] memory mu = new IERC20MetadataUpgradeable[](1);
        mu[0] = IERC20MetadataUpgradeable(address(WETH));

        assert(IERC20MetadataUpgradeable(address(WETH)) == collateralRegistry.getToken(0));
        
        (uint256 _index, bool _set) = collateralRegistry.arrayIndex(IERC20MetadataUpgradeable(address(WETH)));
        assert(_index == 0);
        assert(_set == true);
        
        vm.startPrank(address(deployer));
        collateralRegistry.shutdownCollaterals(mu);

        collateralRegistry.removeCollaterals(mu, false);

        (_index, _set) = collateralRegistry.arrayIndex(IERC20MetadataUpgradeable(address(WETH)));
        assert(_index == 0);
        assert(_set == false);

        vm.stopPrank(); 
    }
    function testRemoveCollateralsForcedFailsForLiveBranchWithTrovesPresent() public {
        IERC20MetadataUpgradeable[] memory mu = new IERC20MetadataUpgradeable[](1);
        mu[0] = IERC20MetadataUpgradeable(address(WETH));

        uint256 price = 2000e18;
        priceFeed.setPrice(price);
        uint256 troveDebtRequest_A = 2000e18;
        uint256 interestRate = 5e16;
        openTroveNoHints100pct(A, 5 ether, troveDebtRequest_A, interestRate);

        vm.startPrank(address(deployer));
        vm.expectRevert("Branch is live");
        collateralRegistry.removeCollaterals(mu, true); // forced true
        vm.stopPrank(); 
    }
    function testRemoveCollateralsForcedWithTrovesPresent() public {
        IERC20MetadataUpgradeable[] memory mu = new IERC20MetadataUpgradeable[](1);
        mu[0] = IERC20MetadataUpgradeable(address(WETH));

        uint256 price = 2000e18;
        priceFeed.setPrice(price);
        uint256 troveDebtRequest_A = 2000e18;
        uint256 interestRate = 5e16;
        openTroveNoHints100pct(A, 5 ether, troveDebtRequest_A, interestRate);

        assert(IERC20MetadataUpgradeable(address(WETH)) == collateralRegistry.getToken(0));
        
        (uint256 _index, bool _set) = collateralRegistry.arrayIndex(IERC20MetadataUpgradeable(address(WETH)));
        assert(_index == 0);
        assert(_set == true);
        
        vm.startPrank(address(deployer));
        collateralRegistry.shutdownCollaterals(mu);

        collateralRegistry.removeCollaterals(mu, true); // forced true

        (_index, _set) = collateralRegistry.arrayIndex(IERC20MetadataUpgradeable(address(WETH)));
        assert(_index == 0);
        assert(_set == false);

        assert(troveManager.getTroveIdsCount() != 0);
        vm.stopPrank(); 
    }

    // shutdown collateral
    function testShutdownCollateralsFailsForNonOwner() public {
        vm.startPrank(G);
        ITroveManager[] memory tm = new ITroveManager[](1);
        IERC20MetadataUpgradeable[] memory mu = new IERC20MetadataUpgradeable[](1);

        vm.expectRevert("Ownable: caller is not the owner");
        collateralRegistry.shutdownCollaterals(mu);

        vm.stopPrank(); 
    }
    function testShutdownCollateralsFailsForNotAlreadyAdded() public {
        IERC20MetadataUpgradeable collToken = new ERC20Faucet();
        IERC20MetadataUpgradeable[] memory mu = new IERC20MetadataUpgradeable[](1);
        mu[0] = collToken;

        vm.startPrank(address(deployer));
        vm.expectRevert("Not added");
        collateralRegistry.shutdownCollaterals(mu);
        vm.stopPrank(); 
    }
    function testShutdownCollaterals() public {
        IERC20MetadataUpgradeable[] memory mu = new IERC20MetadataUpgradeable[](1);
        mu[0] = IERC20MetadataUpgradeable(address(WETH));

        vm.startPrank(address(deployer));
        collateralRegistry.shutdownCollaterals(mu);
        vm.stopPrank(); 

        assert(troveManager.shutdownTime() != 0);
        assert(activePool.shutdownTime() != 0);
        assert(borrowerOperations.hasBeenShutDown() == true); 
    }

    // resume collateral
    function testResumeCollateralsFailsForNonOwner() public {
        vm.startPrank(G);
        ITroveManager[] memory tm = new ITroveManager[](1);
        IERC20MetadataUpgradeable[] memory mu = new IERC20MetadataUpgradeable[](1);

        vm.expectRevert("Ownable: caller is not the owner");
        collateralRegistry.resumeCollaterals(mu);

        vm.stopPrank(); 
    }
    function testResumeCollateralsFailsForNotAlreadyAdded() public {
        IERC20MetadataUpgradeable collToken = new ERC20Faucet();
        IERC20MetadataUpgradeable[] memory mu = new IERC20MetadataUpgradeable[](1);
        mu[0] = collToken;

        vm.startPrank(address(deployer));
        vm.expectRevert("Not added");
        collateralRegistry.resumeCollaterals(mu);
        vm.stopPrank(); 
    }
    function testResumeCollaterals() public {
        IERC20MetadataUpgradeable[] memory mu = new IERC20MetadataUpgradeable[](1);
        mu[0] = IERC20MetadataUpgradeable(address(WETH));

        vm.startPrank(address(deployer));
        collateralRegistry.shutdownCollaterals(mu);
        vm.stopPrank(); 

        assert(troveManager.shutdownTime() != 0);
        assert(activePool.shutdownTime() != 0);
        assert(borrowerOperations.hasBeenShutDown() == true);

        vm.startPrank(address(deployer));
        collateralRegistry.resumeCollaterals(mu);
        vm.stopPrank(); 

        assert(troveManager.shutdownTime() == 0);
        assert(activePool.shutdownTime() == 0);
        assert(borrowerOperations.hasBeenShutDown() == false);
    }

    // redeem threshold
    function testRedeemDoesNotWorkAboveThreshold() public {
        vm.startPrank(address(deployer));
        parameters.setBranchParams(
            IParameters.BranchParams(
                address(WETH), // Collateral
                150e16,        // CCR
                110e16,        // MCR
                110e16,        // SCR
                10e16,         // BCR
                5e16,          // Liq Penalty SP
                10e16,         // Liq Penalty Retribution
                5e16           // Redemption Threshold
            )
        ); 
        vm.stopPrank();

        uint256 price = 2000e18;
        priceFeed.setPrice(price);
        uint256 troveDebtRequest_A = 2000e18;
        uint256 interestRate = 6e16;

        uint256 tID1 = openTroveNoHints100pct(A, 5 ether, troveDebtRequest_A, interestRate);
        uint256 tID2 = openTroveNoHints100pct(B, 5 ether, troveDebtRequest_A, interestRate);

        assert(troveManager.getTroveEntireColl(tID1) == 5 ether);

        redeem(B, 5e18);

        assert(troveManager.getTroveEntireColl(tID1) == 5 ether);
    }
    function testRedeemWorksBelowThreshold() public {
        vm.startPrank(address(deployer));
        parameters.setBranchParams(
            IParameters.BranchParams(
                address(WETH), // Collateral
                150e16,        // CCR
                110e16,        // MCR
                110e16,        // SCR
                10e16,         // BCR
                5e16,          // Liq Penalty SP
                10e16,         // Liq Penalty Retribution
                5e16           // Redemption Threshold
            )
        ); 
        vm.stopPrank();

        uint256 price = 2000e18;
        priceFeed.setPrice(price);
        uint256 troveDebtRequest_A = 2000e18;
        uint256 interestRate1 = 4e16;
        uint256 interestRate2 = 5e16;

        uint256 tID1 = openTroveNoHints100pct(A, 5 ether, troveDebtRequest_A, interestRate1);
        uint256 tID2 = openTroveNoHints100pct(B, 5 ether, troveDebtRequest_A, interestRate2);

        assert(troveManager.getTroveEntireColl(tID1) == 5 ether);
        uint256 wethBefore = WETH.balanceOf(B);
        uint256 boldBefore = boldToken.balanceOf(B);

        vm.warp(block.timestamp + 14 days); // redemp fee starts at 100%

        uint256 redeemAmount = 1000e18;

        redeem(B, redeemAmount);

        uint256 wethDiff = WETH.balanceOf(B) - wethBefore;
        assert(boldBefore == boldToken.balanceOf(B) + redeemAmount);
        assert(WETH.balanceOf(B) ==  wethBefore + wethDiff);
        assert(troveManager.getTroveEntireColl(tID1) < 5 ether);
    }

    // parameters
    function testParametersDefaultGlobals() public {
        assert(parameters.ETH_GAS_COMPENSATION() == 0.0375 ether);

        assert(parameters.COLL_GAS_COMPENSATION_DIVISOR() == 200);

        assert(parameters.COLL_GAS_COMPENSATION_CAP() == 2 ether);

        assert(parameters.MIN_LIQUIDATION_PENALTY_SP() == 5e16);

        assert(parameters.MAX_LIQUIDATION_PENALTY_REDISTRIBUTION() == 20e16);

        assert(parameters.MIN_DEBT() == 2000e18);

        assert(parameters.MIN_BOLD_IN_SP() == 1e18);

        assert(parameters.MIN_ANNUAL_INTEREST_RATE() == _1pct / 2);

        assert(parameters.MAX_ANNUAL_INTEREST_RATE() == 250 * _1pct);

        assert(parameters.MAX_ANNUAL_BATCH_MANAGEMENT_FEE() == uint128(_100pct / 10));

        assert(parameters.MIN_INTEREST_RATE_CHANGE_PERIOD() == 1 hours);

        assert(parameters.INTEREST_RATE_ADJ_COOLDOWN() == 7 days);

        assert(parameters.UPFRONT_INTEREST_PERIOD() == 7 days);

        assert(parameters.REDEMPTION_FEE_FLOOR() == _1pct / 2);

        assert(parameters.REDEMPTION_MINUTE_DECAY_FACTOR() == 998076443575628800);

        assert(parameters.REDEMPTION_BETA() == 1);

        assert(parameters.URGENT_REDEMPTION_BONUS() == 2e16);

        assert(parameters.MAX_BATCH_SHARES_RATIO() == 1e9);

        assert(parameters.SP_YIELD_SPLIT() == 75 * _1pct);
    }
    function testParametersSetCompensationParams() public {
        vm.startPrank(address(deployer));
        parameters.setCompensationParams(
            IParameters.CompensationParams(
                0.4 ether,
                300,
                3 ether
            )
        );
        vm.stopPrank();

        assert(parameters.ETH_GAS_COMPENSATION() == 0.4 ether);

        assert(parameters.COLL_GAS_COMPENSATION_DIVISOR() == 300);

        assert(parameters.COLL_GAS_COMPENSATION_CAP() == 3 ether);
    }
    function testParametersSetLiquidationParams() public {
        vm.startPrank(address(deployer));
        parameters.setLiquidationParams(
            IParameters.LiquidationParams(
                6e16,
                21e16
            )
        );
        vm.stopPrank();

        assert(parameters.MIN_LIQUIDATION_PENALTY_SP() == 6e16);

        assert(parameters.MAX_LIQUIDATION_PENALTY_REDISTRIBUTION() == 21e16);
    }
    function testParametersSetMinParams() public {
        vm.startPrank(address(deployer));
        parameters.setMinParams(
            IParameters.MinParams(
                3000e18,
                2e18
            )
        );
        vm.stopPrank();

        assert(parameters.MIN_DEBT() == 3000e18);

        assert(parameters.MIN_BOLD_IN_SP() == 2e18);
    }
    function testParametersSetInterestParams() public {
        vm.startPrank(address(deployer));
        parameters.setInterestParams(
            IParameters.InterestParams(
                _1pct / 3,
                260 * _1pct,
                uint128(_100pct / 12),
                2 hours,
                8 days,
                8 days
            )
        );
        vm.stopPrank();

        assert(parameters.MIN_ANNUAL_INTEREST_RATE() == _1pct / 3);

        assert(parameters.MAX_ANNUAL_INTEREST_RATE() == 260 * _1pct);

        assert(parameters.MAX_ANNUAL_BATCH_MANAGEMENT_FEE() == uint128(_100pct / 12));

        assert(parameters.MIN_INTEREST_RATE_CHANGE_PERIOD() == 2 hours);

        assert(parameters.INTEREST_RATE_ADJ_COOLDOWN() == 8 days);

        assert(parameters.UPFRONT_INTEREST_PERIOD() == 8 days);
    }
    function testParametersSetRedemptionParams() public {
        vm.startPrank(address(deployer));
        parameters.setRedemptionParams(
            IParameters.RedemptionParams(
                _1pct / 3,
                988076443575628800,
                2,
                3e16,
                2e9
            )
        );
        vm.stopPrank();

        assert(parameters.REDEMPTION_FEE_FLOOR() == _1pct / 3);

        assert(parameters.REDEMPTION_MINUTE_DECAY_FACTOR() == 988076443575628800);

        assert(parameters.REDEMPTION_BETA() == 2);

        assert(parameters.URGENT_REDEMPTION_BONUS() == 3e16);

        assert(parameters.MAX_BATCH_SHARES_RATIO() == 2e9);
    }
    function testParametersSetYieldSplit() public {
        vm.startPrank(address(deployer));
        parameters.setYieldSplit(85 * _1pct);
        vm.stopPrank();

        assert(parameters.SP_YIELD_SPLIT() == 85 * _1pct);
    }
    function testParametersSetBranchParamsFailsForInvalidCCR() public {
        vm.startPrank(address(deployer));
        vm.expectRevert("InvalidCCR()");
        parameters.setBranchParams(
            IParameters.BranchParams(
                address(WETH),
                3e18,
                0,
                0,
                0,
                0,
                0,
                0
            )
        );
        vm.stopPrank();
    }
    function testParametersSetBranchParamsFailsForInvalidMCR() public {
        vm.startPrank(address(deployer));
        vm.expectRevert("InvalidMCR()");
        parameters.setBranchParams(
            IParameters.BranchParams(
                address(WETH),
                12e17,
                3e18,
                0,
                0,
                0,
                0,
                0
            )
        );
        vm.stopPrank();
    }
    function testParametersSetBranchParamsFailsForInvalidBCR() public {
        vm.startPrank(address(deployer));
        vm.expectRevert("InvalidBCR()");
        parameters.setBranchParams(
            IParameters.BranchParams(
                address(WETH),
                12e17,
                12e17,
                12e17,
                51e18,
                0,
                0,
                0
            )
        );
        vm.stopPrank();
    }
    function testParametersSetBranchParamsFailsForInvalidSCR() public {
        vm.startPrank(address(deployer));
        vm.expectRevert("InvalidSCR()");
        parameters.setBranchParams(
            IParameters.BranchParams(
                address(WETH),
                12e17,
                12e17,
                3e18,
                6e16,
                0,
                0,
                0
            )
        );
        vm.stopPrank();
    }
    function testParametersSetBranchParamsFailsForSPPenaltyTooLow() public {
        vm.startPrank(address(deployer));
        vm.expectRevert("SPPenaltyTooLow()");
        parameters.setBranchParams(
            IParameters.BranchParams(
                address(WETH),
                12e17,
                12e17,
                12e17,
                6e16,
                4e16,
                0,
                0
            )
        );
        vm.stopPrank();
    }
    function testParametersSetBranchParamsFailsForSPPenaltyGtRedist() public {
        vm.startPrank(address(deployer));
        vm.expectRevert("SPPenaltyGtRedist()");
        parameters.setBranchParams(
            IParameters.BranchParams(
                address(WETH),
                12e17,
                12e17,
                12e17,
                6e16,
                6e16,
                5e16,
                0
            )
        );
        vm.stopPrank();
    }
    function testParametersSetBranchParamsFailsForRedistPenaltyTooHigh() public {
        vm.startPrank(address(deployer));
        vm.expectRevert("RedistPenaltyTooHigh()");
        parameters.setBranchParams(
            IParameters.BranchParams(
                address(WETH),
                12e17,
                12e17,
                12e17,
                6e16,
                6e16,
                21e16,
                0
            )
        );
        vm.stopPrank();
    }
    function testParametersSetBranchParams() public {
        vm.startPrank(address(deployer));
        parameters.setBranchParams(
            IParameters.BranchParams(
                address(WETH),
                12e17,
                12e17,
                12e17,
                6e16,
                6e16,
                16e16,
                1e18
            )
        );
        vm.stopPrank();

        IParameters.BranchParams memory bp = parameters.getBranchParams(address(WETH));
        
        assert(bp.CCR == 12e17);

        assert(bp.MCR == 12e17);

        assert(bp.BCR == 6e16);

        assert(bp.SCR == 12e17);

        assert(bp.LIQUIDATION_PENALTY_SP == 6e16);

        assert(bp.LIQUIDATION_PENALTY_REDISTRIBUTION == 16e16);
        
        assert(bp.REDEMPTION_THRESHOLD == 1e18);
    }
}
