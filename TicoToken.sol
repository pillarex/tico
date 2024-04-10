// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20CappedUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./Timelock.sol";

/**
 *@title Tico Token Contract
 *@dev This contract extends ERC20, Timelock, Pausable and UUPS upgrades functionality
 */

contract TicoToken is ERC20CappedUpgradeable, UUPSUpgradeable {
    /**
     *@dev Blacklist mapping that stores the addresses which are blacklisted
     */
    mapping(address => bool) public blacklist;

    /**
     *@notice Gnosis Safe address that has specific management rights over this contract
     */
    address public gnosisSafe;

    /**
     *@notice Gnosis Safe address that has specific minting use only
     */
    address public gnosisSafeForMinting;

    /**
     *@notice timelock address that has specific features used for timelock functions
     */
    address public timelock;

    /**
     *@dev Custom error when user tries to mint zero amount
     *@notice You will encounter this error if the minting amount is zero
     */
    error ZeroAmountCannotBeMinted();

    /**
     *@dev Custom error when a user tries to transfer from/to a blacklisted address
     *@notice You will encounter this error if the sender or recipient is blacklisted
     */
    error BlacklistedAddressTransfer();

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
     *@dev Custom error when a user other than the assigned timelock tries to execute the function
     *@notice You will encounter this error if the function is not called by the assigned gnosisSafe
     */
    error NotTimelock();

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
        __ERC20Capped_init(10000000000 * 10 ** decimals());
        __UUPSUpgradeable_init();
        address[] memory gnosisSafeArray = new address[](1);
        gnosisSafeArray[0] = _gnosisSafe;
        Timelock timelockContract = new Timelock();
        timelockContract.initializeTimelock(
            600,
            gnosisSafeArray,
            gnosisSafeArray
        );
        timelock = address(timelockContract);
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
     *@dev Modifier that restricts blacklisted account transfers
     *@param from Sender address
     *@param to Recipient address
     */
    modifier beforeTokenTransfer(address from, address to) {
        if (blacklist[from] || blacklist[to])
            revert BlacklistedAddressTransfer();
        _;
    }

    /**
     *@dev Modifier that restricts functions to be accessed from timelock only
     */
    modifier onlyTimelock() {
        if (_msgSender() != timelock) revert NotTimelock();
        _;
    }

    /**
     *@dev Internal function to authorize upgrades to the contract.
     *@param newImplementation Address of the new contract implementation
     */
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyTimelock() {}

    /**
     *@notice Function to mint new tokens to the specified address. This function can only be executed when the contract is not paused.
     *@param to Recipient address
     *@param amount Amount of tokens to mint
     */
    function mint(
        address to,
        uint256 amount
    ) external onlyGnosisSafeForMinting beforeTokenTransfer(_msgSender(), to) {
        if (to == address(0)) revert ZeroAddress();
        if (amount == 0) revert ZeroAmountCannotBeMinted();
        _mint(to, amount);
    }

    /**
     *@notice Function to transfer tokens from caller's account to the specified address. This can only be executed when the contract is not paused.
     *@param to Recipient address
     *@param value Amount of tokens to transfer
     *@return true upon successful execution
     */
    function transfer(
        address to,
        uint256 value
    ) public override beforeTokenTransfer(_msgSender(), to) returns (bool) {
        if (to == address(0)) revert ZeroAddress();
        _transfer(_msgSender(), to, value);
        return true;
    }

    /**
     *@notice Function to approve the specified address to spend the caller’s tokens. This can only be executed when the contract is not paused.
     *@param spender Address to be approved
     *@param value Amount of tokens to be approved
     *@return true upon successful execution
     */
    function approve(
        address spender,
        uint256 value
    )
        public
        override
        beforeTokenTransfer(_msgSender(), spender)
        returns (bool)
    {
        if (spender == address(0)) revert ZeroAddress();
        _approve(_msgSender(), spender, value);
        return true;
    }

    /**
     *@dev Function allows the specified spender to transfer tokens from a specified address to another address. This can only be executed when the contract is not paused.
     *@param from Sender address
     *@param to Recipient address
     *@param value Amount of tokens to transfer
     *@return Boolean value indicating success
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public override beforeTokenTransfer(from, to) returns (bool) {
        if (from == address(0) || to == address(0)) revert ZeroAddress();
        _spendAllowance(from, _msgSender(), value);
        _transfer(from, to, value);
        return true;
    }

    /**
     *@dev Function to blacklist an address. Only executable by the Gnosis Safe.
     *@param _address Address to be blacklisted
     */
    function blacklistAddress(address _address) external onlyGnosisSafe {
        if (_address == address(0)) revert ZeroAddress();
        blacklist[_address] = true;
    }

    /**
     *@dev Function to remove an address from the blacklist. Only executable by the Gnosis Safe.
     *@param _address Address to be removed from the blacklist
     */
    function whitelistAddress(address _address) external onlyGnosisSafe {
        if (_address == address(0)) revert ZeroAddress();
        blacklist[_address] = false;
    }

    /**
     *@notice This function allows to change the Gnosis Safe address.
     *@dev Only the current Gnosis Safe can execute this function.
     *@param newGnosisSafe The address of the new Gnosis Safe.
     */
    function changeGnosisSafe(
        address newGnosisSafe
    ) external onlyTimelock {
        if (newGnosisSafe == address(0)) revert ZeroAddress();

        gnosisSafe = newGnosisSafe;
    }

    /**
     *@notice This function allows to change the Gnosis Safe for Minting address.
     *@dev Only the current Gnosis Safe for Minting can execute this function.
     *@param newGnosisSafeForMinting The address of the new Gnosis Safe for Minting.
     */
    function changeGnosisSafeForMinting(
        address newGnosisSafeForMinting
    ) external  onlyTimelock {
        if (newGnosisSafeForMinting == address(0)) revert ZeroAddress();

        gnosisSafeForMinting = newGnosisSafeForMinting;
    }

    /**
     *@notice This function allows to change the timelock address.
     *@dev Only the current Gnosis Safe  can execute this function.
     *@param newTimeLock The address of the new timelock.
     */
    function changeTimelock(
        address newTimeLock
    ) external  onlyGnosisSafe {
        if (newTimeLock == address(0)) revert ZeroAddress();
        timelock = newTimeLock;
    }
}
