// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IDefaultCollateralMigrator} from "src/interfaces/IDefaultCollateralMigrator.sol";

import {IDefaultCollateral} from "@symbiotic/collateral/interfaces/defaultCollateral/IDefaultCollateral.sol";
import {IVault} from "@symbiotic/core/interfaces/vault/IVault.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DefaultCollateralMigrator is IDefaultCollateralMigrator {
    /**
     * @inheritdoc IDefaultCollateralMigrator
     */
    function migrate(
        address collateral,
        address vault,
        address onBehalfOf,
        uint256 amount
    ) external returns (uint256, uint256) {
        IERC20(collateral).transferFrom(msg.sender, address(this), amount);
        IDefaultCollateral(collateral).withdraw(address(this), amount);

        address asset = IDefaultCollateral(collateral).asset();
        amount = IERC20(asset).balanceOf(address(this));
        IERC20(asset).approve(vault, amount);
        return IVault(vault).deposit(onBehalfOf, amount);
    }
}
