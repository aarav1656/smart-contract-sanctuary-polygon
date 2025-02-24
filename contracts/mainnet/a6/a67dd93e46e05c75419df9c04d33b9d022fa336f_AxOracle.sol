/**
 *Submitted for verification at polygonscan.com on 2022-07-26
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.2;

interface ManagementList {
    function isManager(address accountAddress) external returns (bool);
}

contract Manageable {
    ManagementList public managementList;

    constructor(address _managementListAddress) {
        managementList = ManagementList(_managementListAddress);
    }

    modifier onlyManagers() {
        bool isManager = managementList.isManager(msg.sender);
        require(isManager, "ManagementList: caller is not a manager");
        _;
    }
}

interface IERC20 {
    function decimals() external view returns (uint8);
}

contract AxOracle is Manageable {
    address[] private _calculations;
    address public usdcAddress;
    mapping(address => address) public tokenAliases;

    event TokenAliasAdded(address tokenAddress, address tokenAliasAddress);
    event TokenAliasRemoved(address tokenAddress);

    struct TokenAlias {
        address tokenAddress;
        address tokenAliasAddress;
    }

    constructor(address _managementListAddress, address _usdcAddress)
        Manageable(_managementListAddress)
    {
        usdcAddress = _usdcAddress;
    }

    /**
     * The oracle supports an array of calculation contracts. Each calculation contract must implement getPriceUsdc().
     * When setting calculation contracts all calculations must be set at the same time (we intentionally do not support for adding/removing calculations).
     * The order of calculation contracts matters as it determines the order preference in the cascading fallback mechanism.
     */
    function setCalculations(address[] memory calculationAddresses)
        external
        onlyManagers
    {
        _calculations = calculationAddresses;
    }

    function calculations() external view returns (address[] memory) {
        return (_calculations);
    }

    function addTokenAlias(address tokenAddress, address tokenAliasAddress)
        public
        onlyManagers
    {
        tokenAliases[tokenAddress] = tokenAliasAddress;
        emit TokenAliasAdded(tokenAddress, tokenAliasAddress);
    }

    function addTokenAliases(TokenAlias[] memory _tokenAliases)
        public
        onlyManagers
    {
        for (uint256 i = 0; i < _tokenAliases.length; i++) {
            addTokenAlias(
                _tokenAliases[i].tokenAddress,
                _tokenAliases[i].tokenAliasAddress
            );
        }
    }

    function removeTokenAlias(address tokenAddress) public onlyManagers {
        delete tokenAliases[tokenAddress];
        emit TokenAliasRemoved(tokenAddress);
    }

    function getNormalizedValueUsdc(
        address tokenAddress,
        uint256 amount,
        uint256 priceUsdc
    ) public view returns (uint256) {
        IERC20 token = IERC20(tokenAddress);
        uint256 tokenDecimals = token.decimals();

        uint256 usdcDecimals = 6;
        uint256 decimalsAdjustment;
        if (tokenDecimals >= usdcDecimals) {
            decimalsAdjustment = tokenDecimals - usdcDecimals;
        } else {
            decimalsAdjustment = usdcDecimals - tokenDecimals;
        }
        uint256 value;
        if (decimalsAdjustment > 0) {
            value =
                (amount * priceUsdc * (10**decimalsAdjustment)) /
                10**(decimalsAdjustment + tokenDecimals);
        } else {
            value = (amount * priceUsdc) / 10**usdcDecimals;
        }
        return value;
    }

    function getNormalizedValueUsdc(address tokenAddress, uint256 amount)
        external
        view
        returns (uint256)
    {
        uint256 priceUsdc = getPriceUsdcRecommended(tokenAddress);
        return getNormalizedValueUsdc(tokenAddress, amount, priceUsdc);
    }

    function getPriceUsdcRecommended(address tokenAddress)
        public
        view
        returns (uint256)
    {
        address tokenAddressAlias = tokenAliases[tokenAddress];
        address tokenToQuery = tokenAddress;
        if (tokenAddressAlias != address(0)) {
            tokenToQuery = tokenAddressAlias;
        }
        (bool success, bytes memory data) =
            address(this).staticcall(
                abi.encodeWithSignature("getPriceUsdc(address)", tokenToQuery)
            );
        if (success) {
            return abi.decode(data, (uint256));
        }
        return 0;
    }

    /**
     * Cascading fallback proxy
     *
     * Loop through all contracts in _calculations and attempt to forward the method call to each underlying contract.
     * This allows users to call getPriceUsdc() on the oracle contract and the result of the first non-reverting contract that
     * implements getPriceUsdc() will be returned.
     *
     * This mechanism also exposes all public methods for calculation contracts. This allows a user to
     * call oracle.isIronBankMarket() or oracle.isCurveLpToken() even though these methods live on different contracts.
     */
    fallback() external {
        for (uint256 i = 0; i < _calculations.length; i++) {
            address calculation = _calculations[i];
            assembly {
                let _target := calculation
                calldatacopy(0, 0, calldatasize())
                let success := staticcall(
                    gas(),
                    _target,
                    0,
                    calldatasize(),
                    0,
                    0
                )
                returndatacopy(0, 0, returndatasize())
                if success {
                    return(0, returndatasize())
                }
            }
        }
        revert("Oracle: Fallback proxy failed to return data");
    }
}