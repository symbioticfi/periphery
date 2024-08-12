// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IDefaultCollateralMigrator} from "src/interfaces/IDefaultCollateralMigrator.sol";

import {IDefaultCollateral} from "@symbiotic/collateral/interfaces/defaultCollateral/IDefaultCollateral.sol";
import {IVault} from "@symbiotic/core/interfaces/vault/IVault.sol";

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract DefaultCollateralMigrator is IDefaultCollateralMigrator {
    using SafeERC20 for IERC20;

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
        if (IERC20(asset).allowance(address(this), vault) < amount) {
            IERC20(asset).forceApprove(vault, type(uint256).max);
        }
        return IVault(vault).deposit(onBehalfOf, amount);
    }
}
