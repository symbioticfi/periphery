// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

interface IDefaultCollateralMigrator {
    /**
     * @notice Unwrap a particular default collateral and deposit its underlying asset to a given vault.
     * @param collateral address of the default collateral to unwrap
     * @param vault address of the vault to deposit the collateral's underlying asset
     * @param amount amount of the default collateral to unwrap and deposit
     */
    function depositDefaultCollateralToVault(address collateral, address vault, uint256 amount) external;
}
