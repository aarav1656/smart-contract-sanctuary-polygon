/**
 *Submitted for verification at polygonscan.com on 2023-03-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC20Decimal {
    // A lot of decimals are uint8 but they can be cast up to uint256
    function decimals() external view returns (uint256);
}

interface IERC20String {
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
}

interface IERC20Bytes32 {
    function symbol() external view returns (bytes32);
    function name() external view returns (bytes32);
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @notice Used to get token information for many addresses in a single call.
 * If an address is not a contract or a token, the batch will not fail.
 * @author Nick Addison
 */
contract TokenInfo {
    struct Info {
        string symbol;
        string name;
        uint256 decimals;
        bool noContract;
        bool nft;
    }

    function getInfoBatch(address[] memory tokens)
        external
        view
        returns (Info[] memory infos)
    {
        infos = new Info[](tokens.length);
        for (uint8 i = 0; i < tokens.length; i++) {
            infos[i] = this.getInfo(tokens[i]);
        }
    }

    function getInfo(address token) external view returns (Info memory info) {
        // Does code exists for the token?
        uint32 size;
        assembly {
            size := extcodesize(token)
        }
        if (size == 0) {
            info.noContract = true;
            return info;
        }

        // Try and get symbol and name as string
        try this.getStringProperties(token) returns (
            string memory _symbol,
            string memory _name
        ) {
            info.symbol = _symbol;
            info.name = _name;
        } catch {
            // Try and get symbol and name as bytes32
            try this.getBytes32Properties(token) returns (
                string memory _symbol,
                string memory _name
            ) {
                info.symbol = _symbol;
                info.name = _name;
            } catch {}
        }

        // Try and get the decimals
        try this.getDecimals(token) returns (uint256 _decimals) {
            info.decimals = _decimals;
        } catch {}
        
        // Try and see if the contract is a NFT
        try this.isNFT(token) returns (bool _nft) {
            info.nft = _nft;
        } catch {}
    }

    function getStringProperties(address token)
        external
        view
        returns (string memory symbol, string memory name)
    {
        symbol = IERC20String(token).symbol();
        name = IERC20String(token).name();
    }

    function getBytes32Properties(address token)
        external
        view
        returns (string memory symbol, string memory name)
    {
        bytes32 symbolBytes32 = IERC20Bytes32(token).symbol();
        bytes32 nameBytes32 = IERC20Bytes32(token).name();
        symbol = bytes32ToString(symbolBytes32);
        name = bytes32ToString(nameBytes32);
    }

    function bytes32ToString(bytes32 _bytes32)
        internal
        pure
        returns (string memory)
    {
        uint8 i = 0;
        while (i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    function getDecimals(address token)
        external
        view
        returns (uint256 decimals)
    {
        decimals = IERC20Decimal(token).decimals();
    }

    /// @notice is an address a contract or eternally owned account?
    function isContract(address account) external view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(account)
        }
        
        return size > 0;
    }

    /// @notice is an address a NFT?
    function isNFT(address account) external view returns (bool) {
        return IERC165(account).supportsInterface(0x80ac58cd) || // ERC721
            IERC165(account).supportsInterface(0x5b5e139f) || // ERC721Metadata
            IERC165(account).supportsInterface(0x780e9d63) || // ERC721Enumerable
            IERC165(account).supportsInterface(0x9a20483d); // CryptoKitties
    }
}