// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SymbioticPeripheryImports.sol";

library SymbioticPeripheryConstants {
    function defaultCollateralMigrator() internal view returns (ISymbioticDefaultCollateralMigrator) {
        if (block.chainid == 1) {
            // mainnet
            return ISymbioticDefaultCollateralMigrator(0x8F152FEAA99eb6656F902E94BD4E7bCf563D4A43);
        } else if (block.chainid == 17_000) {
            // holesky
            return ISymbioticDefaultCollateralMigrator(0x1779C2277A61506b5BaB03Ab24782B8f5Bb6B287);
        } else if (block.chainid == 11_155_111) {
            // sepolia
            return ISymbioticDefaultCollateralMigrator(0xD6BE794b3761fd2bA23fB054F1Fe1606Ae35de4e);
        } else {
            revert("SymbioticPeripheryConstants.defaultCollateralMigrator(): chainid not supported");
        }
    }
}
