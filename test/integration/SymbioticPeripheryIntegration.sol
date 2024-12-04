// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@symbioticfi/core/test/integration/SymbioticCoreIntegration.sol";
import "@symbioticfi/collateral/test/integration/SymbioticCollateralIntegration.sol";

import "./SymbioticPeripheryInit.sol";

contract SymbioticPeripheryIntegration is
    SymbioticPeripheryInit,
    SymbioticCoreIntegration,
    SymbioticCollateralIntegration
{
    function setUp()
        public
        virtual
        override(SymbioticPeripheryInit, SymbioticCoreIntegration, SymbioticCollateralIntegration)
    {
        SymbioticCollateralIntegration.setUp();
        SymbioticCoreIntegration.setUp();

        _initPeriphery_SymbioticPeriphery(SYMBIOTIC_PERIPHERY_USE_EXISTING_DEPLOYMENT);
    }

    function _addPossibleTokens_SymbioticCore() internal virtual override {
        for (uint256 i; i < tokens_SymbioticCollateral.length; ++i) {
            tokens_SymbioticCore.push(tokens_SymbioticCollateral[i]);
        }
    }
}
