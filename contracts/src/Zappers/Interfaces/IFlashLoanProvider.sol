// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "openzeppelin-contracts-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";
import "./ILeverageZapper.sol";
import "./IFlashLoanReceiver.sol";

interface IFlashLoanProvider {
    enum Operation {
        OpenTrove,
        CloseTrove,
        LeverUpTrove,
        LeverDownTrove
    }

    function receiver() external view returns (IFlashLoanReceiver);

    function makeFlashLoan(IERC20Upgradeable _token, uint256 _amount, Operation _operation, bytes calldata userData) external;
}
