// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IDefaultCollateralMigrator} from "src/interfaces/IDefaultCollateralMigrator.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IDefaultCollateral} from "@symbiotic/collateral/interfaces/defaultCollateral/IDefaultCollateral.sol";
import {IVault} from "@symbiotic/core/interfaces/vault/IVault.sol";

contract DefaultCollateralMigrator is IDefaultCollateralMigrator {
    /**
     * @inheritdoc IDefaultCollateralMigrator
     */
    function depositDefaultCollateralToVault(address collateral, address vault, uint256 amount) external {
        IERC20(collateral).transferFrom(msg.sender, address(this), amount);
        IDefaultCollateral(collateral).withdraw(address(this), amount);

        address asset = IDefaultCollateral(collateral).asset();
        IERC20(asset).approve(vault, amount);
        IVault(vault).deposit(msg.sender, amount);
    }
}
