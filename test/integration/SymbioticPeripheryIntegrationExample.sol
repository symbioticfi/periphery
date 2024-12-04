// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SymbioticPeripheryIntegration.sol";

import {console2} from "forge-std/Test.sol";

contract SymbioticPeripheryIntegrationExample is SymbioticPeripheryIntegration {
    function setUp() public override {
        SYMBIOTIC_CORE_PROJECT_ROOT = "lib/core/";
        SYMBIOTIC_COLLATERAL_PROJECT_ROOT = "lib/collateral/";
        SYMBIOTIC_PERIPHERY_PROJECT_ROOT = "";
        // vm.selectFork(vm.createFork(vm.rpcUrl("holesky")));
        // SYMBIOTIC_INIT_BLOCK = 2_727_202;
        // SYMBIOTIC_COLLATERAL_USE_EXISTING_DEPLOYMENT = true;
        // SYMBIOTIC_CORE_USE_EXISTING_DEPLOYMENT = true;

        SYMBIOTIC_CORE_NUMBER_OF_STAKERS = 5;
        SYMBIOTIC_COLLATERAL_NUMBER_OF_STAKERS = 10;

        super.setUp();
    }

    function test_Migration() public {
        for (uint256 i; i < defaultCollaterals_SymbioticCollateral.length; ++i) {
            for (uint256 j; j < vaults_SymbioticCore.length; ++j) {
                if (
                    ISymbioticDefaultCollateral(defaultCollaterals_SymbioticCollateral[i]).asset()
                        != ISymbioticVault(vaults_SymbioticCore[j]).collateral()
                ) {
                    continue;
                }
                for (uint256 k; k < stakers_SymbioticCollateral.length; ++k) {
                    console2.log("Staker:", stakers_SymbioticCollateral[k].addr);
                    console2.log(
                        "Balance before migration:",
                        ISymbioticVault(vaults_SymbioticCore[j]).activeBalanceOf(stakers_SymbioticCollateral[k].addr)
                    );
                    _stakerMigrateRandom_SymbioticPeriphery(
                        stakers_SymbioticCollateral[k].addr,
                        defaultCollaterals_SymbioticCollateral[i],
                        vaults_SymbioticCore[j]
                    );
                    console2.log(
                        "Balance after migration:",
                        ISymbioticVault(vaults_SymbioticCore[j]).activeBalanceOf(stakers_SymbioticCollateral[k].addr)
                    );
                }
            }
        }
    }
}
