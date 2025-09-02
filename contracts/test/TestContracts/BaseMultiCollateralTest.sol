// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IERC20Upgradeable} from "openzeppelin-contracts-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";
import {IBoldToken} from "src/Interfaces/IBoldToken.sol";
import {ICollateralRegistry} from "src/Interfaces/ICollateralRegistry.sol";
import {IWETH} from "src/Interfaces/IWETH.sol";
import {HintHelpers} from "src/HintHelpers.sol";
import {TestDeployer} from "./Deployment.t.sol";

contract BaseMultiCollateralTest {
    struct Contracts {
        IWETH weth;
        ICollateralRegistry collateralRegistry;
        IBoldToken boldToken;
        HintHelpers hintHelpers;
        TestDeployer.LiquityContractsDev[] branches;
    }

    IERC20Upgradeable weth;
    ICollateralRegistry collateralRegistry;
    IBoldToken boldToken;
    HintHelpers hintHelpers;
    TestDeployer.LiquityContractsDev[] branches;

    function setupContracts(Contracts memory contracts) internal {
        weth = contracts.weth;
        collateralRegistry = contracts.collateralRegistry;
        boldToken = contracts.boldToken;
        hintHelpers = contracts.hintHelpers;

        for (uint256 i = 0; i < contracts.branches.length; ++i) {
            branches.push(contracts.branches[i]);
        }
    }
}
