// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test, console2} from "forge-std/Test.sol";

import {DefaultCollateralMigrator} from "src/contracts/DefaultCollateralMigrator.sol";

import {DefaultCollateralFactory} from "@symbiotic/collateral/contracts/defaultCollateral/DefaultCollateralFactory.sol";
import {DefaultCollateral} from "@symbiotic/collateral/contracts/defaultCollateral/DefaultCollateral.sol";

import {VaultFactory} from "@symbiotic/core/contracts/VaultFactory.sol";
import {DelegatorFactory} from "@symbiotic/core/contracts/DelegatorFactory.sol";
import {SlasherFactory} from "@symbiotic/core/contracts/SlasherFactory.sol";
import {NetworkRegistry} from "@symbiotic/core/contracts/NetworkRegistry.sol";
import {OperatorRegistry} from "@symbiotic/core/contracts/OperatorRegistry.sol";
import {MetadataService} from "@symbiotic/core/contracts/service/MetadataService.sol";
import {NetworkMiddlewareService} from "@symbiotic/core/contracts/service/NetworkMiddlewareService.sol";
import {OptInService} from "@symbiotic/core/contracts/service/OptInService.sol";

import {Vault} from "@symbiotic/core/contracts/vault/Vault.sol";
import {NetworkRestakeDelegator} from "@symbiotic/core/contracts/delegator/NetworkRestakeDelegator.sol";
import {FullRestakeDelegator} from "@symbiotic/core/contracts/delegator/FullRestakeDelegator.sol";
import {Slasher} from "@symbiotic/core/contracts/slasher/Slasher.sol";
import {VetoSlasher} from "@symbiotic/core/contracts/slasher/VetoSlasher.sol";

import {Token} from "@symbiotic/core/mocks/Token.sol";
import {FeeOnTransferToken} from "@symbiotic/core/mocks/FeeOnTransferToken.sol";
import {VaultConfigurator, IVaultConfigurator} from "@symbiotic/core/contracts/VaultConfigurator.sol";
import {IVault} from "@symbiotic/core/interfaces/IVaultConfigurator.sol";
import {INetworkRestakeDelegator} from "@symbiotic/core/interfaces/delegator/INetworkRestakeDelegator.sol";
import {IBaseDelegator} from "@symbiotic/core/interfaces/delegator/IBaseDelegator.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DefaultCollateralMigratorTest is Test {
    address owner;
    address alice;
    uint256 alicePrivateKey;
    address bob;
    uint256 bobPrivateKey;

    DefaultCollateralFactory defaultCollateralFactory;

    DefaultCollateral collateral;
    DefaultCollateral feeOnTransferCollateral;

    VaultFactory vaultFactory;
    DelegatorFactory delegatorFactory;
    SlasherFactory slasherFactory;
    NetworkRegistry networkRegistry;
    OperatorRegistry operatorRegistry;
    MetadataService operatorMetadataService;
    MetadataService networkMetadataService;
    NetworkMiddlewareService networkMiddlewareService;
    OptInService operatorVaultOptInService;
    OptInService operatorNetworkOptInService;

    VaultConfigurator vaultConfigurator;

    Vault vault;
    FullRestakeDelegator delegator;
    Slasher slasher;

    Vault vaultFeeOnTransfer;
    FullRestakeDelegator delegatorFeeOnTransfer;
    Slasher slasherFeeOnTransfer;

    DefaultCollateralMigrator defaultCollateralMigrator;

    function setUp() public {
        owner = address(this);
        (alice, alicePrivateKey) = makeAddrAndKey("alice");
        (bob, bobPrivateKey) = makeAddrAndKey("bob");

        vaultFactory = new VaultFactory(owner);
        delegatorFactory = new DelegatorFactory(owner);
        slasherFactory = new SlasherFactory(owner);
        networkRegistry = new NetworkRegistry();
        operatorRegistry = new OperatorRegistry();
        operatorMetadataService = new MetadataService(address(operatorRegistry));
        networkMetadataService = new MetadataService(address(networkRegistry));
        networkMiddlewareService = new NetworkMiddlewareService(address(networkRegistry));
        operatorVaultOptInService = new OptInService(address(operatorRegistry), address(vaultFactory));
        operatorNetworkOptInService = new OptInService(address(operatorRegistry), address(networkRegistry));

        address vaultImpl =
            address(new Vault(address(delegatorFactory), address(slasherFactory), address(vaultFactory)));
        vaultFactory.whitelist(vaultImpl);

        address networkRestakeDelegatorImpl = address(
            new NetworkRestakeDelegator(
                address(networkRegistry),
                address(vaultFactory),
                address(operatorVaultOptInService),
                address(operatorNetworkOptInService),
                address(delegatorFactory),
                delegatorFactory.totalTypes()
            )
        );
        delegatorFactory.whitelist(networkRestakeDelegatorImpl);

        address fullRestakeDelegatorImpl = address(
            new FullRestakeDelegator(
                address(networkRegistry),
                address(vaultFactory),
                address(operatorVaultOptInService),
                address(operatorNetworkOptInService),
                address(delegatorFactory),
                delegatorFactory.totalTypes()
            )
        );
        delegatorFactory.whitelist(fullRestakeDelegatorImpl);

        address slasherImpl = address(
            new Slasher(
                address(vaultFactory),
                address(networkMiddlewareService),
                address(slasherFactory),
                slasherFactory.totalTypes()
            )
        );
        slasherFactory.whitelist(slasherImpl);

        address vetoSlasherImpl = address(
            new VetoSlasher(
                address(vaultFactory),
                address(networkMiddlewareService),
                address(networkRegistry),
                address(slasherFactory),
                slasherFactory.totalTypes()
            )
        );
        slasherFactory.whitelist(vetoSlasherImpl);

        vaultConfigurator =
            new VaultConfigurator(address(vaultFactory), address(delegatorFactory), address(slasherFactory));

        Token token = new Token("Token");
        FeeOnTransferToken feeOnTransferToken = new FeeOnTransferToken("FeeOnTransferToken");

        defaultCollateralFactory = new DefaultCollateralFactory();

        address defaultCollateralAddress =
            defaultCollateralFactory.create(address(token), type(uint256).max, address(0));
        collateral = DefaultCollateral(defaultCollateralAddress);

        defaultCollateralAddress =
            defaultCollateralFactory.create(address(feeOnTransferToken), type(uint256).max, address(0));
        feeOnTransferCollateral = DefaultCollateral(defaultCollateralAddress);

        token.approve(address(collateral), type(uint256).max);

        collateral.deposit(address(this), 1000 * 1e18);

        feeOnTransferToken.approve(address(feeOnTransferCollateral), type(uint256).max);

        feeOnTransferCollateral.deposit(address(this), 1000 * 1e18);

        uint48 epochDuration = 1;
        vault = _getVault(epochDuration);

        address[] memory networkLimitSetRoleHolders = new address[](1);
        networkLimitSetRoleHolders[0] = alice;
        address[] memory operatorNetworkSharesSetRoleHolders = new address[](1);
        operatorNetworkSharesSetRoleHolders[0] = alice;
        (address vault_,,) = vaultConfigurator.create(
            IVaultConfigurator.InitParams({
                version: vaultFactory.lastVersion(),
                owner: alice,
                vaultParams: IVault.InitParams({
                    collateral: address(feeOnTransferToken),
                    delegator: address(0),
                    slasher: address(0),
                    burner: address(0xdEaD),
                    epochDuration: epochDuration,
                    depositWhitelist: false,
                    defaultAdminRoleHolder: alice,
                    depositWhitelistSetRoleHolder: alice,
                    depositorWhitelistRoleHolder: alice
                }),
                delegatorIndex: 0,
                delegatorParams: abi.encode(
                    INetworkRestakeDelegator.InitParams({
                        baseParams: IBaseDelegator.BaseParams({
                            defaultAdminRoleHolder: alice,
                            hook: address(0),
                            hookSetRoleHolder: alice
                        }),
                        networkLimitSetRoleHolders: networkLimitSetRoleHolders,
                        operatorNetworkSharesSetRoleHolders: operatorNetworkSharesSetRoleHolders
                    })
                ),
                withSlasher: false,
                slasherIndex: 0,
                slasherParams: ""
            })
        );

        vaultFeeOnTransfer = Vault(vault_);

        defaultCollateralMigrator = new DefaultCollateralMigrator();
    }

    function test_Migrate(uint256 amount) public {
        amount = bound(amount, 1, 1000 * 1e18);

        uint256 balanceBeforeCollateralThis = collateral.balanceOf(address(this));
        uint256 balanceBeforeCollateralVault = collateral.balanceOf(address(vault));
        uint256 balanceBeforeCollateralMigrator = collateral.balanceOf(address(defaultCollateralMigrator));
        uint256 balanceBeforeAssetThis = IERC20(collateral.asset()).balanceOf(address(this));
        uint256 balanceBeforeAssetVault = IERC20(collateral.asset()).balanceOf(address(vault));
        uint256 balanceBeforeAssetMigrator = IERC20(collateral.asset()).balanceOf(address(defaultCollateralMigrator));

        assertEq(vault.balanceOf(address(this)), 0);

        collateral.approve(address(defaultCollateralMigrator), amount);
        defaultCollateralMigrator.migrate(address(collateral), address(vault), address(this), amount);

        assertEq(balanceBeforeCollateralThis - collateral.balanceOf(address(this)), amount);
        assertEq(collateral.balanceOf(address(vault)) - balanceBeforeCollateralVault, 0);
        assertEq(collateral.balanceOf(address(defaultCollateralMigrator)) - balanceBeforeCollateralMigrator, 0);
        assertEq(IERC20(collateral.asset()).balanceOf(address(this)) - balanceBeforeAssetThis, 0);
        assertEq(IERC20(collateral.asset()).balanceOf(address(vault)) - balanceBeforeAssetVault, amount);
        assertEq(
            IERC20(collateral.asset()).balanceOf(address(defaultCollateralMigrator)) - balanceBeforeAssetMigrator, 0
        );

        assertEq(vault.balanceOf(address(this)), amount);
    }

    function test_MigrateFeeOnTransferToken(uint256 amount) public {
        amount = bound(amount, 3, 500 * 1e18);

        uint256 balanceBeforeCollateralThis = feeOnTransferCollateral.balanceOf(address(this));
        uint256 balanceBeforeCollateralVault = feeOnTransferCollateral.balanceOf(address(vaultFeeOnTransfer));
        uint256 balanceBeforeCollateralMigrator = feeOnTransferCollateral.balanceOf(address(defaultCollateralMigrator));
        uint256 balanceBeforeAssetThis = IERC20(feeOnTransferCollateral.asset()).balanceOf(address(this));
        uint256 balanceBeforeAssetVault = IERC20(feeOnTransferCollateral.asset()).balanceOf(address(vaultFeeOnTransfer));
        uint256 balanceBeforeAssetMigrator =
            IERC20(feeOnTransferCollateral.asset()).balanceOf(address(defaultCollateralMigrator));

        assertEq(vaultFeeOnTransfer.balanceOf(address(this)), 0);

        feeOnTransferCollateral.approve(address(defaultCollateralMigrator), amount);
        defaultCollateralMigrator.migrate(
            address(feeOnTransferCollateral), address(vaultFeeOnTransfer), address(this), amount
        );

        assertEq(balanceBeforeCollateralThis - feeOnTransferCollateral.balanceOf(address(this)), amount);
        assertEq(feeOnTransferCollateral.balanceOf(address(vaultFeeOnTransfer)) - balanceBeforeCollateralVault, 0);
        assertEq(
            feeOnTransferCollateral.balanceOf(address(defaultCollateralMigrator)) - balanceBeforeCollateralMigrator, 0
        );
        assertEq(IERC20(feeOnTransferCollateral.asset()).balanceOf(address(this)) - balanceBeforeAssetThis, 0);
        assertEq(
            IERC20(feeOnTransferCollateral.asset()).balanceOf(address(vaultFeeOnTransfer)) - balanceBeforeAssetVault,
            amount - 2
        );
        assertEq(
            IERC20(feeOnTransferCollateral.asset()).balanceOf(address(defaultCollateralMigrator))
                - balanceBeforeAssetMigrator,
            0
        );

        assertEq(vaultFeeOnTransfer.balanceOf(address(this)), amount - 2);
    }

    function _getVault(uint48 epochDuration) internal returns (Vault) {
        address[] memory networkLimitSetRoleHolders = new address[](1);
        networkLimitSetRoleHolders[0] = alice;
        address[] memory operatorNetworkSharesSetRoleHolders = new address[](1);
        operatorNetworkSharesSetRoleHolders[0] = alice;
        (address vault_,,) = vaultConfigurator.create(
            IVaultConfigurator.InitParams({
                version: vaultFactory.lastVersion(),
                owner: alice,
                vaultParams: IVault.InitParams({
                    collateral: address(collateral.asset()),
                    delegator: address(0),
                    slasher: address(0),
                    burner: address(0xdEaD),
                    epochDuration: epochDuration,
                    depositWhitelist: false,
                    defaultAdminRoleHolder: alice,
                    depositWhitelistSetRoleHolder: alice,
                    depositorWhitelistRoleHolder: alice
                }),
                delegatorIndex: 0,
                delegatorParams: abi.encode(
                    INetworkRestakeDelegator.InitParams({
                        baseParams: IBaseDelegator.BaseParams({
                            defaultAdminRoleHolder: alice,
                            hook: address(0),
                            hookSetRoleHolder: alice
                        }),
                        networkLimitSetRoleHolders: networkLimitSetRoleHolders,
                        operatorNetworkSharesSetRoleHolders: operatorNetworkSharesSetRoleHolders
                    })
                ),
                withSlasher: false,
                slasherIndex: 0,
                slasherParams: ""
            })
        );

        return Vault(vault_);
    }
}