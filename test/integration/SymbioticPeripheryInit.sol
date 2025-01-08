// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@symbioticfi/core/test/integration/SymbioticCoreInit.sol";
import "@symbioticfi/collateral/test/integration/SymbioticCollateralInit.sol";

import "./SymbioticPeripheryImports.sol";

import {SymbioticPeripheryConstants} from "./SymbioticPeripheryConstants.sol";
import {SymbioticPeripheryBindings} from "./SymbioticPeripheryBindings.sol";

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

contract SymbioticPeripheryInit is SymbioticCoreInit, SymbioticCollateralInit, SymbioticPeripheryBindings {
    using SafeERC20 for IERC20;
    using Math for uint256;

    // General config

    string public SYMBIOTIC_PERIPHERY_PROJECT_ROOT = "";
    bool public SYMBIOTIC_PERIPHERY_USE_EXISTING_DEPLOYMENT = false;

    // Staker-related config

    uint256 public SYMBIOTIC_PERIPHERY_MIN_TOKENS_TO_MIGRATE_TIMES_1e18 = 0.001 * 1e18;
    uint256 public SYMBIOTIC_PERIPHERY_MAX_TOKENS_TO_MIGRATE_TIMES_1e18 = 10_000 * 1e18;

    ISymbioticDefaultCollateralMigrator public symbioticDefaultCollateralMigrator;

    function setUp() public virtual override(SymbioticCoreInit, SymbioticCollateralInit) {
        SymbioticCollateralInit.setUp();
        SymbioticCoreInit.setUp();

        _initPeriphery_SymbioticPeriphery(SYMBIOTIC_PERIPHERY_USE_EXISTING_DEPLOYMENT);
    }

    // ------------------------------------------------------------ GENERAL HELPERS ------------------------------------------------------------ //

    function _initPeriphery_SymbioticPeriphery() internal virtual {
        symbioticDefaultCollateralMigrator = SymbioticPeripheryConstants.defaultCollateralMigrator();
    }

    function _initPeriphery_SymbioticPeriphery(
        bool useExisting
    ) internal virtual {
        if (useExisting) {
            _initPeriphery_SymbioticPeriphery();
        } else {
            symbioticDefaultCollateralMigrator = ISymbioticDefaultCollateralMigrator(
                deployCode(
                    string.concat(
                        SYMBIOTIC_PERIPHERY_PROJECT_ROOT,
                        "out/DefaultCollateralMigrator.sol/DefaultCollateralMigrator.json"
                    )
                )
            );
        }
    }

    // ------------------------------------------------------------ STAKER-RELATED HELPERS ------------------------------------------------------------ //

    function _stakerMigrate_SymbioticPeriphery(
        address staker,
        address defaultCollateral,
        address vault,
        uint256 amount
    ) internal virtual {
        _migrate_SymbioticPeriphery(
            symbioticDefaultCollateralMigrator, staker, defaultCollateral, vault, staker, amount
        );
    }

    function _stakerMigrateRandom_SymbioticPeriphery(
        address staker,
        address defaultCollateral,
        address vault
    ) internal virtual {
        address asset = ISymbioticVault(vault).collateral();

        if (ISymbioticVault(vault).depositWhitelist()) {
            return;
        }

        uint256 minAmount = _normalizeForToken_Symbiotic(SYMBIOTIC_PERIPHERY_MIN_TOKENS_TO_MIGRATE_TIMES_1e18, asset);
        uint256 maxAmount = Math.min(
            _normalizeForToken_Symbiotic(SYMBIOTIC_PERIPHERY_MAX_TOKENS_TO_MIGRATE_TIMES_1e18, asset),
            IERC20(defaultCollateral).balanceOf(staker)
        );

        if (maxAmount >= minAmount) {
            uint256 amount = _randomWithBounds_Symbiotic(minAmount, maxAmount);

            if (ISymbioticVault(vault).isDepositLimit()) {
                uint256 depositLimit = ISymbioticVault(vault).depositLimit();
                uint256 activeStake = ISymbioticVault(vault).activeStake();
                amount = Math.min(depositLimit - Math.min(activeStake, depositLimit), amount);
            }

            if (amount >= minAmount) {
                _stakerMigrate_SymbioticPeriphery(staker, defaultCollateral, vault, amount);
            }
        }
    }
}
