// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SymbioticPeripheryImports.sol";

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {Test} from "forge-std/Test.sol";

contract SymbioticPeripheryBindings is Test {
    using SafeERC20 for IERC20;

    function _migrate_SymbioticPeriphery(
        ISymbioticDefaultCollateralMigrator symbioticDefaultCollateralMigrator,
        address who,
        address defaultCollateral,
        address vault,
        address onBehalfOf,
        uint256 amount
    ) internal virtual returns (uint256 depositedAmount, uint256 mintedShares) {
        vm.startPrank(who);
        IERC20(defaultCollateral).forceApprove(address(symbioticDefaultCollateralMigrator), amount);
        (depositedAmount, mintedShares) =
            symbioticDefaultCollateralMigrator.migrate(defaultCollateral, vault, onBehalfOf, amount);
        vm.stopPrank();
    }
}
