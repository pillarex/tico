// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20CappedUpgradeable.sol";

/**
 *@title Tico Token Contract
 *@dev This contract extends ERC20
 */

contract TicoToken is ERC20CappedUpgradeable {
    /**
     *@notice Gnosis Safe address that has specific management rights over this contract
     */
    address public gnosisSafe;

    /**
     *@notice Gnosis Safe address that has specific minting use only
     */
    address public gnosisSafeForMinting;

    /**
     *@dev Custom error when user tries to mint zero amount
     *@notice You will encounter this error if the minting amount is zero
     */
    error ZeroAmountCannotBeMinted();

    /**
     *@dev Custom error when a user other than the assigned gnosisSafeForMinting tries to mint tokens
     *@notice You will encounter this error if the minter is not the assigned gnosisSafeForMinting
     */
    error NotGnosisSafeMinter();

    /**
     *@dev Custom error when a user other than the assigned gnosisSafe tries to execute the function
     *@notice You will encounter this error if the function is not called by the assigned gnosisSafe
     */
    error NotGnosisSafe();

    /**
     *@notice Custom Error to throw in case new Gnosis Safe address is the zero address.
     */
    error ZeroAddress();

    /**
     *@notice Initialize function to setup the token and its configurations including cap, name, symbol and setting up the Gnosis Safe
     *@param _gnosisSafe Address of the Gnosis Safe
     *@param _gnosisSafeForMinting Address of the Gnosis Safe for minting purpose
     */

    function initialize(
        address _gnosisSafe,
        address _gnosisSafeForMinting
    ) public initializer {
        __ERC20_init("Tico", "TICO");
        __ERC20Capped_init(10_000_000_000 * 10 ** decimals());
        gnosisSafe = _gnosisSafe;
        gnosisSafeForMinting = _gnosisSafeForMinting;
    }

    /**
     *@dev Modifier that restricts function access to the Gnosis Safe address only.
     */
    modifier onlyGnosisSafe() {
        if (_msgSender() != gnosisSafe) revert NotGnosisSafe();
        _;
    }

    /**
     *@dev Modifier that restricts function access to the Gnosis Safe Minter address only.
     */
    modifier onlyGnosisSafeForMinting() {
        if (_msgSender() != gnosisSafeForMinting) revert NotGnosisSafeMinter();
        _;
    }

    /**
     *@notice Function to mint new tokens to the specified address. This function can only be executed when the contract is not paused.
     *@param to Recipient address
     *@param amount Amount of tokens to mint
     */
    function mint(
        address to,
        uint256 amount
    ) public onlyGnosisSafeForMinting {
        if (to == address(0)) revert ZeroAddress();
        if (amount == 0) revert ZeroAmountCannotBeMinted();
        _mint(to, amount);
    }

    /**
     *@notice This function allows to change the Gnosis Safe address.
     *@dev Only the current Gnosis Safe can execute this function.
     *@param newGnosisSafe The address of the new Gnosis Safe.
     */
    function changeGnosisSafe(
        address newGnosisSafe
    ) public onlyGnosisSafe {
        if (newGnosisSafe == address(0)) revert ZeroAddress();

        gnosisSafe = newGnosisSafe;
    }

    /**
     *@notice This function allows to change the Gnosis Safe for Minting address.
     *@dev Only the current Gnosis Safe can execute this function.
     *@param newGnosisSafeForMinting The address of the new Gnosis Safe for Minting.
     */
    function changeGnosisSafeForMinting(
        address newGnosisSafeForMinting
    ) public onlyGnosisSafe {
        if (newGnosisSafeForMinting == address(0)) revert ZeroAddress();

        gnosisSafeForMinting = newGnosisSafeForMinting;
    }
}
