// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDefaultCollateral is IERC20 {
    /**
     * @notice Get the collateral's underlying asset.
     * @return asset address of the underlying asset
     */
    function asset() external view returns (address);

    /**
     * @notice Get a maximum possible collateral total supply.
     * @return maximum collateral total supply
     */
    function limit() external view returns (uint256);

    /**
     * @notice Get an address of the limit increaser.
     * @return address of the limit increaser
     */
    function limitIncreaser() external view returns (address);

    /**
     * @notice Deposit a given amount of the underlying asset, and mint the collateral to a particular recipient.
     * @param recipient address of the collateral's recipient
     * @param amount amount of the underlying asset
     * @return amount of the collateral minted
     */
    function deposit(address recipient, uint256 amount) external returns (uint256);

    /**
     * @notice Deposit a given amount of the underlying asset using a permit functionality, and mint the collateral to a particular recipient.
     * @param recipient address of the collateral's recipient
     * @param amount amount of the underlying asset
     * @param deadline timestamp of the signature's deadline
     * @param v v component of the signature
     * @param r r component of the signature
     * @param s s component of the signature
     * @return amount of the collateral minted
     */
    function deposit(
        address recipient,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256);

    /**
     * @notice Withdraw a given amount of the underlying asset, and transfer it to a particular recipient.
     * @param recipient address of the underlying asset's recipient
     * @param amount amount of the underlying asset
     */
    function withdraw(address recipient, uint256 amount) external;

    /**
     * @notice Increase a limit of maximum collateral total supply.
     * @param amount amount to increase the limit by
     * @dev Called only by limitIncreaser.
     */
    function increaseLimit(
        uint256 amount
    ) external;

    /**
     * @notice Set a new limit increaser.
     * @param limitIncreaser address of the new limit increaser
     * @dev Called only by limitIncreaser.
     */
    function setLimitIncreaser(
        address limitIncreaser
    ) external;
}
