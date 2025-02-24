//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./static/StaticERC20.sol";
import "./static/StaticERC721.sol";
import "./static/StaticERC1155.sol";
import "./static/StaticUtil.sol";
import "./static/StaticMarket.sol";

/**
 * @title OasisXStatic
 * @notice static call functions
 * @author OasisX Protocol | cryptoware.eth
 */
contract OasisXStatic is
    StaticERC20,
    StaticERC721,
    StaticERC1155,
    StaticUtil,
    StaticMarket
{
    string public constant name = "OasisX Static";

    constructor(address atomicizerAddress) {
        require
        (
            atomicizerAddress != address(0),
            "OasisXAtomicizer: Atomicizer address cannot be 0"
        );
        atomicizer = atomicizerAddress;
        atomicizerAddr = atomicizerAddress;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/StaticCaller.sol";
import "../lib/ArrayUtils.sol";
import "../registry/AuthenticatedProxy.sol";

/// @notice StaticUtil - static call utility contract
contract StaticUtil is StaticCaller {
    address public atomicizer;

    function any(
        bytes memory,
        address[7] memory,
        AuthenticatedProxy.HowToCall[2] memory,
        uint256[6] memory,
        bytes memory,
        bytes memory
    ) public pure returns (uint256) {
        /*
           Accept any call.
           Useful e.g. for matching-by-transaction, where you authorize the counter-call by sending the transaction and don't need to re-check it.
           Return fill "1".
        */

        return 1;
    }

    function any() public pure returns (uint8) {
        return 1;
    }

    function anySingle(
        bytes memory,
        address[7] memory,
        AuthenticatedProxy.HowToCall,
        uint256[6] memory,
        bytes memory
    ) public pure {
        /* No checks. */
    }

    function anyNoFill(
        bytes memory,
        address[7] memory,
        AuthenticatedProxy.HowToCall[2] memory,
        uint256[6] memory,
        bytes memory,
        bytes memory
    ) public pure returns (uint256) {
        /*
           Accept any call.
           Useful e.g. for matching-by-transaction, where you authorize the counter-call by sending the transaction and don't need to re-check it.
           Return fill "0".
        */

        return 0;
    }

    function anyAddOne(
        bytes memory,
        address[7] memory,
        AuthenticatedProxy.HowToCall[2] memory,
        uint256[6] memory uints,
        bytes memory,
        bytes memory
    ) public pure returns (uint256) {
        /*
           Accept any call.
           Useful e.g. for matching-by-transaction, where you authorize the counter-call by sending the transaction and don't need to re-check it.
           Return the current fill plus 1.
        */

        return uints[5] + 1;
    }

    function split(
        bytes memory extra,
        address[7] memory addresses,
        AuthenticatedProxy.HowToCall[2] memory howToCalls,
        uint256[6] memory uints,
        bytes memory data,
        bytes memory counterdata
    ) public view returns (uint256) {
        (
            address[2] memory targets,
            bytes4[2] memory selectors,
            bytes memory firstExtradata,
            bytes memory secondExtradata
        ) = abi.decode(extra, (address[2], bytes4[2], bytes, bytes));

        /* Split into two static calls: one for the call, one for the counter-call, both with metadata. */

        /* Static call to check the call. */
        require(
            staticCall(
                targets[0],
                abi.encodeWithSelector(
                    selectors[0],
                    firstExtradata,
                    addresses,
                    howToCalls[0],
                    uints,
                    data
                )
            )
        );

        /* Static call to check the counter-call. */
        require(
            staticCall(
                targets[1],
                abi.encodeWithSelector(
                    selectors[1],
                    secondExtradata,
                    [
                        addresses[3],
                        addresses[4],
                        addresses[5],
                        addresses[0],
                        addresses[1],
                        addresses[2],
                        addresses[6]
                    ],
                    howToCalls[1],
                    uints,
                    counterdata
                )
            )
        );

        return 1;
    }

    function splitAddOne(
        bytes memory extra,
        address[7] memory addresses,
        AuthenticatedProxy.HowToCall[2] memory howToCalls,
        uint256[6] memory uints,
        bytes memory data,
        bytes memory counterdata
    ) public view returns (uint256) {
        split(extra, addresses, howToCalls, uints, data, counterdata);
        return uints[5] + 1;
    }

    function and(
        bytes memory extra,
        address[7] memory addresses,
        AuthenticatedProxy.HowToCall[2] memory howToCalls,
        uint256[6] memory uints,
        bytes memory data,
        bytes memory counterdata
    ) public view {
        (
            address[] memory addrs,
            bytes4[] memory selectors,
            uint256[] memory extradataLengths,
            bytes memory extradatas
        ) = abi.decode(extra, (address[], bytes4[], uint256[], bytes));

        require(addrs.length == extradataLengths.length);

        uint256 j = 0;
        for (uint256 i = 0; i < addrs.length; i++) {
            bytes memory extradata = new bytes(extradataLengths[i]);
            for (uint256 k = 0; k < extradataLengths[i]; k++) {
                extradata[k] = extradatas[j];
                j++;
            }
            require(
                staticCall(
                    addrs[i],
                    abi.encodeWithSelector(
                        selectors[i],
                        extradata,
                        addresses,
                        howToCalls,
                        uints,
                        data,
                        counterdata
                    )
                )
            );
        }
    }

    function or(
        bytes memory extra,
        address[7] memory addresses,
        AuthenticatedProxy.HowToCall[2] memory howToCalls,
        uint256[6] memory uints,
        bytes memory data,
        bytes memory counterdata
    ) public view {
        (
            address[] memory addrs,
            bytes4[] memory selectors,
            uint256[] memory extradataLengths,
            bytes memory extradatas
        ) = abi.decode(extra, (address[], bytes4[], uint256[], bytes));

        require(
            addrs.length == extradataLengths.length,
            "Different number of static call addresses and extradatas"
        );

        uint256 j = 0;
        for (uint256 i = 0; i < addrs.length; i++) {
            bytes memory extradata = new bytes(extradataLengths[i]);
            for (uint256 k = 0; k < extradataLengths[i]; k++) {
                extradata[k] = extradatas[j];
                j++;
            }
            if (
                staticCall(
                    addrs[i],
                    abi.encodeWithSelector(
                        selectors[i],
                        extradata,
                        addresses,
                        howToCalls,
                        uints,
                        data,
                        counterdata
                    )
                )
            ) {
                return;
            }
        }

        revert("No static calls succeeded");
    }

    function sequenceExact(
        bytes memory extra,
        address[7] memory addresses,
        AuthenticatedProxy.HowToCall howToCall,
        uint256[6] memory uints,
        bytes memory cdata
    ) public view {
        (
            address[] memory addrs,
            uint256[] memory extradataLengths,
            bytes4[] memory selectors,
            bytes memory extradatas
        ) = abi.decode(extra, (address[], uint256[], bytes4[], bytes));

        /* Assert DELEGATECALL to atomicizer library with given call sequence, split up predicates accordingly.
           e.g. transferring two CryptoKitties in sequence. */

        require(addrs.length == extradataLengths.length);

        (
            address[] memory caddrs,
            uint256[] memory cvals,
            uint256[] memory clengths,
            bytes memory calldatas
        ) = abi.decode(
                ArrayUtils.arrayDrop(cdata, 4),
                (address[], uint256[], uint256[], bytes)
            );

        require(addresses[2] == atomicizer);
        require(howToCall == AuthenticatedProxy.HowToCall.DelegateCall);
        require(addrs.length == caddrs.length); // Exact calls only

        for (uint256 i = 0; i < addrs.length; i++) {
            require(cvals[i] == 0);
        }

        sequence(
            caddrs,
            clengths,
            calldatas,
            addresses,
            uints,
            addrs,
            extradataLengths,
            selectors,
            extradatas
        );
    }

    function dumbSequenceExact(
        bytes memory extra,
        address[7] memory addresses,
        AuthenticatedProxy.HowToCall[2] memory howToCalls,
        uint256[6] memory uints,
        bytes memory cdata,
        bytes memory
    ) public view returns (uint256) {
        sequenceExact(extra, addresses, howToCalls[0], uints, cdata);

        return 1;
    }

    function sequenceAnyAfter(
        bytes memory extra,
        address[7] memory addresses,
        AuthenticatedProxy.HowToCall howToCall,
        uint256[6] memory uints,
        bytes memory cdata
    ) public view {
        (
            address[] memory addrs,
            uint256[] memory extradataLengths,
            bytes4[] memory selectors,
            bytes memory extradatas
        ) = abi.decode(extra, (address[], uint256[], bytes4[], bytes));

        /* Assert DELEGATECALL to atomicizer library with given call sequence, split up predicates accordingly.
           e.g. transferring two CryptoKitties in sequence. */

        require(addrs.length == extradataLengths.length);

        (
            address[] memory caddrs,
            uint256[] memory cvals,
            uint256[] memory clengths,
            bytes memory calldatas
        ) = abi.decode(
                ArrayUtils.arrayDrop(cdata, 4),
                (address[], uint256[], uint256[], bytes)
            );

        require(addresses[2] == atomicizer);
        require(howToCall == AuthenticatedProxy.HowToCall.DelegateCall);
        require(addrs.length <= caddrs.length); // Extra calls OK

        for (uint256 i = 0; i < addrs.length; i++) {
            require(cvals[i] == 0);
        }

        sequence(
            caddrs,
            clengths,
            calldatas,
            addresses,
            uints,
            addrs,
            extradataLengths,
            selectors,
            extradatas
        );
    }

    function sequence(
        address[] memory caddrs,
        uint256[] memory clengths,
        bytes memory calldatas,
        address[7] memory addresses,
        uint256[6] memory uints,
        address[] memory addrs,
        uint256[] memory extradataLengths,
        bytes4[] memory selectors,
        bytes memory extradatas
    ) internal view {
        uint256 j = 0;
        uint256 l = 0;
        for (uint256 i = 0; i < addrs.length; i++) {
            bytes memory extradata = new bytes(extradataLengths[i]);
            for (uint256 k = 0; k < extradataLengths[i]; k++) {
                extradata[k] = extradatas[j];
                j++;
            }
            bytes memory data = new bytes(clengths[i]);
            for (uint256 m = 0; m < clengths[i]; m++) {
                data[m] = calldatas[l];
                l++;
            }
            addresses[2] = caddrs[i];
            require(
                staticCall(
                    addrs[i],
                    abi.encodeWithSelector(
                        selectors[i],
                        extradata,
                        addresses,
                        AuthenticatedProxy.HowToCall.Call,
                        uints,
                        data
                    )
                )
            );
        }
        require(j == extradatas.length);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/ArrayUtils.sol";
import "../registry/AuthenticatedProxy.sol";

/**
 * @title StaticMarket
 * @author OasisX Protocol Developers
 * @dev each public here has the same parameters:
 * addresses an array of addresses, with each corresponding to the following:
		[0] order registry
		[1] order maker
		[2] call target
		[3] counterorder registry
		[4] counterorder maker
		[5] countercall target
		[6] matcher
 * howToCalls an array of enums: { Call | DelegateCall }
		[0] for the call
		[1] for the countercall
 * uints an array of 6 uints corresponding to the following:
		[0] value (eth value)
		[1] call max fill
		[2] order listing time
		[3] order expiration time
		[4] counterorder listing time
		[5] previous fill
 * data The data that you pass into the proxied function call. The static calls verify that the order placed actually matches up with the calldata passed to the proxied call
 * counterdata Same as data but for the countercall
 */
contract StaticMarket {
    address public atomicizerAddr;

    constructor() {
        /* solium-disable-line */
    }

    function anyERC1155ForERC20(
        bytes memory extra,
        address[7] memory addresses,
        AuthenticatedProxy.HowToCall[2] memory howToCalls,
        uint256[6] memory uints,
        bytes memory data,
        bytes memory counterdata
    ) public pure returns (uint256) {
        require(uints[0] == 0, "anyERC1155ForERC20: Zero value required");
        require(
            howToCalls[0] == AuthenticatedProxy.HowToCall.Call,
            "anyERC1155ForERC20: call must be a direct call"
        );

        (
            address[2] memory tokenGiveGet,
            uint256[3] memory tokenIdAndNumeratorDenominator
        ) = abi.decode(extra, (address[2], uint256[3]));

        require(
            tokenIdAndNumeratorDenominator[1] > 0,
            "anyERC20ForERC1155: numerator must be larger than zero"
        );
        require(
            tokenIdAndNumeratorDenominator[2] > 0,
            "anyERC20ForERC1155: denominator must be larger than zero"
        );
        require(
            addresses[2] == tokenGiveGet[0],
            "anyERC1155ForERC20: call target must equal address of token to give"
        );
        require(
            addresses[5] == tokenGiveGet[1],
            "anyERC1155ForERC20: countercall target must equal address of token to get"
        );

        uint256[2] memory call_amounts = [
            getERC1155AmountFromCalldata(data),
            getERC20AmountFromCalldata(counterdata)
        ];
        uint256 new_fill = (uints[5] + call_amounts[0]);
        require(
            new_fill <= uints[1],
            "anyERC1155ForERC20: new fill exceeds maximum fill"
        );
        require(
            (tokenIdAndNumeratorDenominator[1] * call_amounts[1]) ==
                (
                    tokenIdAndNumeratorDenominator[2] *
                    call_amounts[0]
                ),
            "anyERC1155ForERC20: wrong ratio"
        );
        checkERC1155Side(
            data,
            addresses[1],
            addresses[4],
            tokenIdAndNumeratorDenominator[0],
            call_amounts[0]
        );
        checkERC20Side(
            counterdata,
            addresses[4],
            addresses[1],
            call_amounts[1]
        );
        return new_fill;
    }

    function anyERC1155FforMultiERC20Calls(
        bytes memory extra,
        address[7] memory addresses,
        AuthenticatedProxy.HowToCall[2] memory,
        uint256[6] memory uints,
        bytes memory data,
        bytes memory counterdata
    ) public view returns (uint256) {
        require(uints[0] == 0, "anyERC1155ForERC20: Zero value required");

        (
            address[] memory tokenGiveGet,
            uint256[] memory tokenIdAndNumeratorDenominator
        ) = abi.decode(extra, (address[], uint256[]));

        require(
            tokenIdAndNumeratorDenominator[1] > 0,
            "anyERC20ForERC1155: numerator must be larger than zero"
        );
        require(
            tokenIdAndNumeratorDenominator[2] > 0,
            "anyERC20ForERC1155: denominator must be larger than zero"
        );
        require(
            addresses[2] == atomicizerAddr,
            "anyERC1155ForERC20: call target must equal address of token to give"
        );
        require(
            addresses[5] == tokenGiveGet[1],
            "anyERC1155ForERC20: countercall target must equal atomicizer address"
        );

        (
            uint256[] memory erc20Amounts,
            bytes[] memory calls
        ) = getAmountsFromAtomizerData(data);

        uint256 nftsAmount = getERC1155AmountFromCalldata(counterdata);

        uint256 new_fill = (uints[5] + erc20Amounts[0]);

        require(
            new_fill <= uints[1],
            "anyERC1155ForERC20: new fill exceeds maximum fill"
        );

        require(
            (tokenIdAndNumeratorDenominator[2] * erc20Amounts[0]) ==
                (tokenIdAndNumeratorDenominator[1] * nftsAmount),
            "anyERC1155ForERC20: wrong ratio"
        );

        checkERC1155Side(
            counterdata,
            addresses[4],
            addresses[1],
            tokenIdAndNumeratorDenominator[0],
            nftsAmount
        );

        for (uint256 i = 0; i < calls.length; i++) {
            checkERC20Side(
                calls[i],
                addresses[1],
                i == 0 ? addresses[4] : tokenGiveGet[i + 1],
                i == 0
                    ? tokenIdAndNumeratorDenominator[i + 1]
                    : tokenIdAndNumeratorDenominator[i + 2]
            );
        }

        return new_fill;
    }

    function getAmountsFromAtomizerData(bytes memory counterdata)
        public
        pure
        returns (uint256[] memory, bytes[] memory)
    {
        (
            address[] memory caddrs,
            ,
            /*uint256[] memory cvals */
            uint256[] memory clengths,
            bytes memory calldatas
        ) = abi.decode(
                ArrayUtils.arrayDrop(counterdata, 4),
                (address[], uint256[], uint256[], bytes)
            );

        uint256[] memory amounts = new uint256[](caddrs.length);

        bytes[] memory calls = new bytes[](caddrs.length);

        uint256 j = 0;

        for (uint256 i = 0; i < caddrs.length; i++) {
            bytes memory cd = new bytes(clengths[i]);
            for (uint256 k = 0; k < clengths[i]; k++) {
                cd[k] = calldatas[j];
                j++;
            }

            amounts[i] = abi.decode(
                ArrayUtils.arraySlice(cd, 68, 32),
                (uint256)
            );
            calls[i] = cd;
        }

        return (amounts, calls);
    }

    function ERC1155WithValue(
        bytes memory extra,
        address[7] memory addresses,
        AuthenticatedProxy.HowToCall[2] memory howToCalls,
        uint256[6] memory uints,
        bytes memory data,
        bytes memory
    ) public pure returns (uint256) {
        // decode extraData
        (
            address[2] memory creatorAndTokenGive,
            uint256[3] memory tokenIdPriceRoyalties,
            /*bytes memory ReferralCoupon*/
        ) = abi.decode(extra, (address[2], uint256[3], bytes));

        require(
            howToCalls[0] == AuthenticatedProxy.HowToCall.Call,
            "ERC1155WithValue: call must be a direct call"
        );

        require(
            addresses[2] == creatorAndTokenGive[1],
            "ERC1155WithValue: call target must equal address of token to give"
        );

        uint256[1] memory call_amounts = [getERC1155AmountFromCalldata(data)];

        require(
            tokenIdPriceRoyalties[1] * call_amounts[0] == uints[0],
            "ERC1155WithValue: value sent must equal to token price x amount in eth"
        );

        uint256 new_fill = (uints[5] + call_amounts[0]);

        require(
            new_fill <= uints[1],
            "ERC1155WithValue: new fill exceeds maximum fill"
        );

        checkERC1155Side(
            data,
            addresses[1],
            addresses[4],
            tokenIdPriceRoyalties[0],
            call_amounts[0]
        );

        return new_fill;
    }

    function anyERC20ForERC1155(
        bytes memory extra,
        address[7] memory addresses,
        AuthenticatedProxy.HowToCall[2] memory howToCalls,
        uint256[6] memory uints,
        bytes memory data,
        bytes memory counterdata
    ) public pure returns (uint256) {
        require(uints[0] == 0, "anyERC20ForERC1155: Zero value required");
        require(
            howToCalls[0] == AuthenticatedProxy.HowToCall.Call,
            "anyERC20ForERC1155: call must be a direct call"
        );

        (
            address[2] memory tokenGiveGet,
            uint256[3] memory tokenIdAndNumeratorDenominator
        ) = abi.decode(extra, (address[2], uint256[3]));

        require(
            tokenIdAndNumeratorDenominator[1] > 0,
            "anyERC20ForERC1155: numerator must be larger than zero"
        );
        require(
            tokenIdAndNumeratorDenominator[2] > 0,
            "anyERC20ForERC1155: denominator must be larger than zero"
        );
        require(
            addresses[2] == tokenGiveGet[0],
            "anyERC20ForERC1155: call target must equal address of token to get"
        );
        require(
            addresses[5] == tokenGiveGet[1],
            "anyERC20ForERC1155: countercall target must equal address of token to give"
        );

        uint256[2] memory call_amounts = [
            getERC1155AmountFromCalldata(counterdata),
            getERC20AmountFromCalldata(data)
        ];
        uint256 new_fill = (uints[5] + call_amounts[1]);
        require(
            new_fill <= uints[1],
            "anyERC20ForERC1155: new fill exceeds maximum fill"
        );
        require(
            (tokenIdAndNumeratorDenominator[1] * call_amounts[0]) ==
               (
                    tokenIdAndNumeratorDenominator[2] *
                    call_amounts[1]
                ),
            "anyERC20ForERC1155: wrong ratio"
        );
        checkERC1155Side(
            counterdata,
            addresses[4],
            addresses[1],
            tokenIdAndNumeratorDenominator[0],
            call_amounts[0]
        );
        checkERC20Side(data, addresses[1], addresses[4], call_amounts[1]);
        return new_fill;
    }

    function LazyERC1155ForERC20(
        bytes memory extra,
        address[7] memory addresses,
        AuthenticatedProxy.HowToCall[2] memory howToCalls,
        uint256[6] memory uints,
        bytes memory data,
        bytes memory counterdata
    ) public pure returns (uint256) {
        require(uints[0] == 0, "lazyERC1155ForERC20: Zero value required");
        require(
            howToCalls[0] == AuthenticatedProxy.HowToCall.Call,
            "lazyERC1155ForERC20: call must be a direct call"
        );

        (
            address[2] memory tokenGiveGet,
            uint256[3] memory tokenIdAndNumeratorDenominator,
            bytes memory extraBytes
        ) = abi.decode(extra, (address[2], uint256[3], bytes));

        require(
            tokenIdAndNumeratorDenominator[1] > 0,
            "lazyERC1155ForERC20: numerator must be larger than zero"
        );
        require(
            tokenIdAndNumeratorDenominator[2] > 0,
            "lazyERC1155ForERC20: denominator must be larger than zero"
        );
        require(
            addresses[2] == tokenGiveGet[0],
            "lazyERC1155ForERC20: call target must equal address of token to give"
        );
        require(
            addresses[5] == tokenGiveGet[1],
            "lazyERC1155ForERC20: countercall target must equal address of token to get"
        );

        uint256[2] memory call_amounts = [
            abi.decode(ArrayUtils.arraySlice(data, 68, 32), (uint256)),
            getERC20AmountFromCalldata(counterdata)
        ];
        uint256 new_fill = (uints[5] +call_amounts[0]);
        require(
            new_fill <= uints[1],
            "anyERC1155ForERC20: new fill exceeds maximum fill"
        );
        require(
            (tokenIdAndNumeratorDenominator[1] * call_amounts[1]) ==
                (
                    tokenIdAndNumeratorDenominator[2] *
                    call_amounts[0]
                ),
            "lazyERC1155ForERC20: wrong ratio"
        );
        require(
            ArrayUtils.arrayEq(
                data,
                abi.encodeWithSignature(
                    "mint(address,uint256,uint256,bytes)",
                    addresses[4],
                    tokenIdAndNumeratorDenominator[0],
                    call_amounts[0],
                    extraBytes
                )
            ),
            "Data arity mismatch"
        );
        require(
            ArrayUtils.arrayEq(
                counterdata,
                abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)",
                    addresses[4],
                    addresses[1],
                    call_amounts[1]
                )
            ),
            "Counterdata arity mismatch"
        );
        return new_fill;
    }

    function LazyERC20ForERC1155(
        bytes memory extra,
        address[7] memory addresses,
        AuthenticatedProxy.HowToCall[2] memory howToCalls,
        uint256[6] memory uints,
        bytes memory data,
        bytes memory counterdata
    ) public pure returns (uint256) {
        require(uints[0] == 0, "lazyERC20ForERC1155: Zero value required");
        require(
            howToCalls[0] == AuthenticatedProxy.HowToCall.Call,
            "lazyERC20ForERC1155: call must be a direct call"
        );

        (
            address[2] memory tokenGiveGet,
            uint256[3] memory tokenIdAndNumeratorDenominator,
            bytes memory extraBytes
        ) = abi.decode(extra, (address[2], uint256[3], bytes));

        require(
            tokenIdAndNumeratorDenominator[1] > 0,
            "lazyERC20ForERC1155: numerator must be larger than zero"
        );
        require(
            tokenIdAndNumeratorDenominator[2] > 0,
            "lazyERC20ForERC1155: denominator must be larger than zero"
        );
        require(
            addresses[2] == tokenGiveGet[0],
            "lazyERC20ForERC1155: call target must equal address of token to get"
        );
        require(
            addresses[5] == tokenGiveGet[1],
            "lazyERC20ForERC1155: countercall target must equal address of token to give"
        );

        uint256[2] memory call_amounts = [
            abi.decode(ArrayUtils.arraySlice(counterdata, 68, 32), (uint256)),
            getERC20AmountFromCalldata(data)
        ];
        uint256 new_fill = (uints[5] + call_amounts[1]);
        require(
            new_fill <= uints[1],
            "lazyERC20ForERC1155: new fill exceeds maximum fill"
        );
        require(
            (tokenIdAndNumeratorDenominator[1] * call_amounts[0]) ==
               (
                    tokenIdAndNumeratorDenominator[2] *
                    call_amounts[1]
                ),
            "lazyERC20ForERC1155: wrong ratio"
        );
        require(
            ArrayUtils.arrayEq(
                counterdata,
                abi.encodeWithSignature(
                    "mint(address,uint256,uint256,bytes)",
                    addresses[1],
                    tokenIdAndNumeratorDenominator[0],
                    call_amounts[0],
                    extraBytes
                )
            ),
            "Counterdata arity mismatch"
        );
        require(
            ArrayUtils.arrayEq(
                data,
                abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)",
                    addresses[1],
                    addresses[4],
                    call_amounts[1]
                )
            ),
            "Data arity mismatch"
        );
        return new_fill;
    }

    function anyERC20ForERC20(
        bytes memory extra,
        address[7] memory addresses,
        AuthenticatedProxy.HowToCall[2] memory howToCalls,
        uint256[6] memory uints,
        bytes memory data,
        bytes memory counterdata
    ) public pure returns (uint256) {
        require(uints[0] == 0, "anyERC20ForERC20: Zero value required");
        require(
            howToCalls[0] == AuthenticatedProxy.HowToCall.Call,
            "anyERC20ForERC20: call must be a direct call"
        );

        (
            address[2] memory tokenGiveGet,
            uint256[2] memory numeratorDenominator
        ) = abi.decode(extra, (address[2], uint256[2]));

        require(
            numeratorDenominator[0] > 0,
            "anyERC20ForERC20: numerator must be larger than zero"
        );
        require(
            numeratorDenominator[1] > 0,
            "anyERC20ForERC20: denominator must be larger than zero"
        );
        require(
            addresses[2] == tokenGiveGet[0],
            "anyERC20ForERC20: call target must equal address of token to give"
        );
        require(
            addresses[5] == tokenGiveGet[1],
            "anyERC20ForERC20: countercall target must equal address of token to get"
        );

        uint256[2] memory call_amounts = [
            getERC20AmountFromCalldata(data),
            getERC20AmountFromCalldata(counterdata)
        ];
        uint256 new_fill = (uints[5] + call_amounts[0]);
        require(
            new_fill <= uints[1],
            "anyERC20ForERC20: new fill exceeds maximum fill"
        );
        require(
            (numeratorDenominator[0] * call_amounts[0]) ==
               (numeratorDenominator[1] * call_amounts[1]),
            "anyERC20ForERC20: wrong ratio"
        );
        checkERC20Side(data, addresses[1], addresses[4], call_amounts[0]);
        checkERC20Side(
            counterdata,
            addresses[4],
            addresses[1],
            call_amounts[1]
        );
        return new_fill;
    }

    function ERC721ForERC20(
        bytes memory extra,
        address[7] memory addresses,
        AuthenticatedProxy.HowToCall[2] memory howToCalls,
        uint256[6] memory uints,
        bytes memory data,
        bytes memory counterdata
    ) public pure returns (uint256) {
        require(uints[0] == 0, "ERC721ForERC20: Zero value required");
        require(
            howToCalls[0] == AuthenticatedProxy.HowToCall.Call,
            "ERC721ForERC20: call must be a direct call"
        );

        (
            address[2] memory tokenGiveGet,
            uint256[2] memory tokenIdAndPrice
        ) = abi.decode(extra, (address[2], uint256[2]));

        require(
            tokenIdAndPrice[1] > 0,
            "ERC721ForERC20: ERC721 price must be larger than zero"
        );
        require(
            addresses[2] == tokenGiveGet[0],
            "ERC721ForERC20: call target must equal address of token to give"
        );
        require(
            addresses[5] == tokenGiveGet[1],
            "ERC721ForERC20: countercall target must equal address of token to get"
        );

        checkERC721Side(data, addresses[1], addresses[4], tokenIdAndPrice[0]);
        checkERC20Side(
            counterdata,
            addresses[4],
            addresses[1],
            tokenIdAndPrice[1]
        );
        return 1;
    }

    function ERC20ForERC721(
        bytes memory extra,
        address[7] memory addresses,
        AuthenticatedProxy.HowToCall[2] memory howToCalls,
        uint256[6] memory uints,
        bytes memory data,
        bytes memory counterdata
    ) public pure returns (uint256) {
        require(uints[0] == 0, "ERC20ForERC721: Zero value required");
        require(
            howToCalls[0] == AuthenticatedProxy.HowToCall.Call,
            "ERC20ForERC721: call must be a direct call"
        );

        (
            address[2] memory tokenGiveGet,
            uint256[2] memory tokenIdAndPrice
        ) = abi.decode(extra, (address[2], uint256[2]));

        require(
            tokenIdAndPrice[1] > 0,
            "ERC20ForERC721: ERC721 price must be larger than zero"
        );
        require(
            addresses[2] == tokenGiveGet[0],
            "ERC20ForERC721: call target must equal address of token to give"
        );
        require(
            addresses[5] == tokenGiveGet[1],
            "ERC20ForERC721: countercall target must equal address of token to get"
        );

        checkERC721Side(
            counterdata,
            addresses[4],
            addresses[1],
            tokenIdAndPrice[0]
        );
        checkERC20Side(data, addresses[1], addresses[4], tokenIdAndPrice[1]);
        return 1;
    }

    function LazyERC721ForERC20(
        bytes memory extra,
        address[7] memory addresses,
        AuthenticatedProxy.HowToCall[2] memory howToCalls,
        uint256[6] memory uints,
        bytes memory data,
        bytes memory counterdata
    ) public pure returns (uint256) {
        require(uints[0] == 0, "LazyERC721ForERC20: Zero value required");
        require(
            howToCalls[0] == AuthenticatedProxy.HowToCall.Call,
            "ERC721ForERC20: call must be a direct call"
        );
        (
            address[2] memory tokenGiveGet,
            uint256[2] memory tokenIdAndPrice,
            bytes memory extraBytes
        ) = abi.decode(extra, (address[2], uint256[2], bytes));

        require(
            tokenIdAndPrice[1] > 0,
            "LazyERC721ForERC20: ERC721 price must be larger than zero"
        );
        require(
            addresses[2] == tokenGiveGet[0],
            "ERC721ForERC20: call target must equal address of token to give"
        );
        require(
            addresses[5] == tokenGiveGet[1],
            "ERC721ForERC20: countercall target must equal address of token to get"
        );
        require(
            ArrayUtils.arrayEq(
                data,
                abi.encodeWithSignature(
                    "mint(address,uint256,bytes)",
                    addresses[4],
                    tokenIdAndPrice[0],
                    extraBytes
                )
            ),
            "Data arity mismatch"
        );
        require(
            ArrayUtils.arrayEq(
                counterdata,
                abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)",
                    addresses[4],
                    addresses[1],
                    tokenIdAndPrice[1]
                )
            ),
            "Counterdata arity mismatch"
        );
        return 1;
    }

    function LazyERC20ForERC721(
        bytes memory extra,
        address[7] memory addresses,
        AuthenticatedProxy.HowToCall[2] memory howToCalls,
        uint256[6] memory uints,
        bytes memory data,
        bytes memory counterdata
    ) public pure returns (uint256) {
        require(uints[0] == 0, "ERC20ForERC721: Zero value required");
        require(
            howToCalls[0] == AuthenticatedProxy.HowToCall.Call,
            "ERC20ForERC721: call must be a direct call"
        );

        (
            address[2] memory tokenGiveGet,
            uint256[2] memory tokenIdAndPrice,
            bytes memory extraBytes
        ) = abi.decode(extra, (address[2], uint256[2], bytes));

        require(
            tokenIdAndPrice[1] > 0,
            "ERC20ForERC721: ERC721 price must be larger than zero"
        );
        require(
            addresses[2] == tokenGiveGet[0],
            "ERC20ForERC721: call target must equal address of token to give"
        );
        require(
            addresses[5] == tokenGiveGet[1],
            "ERC20ForERC721: countercall target must equal address of token to get"
        );
        require(
            ArrayUtils.arrayEq(
                counterdata,
                abi.encodeWithSignature(
                    "mint(address,uint256,bytes)",
                    addresses[1],
                    tokenIdAndPrice[0],
                    extraBytes
                )
            ),
            "Counterdata arity mismatch"
        );
        require(
            ArrayUtils.arrayEq(
                data,
                abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)",
                    addresses[1],
                    addresses[4],
                    tokenIdAndPrice[1]
                )
            ),
            "Data arity mismatch"
        );
        return 1;
    }

    // internal helper functions
    function getERC1155AmountFromCalldata(bytes memory data)
        internal
        pure
        returns (uint256)
    {
        uint256 amount = abi.decode(
            ArrayUtils.arraySlice(data, 100, 32),
            (uint256)
        );
        return amount;
    }

    function getERC20AmountFromCalldata(bytes memory data)
        internal
        pure
        returns (uint256)
    {
        uint256 amount = abi.decode(
            ArrayUtils.arraySlice(data, 68, 32),
            (uint256)
        );
        return amount;
    }

    function checkERC1155Side(
        bytes memory data,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) internal pure {
        require(
            ArrayUtils.arrayEq(
                data,
                abi.encodeWithSignature(
                    "safeTransferFrom(address,address,uint256,uint256,bytes)",
                    from,
                    to,
                    tokenId,
                    amount,
                    ""
                )
            ),
            "Data arity mismatch"
        );
    }

    function checkERC721Side(
        bytes memory data,
        address from,
        address to,
        uint256 tokenId
    ) internal pure {
        require(
            ArrayUtils.arrayEq(
                data,
                abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)",
                    from,
                    to,
                    tokenId
                )
            ),
            "Data arity mismatch"
        );
    }

    function checkERC20Side(
        bytes memory data,
        address from,
        address to,
        uint256 amount
    ) internal pure {
        require(
            ArrayUtils.arrayEq(
                data,
                abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)",
                    from,
                    to,
                    amount
                )
            ),
            "Data arity mismatch"
        );
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/ArrayUtils.sol";
import "../registry/AuthenticatedProxy.sol";

/// @notice StaticERC721 - static calls for ERC721 trades
contract StaticERC721 {
    function transferERC721Exact(
        bytes memory extra,
        address[7] memory addresses,
        AuthenticatedProxy.HowToCall howToCall,
        uint256[6] memory,
        bytes memory data
    ) public pure {
        // Decode extradata
        (address token, uint256 tokenId) = abi.decode(
            extra,
            (address, uint256)
        );

        // Call target = token to give
        require(addresses[2] == token);
        // Call type = call
        require(howToCall == AuthenticatedProxy.HowToCall.Call);
        // Assert calldata
        require(
            ArrayUtils.arrayEq(
                data,
                abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)",
                    addresses[1],
                    addresses[4],
                    tokenId
                )
            )
        );
    }

    function swapOneForOneERC721(
        bytes memory extra,
        address[7] memory addresses,
        AuthenticatedProxy.HowToCall[2] memory howToCalls,
        uint256[6] memory uints,
        bytes memory data,
        bytes memory counterdata
    ) public pure returns (uint256) {
        // Zero-value
        require(uints[0] == 0);

        // Decode extradata
        (address[2] memory tokenGiveGet, uint256[2] memory nftGiveGet) = abi
            .decode(extra, (address[2], uint256[2]));

        // Call target = token to give
        require(
            addresses[2] == tokenGiveGet[0],
            "ERC721: call target must equal address of token to give"
        );
        // Call type = call
        require(
            howToCalls[0] == AuthenticatedProxy.HowToCall.Call,
            "ERC721: call must be a direct call"
        );
        // Assert calldata
        require(
            ArrayUtils.arrayEq(
                data,
                abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)",
                    addresses[1],
                    addresses[4],
                    nftGiveGet[0]
                )
            )
        );

        // Countercall target = token to get
        require(
            addresses[5] == tokenGiveGet[1],
            "ERC721: countercall target must equal address of token to get"
        );
        // Countercall type = call
        require(
            howToCalls[1] == AuthenticatedProxy.HowToCall.Call,
            "ERC721: countercall must be a direct call"
        );
        // Assert countercalldata
        require(
            ArrayUtils.arrayEq(
                counterdata,
                abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)",
                    addresses[4],
                    addresses[1],
                    nftGiveGet[1]
                )
            )
        );

        // Mark filled
        return 1;
    }

    function swapOneForOneERC721Decoding(
        bytes memory extra,
        address[7] memory addresses,
        AuthenticatedProxy.HowToCall[2] memory howToCalls,
        uint256[6] memory uints,
        bytes memory data,
        bytes memory counterdata
    ) public pure returns (uint256) {
        // Calculate function signature
        bytes memory sig = ArrayUtils.arrayTake(
            abi.encodeWithSignature("transferFrom(address,address,uint256)"),
            4
        );

        // Zero-value
        require(uints[0] == 0);

        // Decode extradata
        (address[2] memory tokenGiveGet, uint256[2] memory nftGiveGet) = abi
            .decode(extra, (address[2], uint256[2]));

        // Call target = token to give
        require(
            addresses[2] == tokenGiveGet[0],
            "ERC721: call target must equal address of token to give"
        );
        // Call type = call
        require(
            howToCalls[0] == AuthenticatedProxy.HowToCall.Call,
            "ERC721: call must be a direct call"
        );
        // Assert signature
        require(ArrayUtils.arrayEq(sig, ArrayUtils.arrayTake(data, 4)));
        // Decode calldata
        (address callFrom, address callTo, uint256 nftGive) = abi.decode(
            ArrayUtils.arrayDrop(data, 4),
            (address, address, uint256)
        );
        // Assert from
        require(callFrom == addresses[1]);
        // Assert to
        require(callTo == addresses[4]);
        // Assert NFT
        require(nftGive == nftGiveGet[0]);

        // Countercall target = token to get
        require(
            addresses[5] == tokenGiveGet[1],
            "ERC721: countercall target must equal address of token to get"
        );
        // Countercall type = call
        require(
            howToCalls[1] == AuthenticatedProxy.HowToCall.Call,
            "ERC721: countercall must be a direct call"
        );
        // Assert signature
        require(ArrayUtils.arrayEq(sig, ArrayUtils.arrayTake(counterdata, 4)));
        // Decode countercalldata
        (address countercallFrom, address countercallTo, uint256 nftGet) = abi
            .decode(
                ArrayUtils.arrayDrop(counterdata, 4),
                (address, address, uint256)
            );
        // Assert from
        require(countercallFrom == addresses[4]);
        // Assert to
        require(countercallTo == addresses[1]);
        // Assert NFT
        require(nftGet == nftGiveGet[1]);

        // Mark filled
        return 1;
    }

    function ERC721WithValue(
        bytes memory extra,
        address[7] memory addresses,
        AuthenticatedProxy.HowToCall[2] memory howToCalls,
        uint256[6] memory uints,
        bytes memory data,
        bytes memory
    ) public pure returns (uint256) {
        // Decode extradata
        (
            address[2] memory creatorAndCollection,
            uint256[3] memory tokenIdPriceRoyalties,
            /*bytes memory ReferralCoupon*/
        ) = abi.decode(extra, (address[2], uint256[3], bytes));

        // msg.value
        require(
            uints[0] == tokenIdPriceRoyalties[1],
            "ERC721: value sent must equal to token price in eth"
        );

        // Call target = token to give
        require(
            addresses[2] == creatorAndCollection[1],
            "ERC721: call target must equal address of token to give"
        );

        // Call type = call
        require(
            howToCalls[0] == AuthenticatedProxy.HowToCall.Call,
            "ERC721: call must be a direct call"
        );

        // Assert calldata
        require(
            ArrayUtils.arrayEq(
                data,
                abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)",
                    addresses[1],
                    addresses[4],
                    tokenIdPriceRoyalties[0]
                )
            )
        );

        // Mark filled
        return 1;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/ArrayUtils.sol";
import "../registry/AuthenticatedProxy.sol";

/// @notice StaticERC20 - static calls for ERC20 trades
contract StaticERC20 {
    function transferERC20Exact(
        bytes memory extra,
        address[7] memory addresses,
        AuthenticatedProxy.HowToCall howToCall,
        uint256[6] memory,
        bytes memory data
    ) public pure {
        // Decode extradata
        (address token, uint256 amount) = abi.decode(extra, (address, uint256));

        // Call target = token to give
        require(addresses[2] == token);
        // Call type = call
        require(howToCall == AuthenticatedProxy.HowToCall.Call);
        // Assert calldata
        require(
            ArrayUtils.arrayEq(
                data,
                abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)",
                    addresses[1],
                    addresses[4],
                    amount
                )
            )
        );
    }

    function transferERC20ExactTo(
        bytes memory extra,
        address[7] memory addresses,
        AuthenticatedProxy.HowToCall howToCall,
        uint256[6] memory,
        bytes memory data
    ) public pure {
        // Decode extradata
        (address token, uint256 amount, address receiver) = abi.decode(
            extra,
            (address, uint256, address)
        );
        // Call target = token to give
        require(addresses[2] == token);
        // Call type = call
        require(howToCall == AuthenticatedProxy.HowToCall.Call);
        // Assert calldata
        require(
            ArrayUtils.arrayEq(
                data,
                abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)",
                    addresses[1],
                    receiver,
                    amount
                )
            )
        );
    }

    function swapExact(
        bytes memory extra,
        address[7] memory addresses,
        AuthenticatedProxy.HowToCall[2] memory howToCalls,
        uint256[6] memory uints,
        bytes memory data,
        bytes memory counterdata
    ) public pure returns (uint256) {
        // Zero-value
        require(uints[0] == 0);

        // Decode extradata
        (address[2] memory tokenGiveGet, uint256[2] memory amountGiveGet) = abi
            .decode(extra, (address[2], uint256[2]));

        // Call target = token to give
        require(addresses[2] == tokenGiveGet[0]);
        // Call type = call
        require(howToCalls[0] == AuthenticatedProxy.HowToCall.Call);
        // Assert calldata
        require(
            ArrayUtils.arrayEq(
                data,
                abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)",
                    addresses[1],
                    addresses[4],
                    amountGiveGet[0]
                )
            )
        );

        require(addresses[5] == tokenGiveGet[1]);
        // Countercall type = call
        require(howToCalls[1] == AuthenticatedProxy.HowToCall.Call);
        // Assert countercalldata
        require(
            ArrayUtils.arrayEq(
                counterdata,
                abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)",
                    addresses[4],
                    addresses[1],
                    amountGiveGet[1]
                )
            )
        );

        // Mark filled.
        return 1;
    }

    function swapForever(
        bytes memory extra,
        address[7] memory addresses,
        AuthenticatedProxy.HowToCall[2] memory howToCalls,
        uint256[6] memory uints,
        bytes memory data,
        bytes memory counterdata
    ) public pure returns (uint256) {
        // Calculate function signature
        bytes memory sig = ArrayUtils.arrayTake(
            abi.encodeWithSignature("transferFrom(address,address,uint256)"),
            4
        );

        // Zero-value
        require(uints[0] == 0);

        // Decode extradata
        (
            address[2] memory tokenGiveGet,
            uint256[2] memory numeratorDenominator
        ) = abi.decode(extra, (address[2], uint256[2]));

        // Call target = token to give
        require(addresses[2] == tokenGiveGet[0]);
        // Call type = call
        require(howToCalls[0] == AuthenticatedProxy.HowToCall.Call);
        // Check signature
        require(ArrayUtils.arrayEq(sig, ArrayUtils.arrayTake(data, 4)));
        // Decode calldata
        (address callFrom, address callTo, uint256 amountGive) = abi.decode(
            ArrayUtils.arrayDrop(data, 4),
            (address, address, uint256)
        );
        // Assert from
        require(callFrom == addresses[1]);
        // Assert to
        require(callTo == addresses[4]);

        // Countercall target = token to get
        require(addresses[5] == tokenGiveGet[1]);
        // Countercall type = call
        require(howToCalls[1] == AuthenticatedProxy.HowToCall.Call);
        // Check signature
        require(ArrayUtils.arrayEq(sig, ArrayUtils.arrayTake(counterdata, 4)));
        // Decode countercalldata
        (
            address countercallFrom,
            address countercallTo,
            uint256 amountGet
        ) = abi.decode(
                ArrayUtils.arrayDrop(counterdata, 4),
                (address, address, uint256)
            );
        // Assert from
        require(countercallFrom == addresses[4]);
        // Assert to
        require(countercallTo == addresses[1]);

        // Assert ratio
        // ratio = min get/give
        require(
            (amountGet * numeratorDenominator[1]) >=
                (amountGive * numeratorDenominator[0])
        );

        // Order will be set with maximumFill = 2 (to allow signature caching)
        return 1;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/ArrayUtils.sol";
import "../registry/AuthenticatedProxy.sol";

/// @notice StaticERC1155 - static calls for ERC1155 trades
contract StaticERC1155 {
    function transferERC1155Exact(
        bytes memory extra,
        address[7] memory addresses,
        AuthenticatedProxy.HowToCall howToCall,
        uint256[6] memory,
        bytes memory data
    ) public pure {
        // Decode extradata
        (address token, uint256 tokenId, uint256 amount) = abi.decode(
            extra,
            (address, uint256, uint256)
        );

        // Call target = token to give
        require(addresses[2] == token);
        // Call type = call
        require(howToCall == AuthenticatedProxy.HowToCall.Call);
        // Assert calldata
        require(
            ArrayUtils.arrayEq(
                data,
                abi.encodeWithSignature(
                    "safeTransferFrom(address,address,uint256,uint256,bytes)",
                    addresses[1],
                    addresses[4],
                    tokenId,
                    amount,
                    ""
                )
            )
        );
    }

    function swapOneForOneERC1155(
        bytes memory extra,
        address[7] memory addresses,
        AuthenticatedProxy.HowToCall[2] memory howToCalls,
        uint256[6] memory uints,
        bytes memory data,
        bytes memory counterdata
    ) public pure returns (uint256) {
        // Zero-value
        require(uints[0] == 0);

        // Decode extradata
        (
            address[2] memory tokenGiveGet,
            uint256[2] memory nftGiveGet,
            uint256[2] memory nftAmounts
        ) = abi.decode(extra, (address[2], uint256[2], uint256[2]));

        // Call target = token to give
        require(
            addresses[2] == tokenGiveGet[0],
            "ERC1155: call target must equal address of token to give"
        );
        // Assert more than zero
        require(
            nftAmounts[0] > 0,
            "ERC1155: give amount must be larger than zero"
        );
        // Call type = call
        require(
            howToCalls[0] == AuthenticatedProxy.HowToCall.Call,
            "ERC1155: call must be a direct call"
        );
        // Assert calldata
        require(
            ArrayUtils.arrayEq(
                data,
                abi.encodeWithSignature(
                    "safeTransferFrom(address,address,uint256,uint256,bytes)",
                    addresses[1],
                    addresses[4],
                    nftGiveGet[0],
                    nftAmounts[0],
                    ""
                )
            )
        );

        // Countercall target = token to get
        require(
            addresses[5] == tokenGiveGet[1],
            "ERC1155: countercall target must equal address of token to get"
        );
        // Assert more than zero
        require(
            nftAmounts[1] > 0,
            "ERC1155: take amount must be larger than zero"
        );
        // Countercall type = call
        require(
            howToCalls[1] == AuthenticatedProxy.HowToCall.Call,
            "ERC1155: countercall must be a direct call"
        );
        // Assert countercalldata
        require(
            ArrayUtils.arrayEq(
                counterdata,
                abi.encodeWithSignature(
                    "safeTransferFrom(address,address,uint256,uint256,bytes)",
                    addresses[4],
                    addresses[1],
                    nftGiveGet[1],
                    nftAmounts[1],
                    ""
                )
            )
        );

        // Mark filled
        return 1;
    }

    function swapOneForOneERC1155Decoding(
        bytes memory extra,
        address[7] memory addresses,
        AuthenticatedProxy.HowToCall[2] memory howToCalls,
        uint256[6] memory uints,
        bytes memory data,
        bytes memory counterdata
    ) public pure returns (uint256) {
        // Calculate function signature
        bytes memory sig = ArrayUtils.arrayTake(
            abi.encodeWithSignature(
                "safeTransferFrom(address,address,uint256,uint256,bytes)"
            ),
            4
        );

        // Zero-value
        require(uints[0] == 0);

        // Decode extradata
        (
            address[2] memory tokenGiveGet,
            uint256[2] memory nftGiveGet,
            uint256[2] memory nftAmounts
        ) = abi.decode(extra, (address[2], uint256[2], uint256[2]));

        // Call target = token to give
        require(
            addresses[2] == tokenGiveGet[0],
            "ERC1155: call target must equal address of token to give"
        );
        // Call type = call
        require(
            howToCalls[0] == AuthenticatedProxy.HowToCall.Call,
            "ERC1155: call must be a direct call"
        );
        // Assert signature
        require(ArrayUtils.arrayEq(sig, ArrayUtils.arrayTake(data, 4)));
        // Decode and assert calldata
        require(
            ArrayUtils.arrayEq(
                data,
                abi.encodeWithSignature(
                    "safeTransferFrom(address,address,uint256,uint256,bytes)",
                    addresses[1],
                    addresses[4],
                    nftGiveGet[0],
                    nftAmounts[0],
                    ""
                )
            )
        );
        // Decode and assert countercalldata
        require(
            ArrayUtils.arrayEq(
                counterdata,
                abi.encodeWithSignature(
                    "safeTransferFrom(address,address,uint256,uint256,bytes)",
                    addresses[4],
                    addresses[1],
                    nftGiveGet[1],
                    nftAmounts[1],
                    ""
                )
            )
        );

        // Mark filled
        return 1;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Proxy
 * @dev Gives the possibility to delegate any call to a foreign implementation.
 * @author OasisX Protocol | cryptoware.eth
 */
abstract contract Proxy {
    /**
     * @dev Tells the address of the implementation where every call will be delegated.
     * @return address of the implementation to which it will be delegated
     */
    function implementation() public view virtual returns (address);

    /**
     * @dev Tells the type of proxy (EIP 897)
     * @return proxyTypeId Type of proxy, 2 for upgradeable proxy
     */
    function proxyType() public pure virtual returns (uint256 proxyTypeId);

    /**
     * @dev Fallback function allowing to perform a delegatecall to the given implementation.
     * This function will return whatever the implementation call returns
     */
    fallback() external payable {
        common_fallback();
    }

    receive() external payable {
        common_fallback();
    }

    function common_fallback() internal {
        address _impl = implementation();
        require(_impl != address(0), "Proxy implementation required");

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 {
                revert(ptr, size)
            }
            default {
                return(ptr, size)
            }
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title OwnedUpgradeabilityStorage
 * @dev This contract keeps track of the upgradeability owner
 * @author OasisX Protocol | cryptoware.eth
 */
contract OwnedUpgradeabilityStorage {
    // Current implementation
    address internal _implementation;

    // Owner of the contract
    address private _upgradeabilityOwner;

    /**
     * @dev Tells the address of the owner
     * @return the address of the owner
     */
    function upgradeabilityOwner() public view returns (address) {
        return _upgradeabilityOwner;
    }

    /**
     * @dev Sets the address of the owner
     */
    function setUpgradeabilityOwner(address newUpgradeabilityOwner) internal {
        _upgradeabilityOwner = newUpgradeabilityOwner;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Proxy.sol";
import "./OwnedUpgradeabilityStorage.sol";

/**
 * @title OwnedUpgradeabilityProxy
 * @dev This contract combines an upgradeability proxy with basic authorization control functionalities
 * @author OasisX Protocol | cryptoware.eth
 */
contract OwnedUpgradeabilityProxy is Proxy, OwnedUpgradeabilityStorage {
    /**
     * @dev Event to show ownership has been transferred
     * @param previousOwner representing the address of the previous owner
     * @param newOwner representing the address of the new owner
     */
    event ProxyOwnershipTransferred(address previousOwner, address newOwner);

    /**
     * @dev This event will be emitted every time the implementation gets upgraded
     * @param implementation representing the address of the upgraded implementation
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Tells the address of the current implementation
     * @return address of the current implementation
     */
    function implementation() public view override returns (address) {
        return _implementation;
    }

    /**
     * @dev Tells the proxy type (EIP 897)
     * @return proxyTypeId Proxy type, 2 for forwarding proxy
     */
    function proxyType() public pure override returns (uint256 proxyTypeId) {
        return 2;
    }

    /**
     * @dev Upgrades the implementation address
     * @param impl representing the address of the new implementation to be set
     */
    function _upgradeTo(address impl) internal {
        require(
            _implementation != impl,
            "Proxy already uses this implementation"
        );
        _implementation = impl;
        emit Upgraded(impl);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyProxyOwner() {
        require(
            msg.sender == proxyOwner(),
            "Only the proxy owner can call this method"
        );
        _;
    }

    /**
     * @dev Tells the address of the proxy owner
     * @return the address of the proxy owner
     */
    function proxyOwner() public view returns (address) {
        return upgradeabilityOwner();
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferProxyOwnership(address newOwner) public onlyProxyOwner {
        require(newOwner != address(0), "New owner cannot be the null address");
        emit ProxyOwnershipTransferred(proxyOwner(), newOwner);
        setUpgradeabilityOwner(newOwner);
    }

    /**
     * @dev Allows the upgradeability owner to upgrade the current implementation of the proxy.
     * @param impl representing the address of the new implementation to be set.
     */
    function upgradeTo(address impl) public onlyProxyOwner {
        _upgradeTo(impl);
    }

    /**
     * @dev Allows the upgradeability owner to upgrade the current implementation of the proxy
     * and delegatecall the new implementation for initialization.
     * @param impl representing the address of the new implementation to be set.
     * @param data represents the msg.data to bet sent in the low level call. This parameter may include the function
     * signature of the implementation to be called with the needed payload
     */
    function upgradeToAndCall(address impl, bytes memory data)
        public
        payable
        onlyProxyOwner
    {
        upgradeTo(impl);
        (bool success, ) = address(this).delegatecall(data); /* solium-disable-line */
        require(success, "Call failed after proxy upgrade");
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title TokenRecipient
 * @author OasisX Protocol | cryptoware.eth
 */
contract TokenRecipient {
    event ReceivedEther(address indexed sender, uint256 amount);
    event ReceivedTokens(
        address indexed from,
        uint256 value,
        address indexed token,
        bytes extraData
    );

    /**
     * @dev Receive tokens and generate a log event
     * @param from Address from which to transfer tokens
     * @param value Amount of tokens to transfer
     * @param token Address of token
     * @param extraData Additional data to log
     */
    function receiveApproval(
        address from,
        uint256 value,
        address token,
        bytes memory extraData
    ) public {
        require(
            ERC20(token).transferFrom(from, address(this), value),
            "ERC20: token transfer failed"
        );
        emit ReceivedTokens(from, value, token, extraData);
    }

    /**
     * @dev Receive Ether and generate a log event
     */
    fallback() external payable {
        emit ReceivedEther(msg.sender, msg.value);
    }

    /**
     * @dev Receive Ether and generate a log event
     */
    receive() external payable {
        emit ReceivedEther(msg.sender, msg.value);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableDelegateProxy.sol";

/**
 * @title ProxyRegistryInterface
 * @author OasisX Protocol | cryptoware.eth
 */
interface ProxyRegistryInterface {
    function delegateProxyImplementation() external returns (address);

    function proxies(address owner) external returns (OwnableDelegateProxy);
}

/*

  Proxy registry; keeps a mapping of AuthenticatedProxy contracts and mapping of contracts authorized to access them.  
  
  Abstracted away from the Exchange (a) to reduce Exchange attack surface and (b) so that the Exchange contract can be upgraded without users needing to transfer assets to new proxies.

*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./OwnableDelegateProxy.sol";
import "./ProxyRegistryInterface.sol";

/**
 * @title ProxyRegistry
 * @author OasisX Protocol | cryptoware.eth
 */
contract ProxyRegistry is Ownable, ProxyRegistryInterface {
    /* DelegateProxy implementation contract. Must be initialized. */
    address public override delegateProxyImplementation;

    /* Authenticated proxies by user. */
    mapping(address => OwnableDelegateProxy) public override proxies;

    /* Contracts pending access. */
    mapping(address => uint256) public pending;

    /* Contracts allowed to call those proxies. */
    mapping(address => bool) public contracts;

    /* Delay period for adding an authenticated contract.
       This mitigates a particular class of potential attack on the OasisX DAO (which owns this registry) - if at any point the value of assets held by proxy contracts exceeded the value of half the OasisX supply (votes in the DAO),
       a malicious but rational attacker could buy half the OasisX and grant themselves access to all the proxy contracts. A delay period renders this attack nonthreatening - given three days, if that happened, users would have
       plenty of time to notice and transfer their assets.
    */
    uint256 public DELAY_PERIOD = 3 days;

    /**
     * Start the process to enable access for specified contract. Subject to delay period.
     *
     * @dev ProxyRegistry owner only
     * @param addr Address to which to grant permissions
     */
    function startGrantAuthentication(address addr) public onlyOwner {
        require(
            !contracts[addr] && pending[addr] == 0,
            "Contract is already allowed in registry, or pending"
        );
        pending[addr] = block.timestamp;
    }

    /**
     * End the process to enable access for specified contract after delay period has passed.
     *
     * @dev ProxyRegistry owner only
     * @param addr Address to which to grant permissions
     */
    function endGrantAuthentication(address addr) public onlyOwner {
        require(
            !contracts[addr] &&
                pending[addr] != 0 &&
                ((pending[addr] + DELAY_PERIOD) < block.timestamp),
            "Contract is no longer pending or has already been approved by registry"
        );
        pending[addr] = 0;
        contracts[addr] = true;
    }

    /**
     * Revoke access for specified contract. Can be done instantly.
     *
     * @dev ProxyRegistry owner only
     * @param addr Address of which to revoke permissions
     */
    function revokeAuthentication(address addr) public onlyOwner {
        contracts[addr] = false;
    }

    /**
     * Register a proxy contract with this registry
     *
     * @dev Must be called by the user which the proxy is for, creates a new AuthenticatedProxy
     * @return proxy New AuthenticatedProxy contract
     */
    function registerProxy() public returns (OwnableDelegateProxy proxy) {
        return registerProxyFor(msg.sender);
    }

    /**
     * Register a proxy contract with this registry, overriding any existing proxy
     *
     * @dev Must be called by the user which the proxy is for, creates a new AuthenticatedProxy
     * @return proxy New AuthenticatedProxy contract
     */
    function registerProxyOverride()
        public
        returns (OwnableDelegateProxy proxy)
    {
        proxy = new OwnableDelegateProxy(
            msg.sender,
            delegateProxyImplementation,
            abi.encodeWithSignature(
                "initialize(address,address)",
                msg.sender,
                address(this)
            )
        );
        proxies[msg.sender] = proxy;
        return proxy;
    }

    /**
     * Register a proxy contract with this registry
     * @dev Can be called by any user
     * @return proxy New AuthenticatedProxy contract
     */
    function registerProxyFor(address user)
        public
        returns (OwnableDelegateProxy proxy)
    {
        require(
            proxies[user] == OwnableDelegateProxy(payable(0)),
            "User already has a proxy"
        );
        proxy = new OwnableDelegateProxy(
            user,
            delegateProxyImplementation,
            abi.encodeWithSignature(
                "initialize(address,address)",
                user,
                address(this)
            )
        );
        proxies[user] = proxy;
        return proxy;
    }

    /**
     * Transfer access
     */
    function transferAccessTo(address from, address to) public {
        OwnableDelegateProxy proxy = proxies[from];

        /* CHECKS */
        require(
            OwnableDelegateProxy(payable(msg.sender)) == proxy,
            "Proxy transfer can only be called by the proxy"
        );
        require(
            proxies[to] == OwnableDelegateProxy(payable(0)),
            "Proxy transfer has existing proxy as destination"
        );

        /* EFFECTS */
        delete proxies[from];
        proxies[to] = proxy;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./proxy/OwnedUpgradeabilityProxy.sol";

/**
 * @title OwnableDelegateProxy
 * @author OasisX Protocol | cryptoware.eth
 */
contract OwnableDelegateProxy is OwnedUpgradeabilityProxy {
    constructor(
        address owner,
        address initialImplementation,
        bytes memory data
    ) {
        setUpgradeabilityOwner(owner);
        _upgradeTo(initialImplementation);
        (bool success, ) = initialImplementation.delegatecall(data); /* solium-disable-line */
        require(success, "OwnableDelegateProxy failed implementation");
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ProxyRegistry.sol";
import "./TokenRecipient.sol";
import "./proxy/OwnedUpgradeabilityStorage.sol";

/**
 * @title AuthenticatedProxy
 * @author OasisX Protocol | cryptoware.eth
 * @notice Proxy contract to hold access to assets on behalf of a user (e.g. ERC20 approve) and execute calls under particular conditions.
 */
contract AuthenticatedProxy is TokenRecipient, OwnedUpgradeabilityStorage {
    /* Whether initialized. */
    bool initialized = false;

    /* Address which owns this proxy. */
    address public user;

    /* Associated registry with contract authentication information. */
    ProxyRegistry public registry;

    /* Whether access has been revoked. */
    bool public revoked;

    /* Delegate call could be used to atomically transfer multiple assets owned by the proxy contract with one order. */
    enum HowToCall {
        Call,
        DelegateCall
    }

    /* Event fired when the proxy access is revoked or unrevoked. */
    event Revoked(bool revoked);

    /**
     * Initialize an AuthenticatedProxy
     *
     * @param addrUser Address of user on whose behalf this proxy will act
     * @param addrRegistry Address of ProxyRegistry contract which will manage this proxy
     */
    function initialize(address addrUser, ProxyRegistry addrRegistry) public {
        require(!initialized, "Authenticated proxy already initialized");
        initialized = true;
        user = addrUser;
        registry = addrRegistry;
    }

    /**
     * Set the revoked flag (allows a user to revoke ProxyRegistry access)
     *
     * @dev Can be called by the user only
     * @param revoke Whether or not to revoke access
     */
    function setRevoke(bool revoke) public {
        require(
            msg.sender == user,
            "Authenticated proxy can only be revoked by its user"
        );
        revoked = revoke;
        emit Revoked(revoke);
    }

    /**
     * Execute a message call from the proxy contract
     *
     * @dev Can be called by the user, or by a contract authorized by the registry as long as the user has not revoked access
     * @param dest Address to which the call will be sent
     * @param howToCall Which kind of call to make
     * @param data Calldata to send
     * @return result Result of the call (success or failure)
     */
    function proxy(
        address dest,
        HowToCall howToCall,
        bytes memory data
    ) public returns (bool result) {
        require(
            msg.sender == user || (!revoked && registry.contracts(msg.sender)),
            "Authenticated proxy can only be called by its user, or by a contract authorized by the registry as long as the user has not revoked access"
        );
        bytes memory ret;
        if (howToCall == HowToCall.Call) {
            (result, ret) = dest.call(data); /* solium-disable-line */
        } else if (howToCall == HowToCall.DelegateCall) {
            (result, ret) = dest.delegatecall(data); /* solium-disable-line */
        }
        return result;
    }

    /**
     * Execute a message call and assert success
     * @dev Same functionality as `proxy`, just asserts the return value
     * @param dest Address to which the call will be sent
     * @param howToCall What kind of call to make
     * @param data Calldata to send
     */
    function proxyAssert(
        address dest,
        HowToCall howToCall,
        bytes memory data
    ) public {
        require(proxy(dest, howToCall, data), "Proxy assertion failed");
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title StaticCaller
 * @author OasisX Protocol | cryptoware.eth
 */
abstract contract StaticCaller {
    function staticCall(address target, bytes memory data)
        internal
        view
        returns (bool result)
    {
        assembly {
            /* solium-disable-line */
            result := staticcall(
                gas(),
                target,
                add(data, 0x20),
                mload(data),
                mload(0x40),
                0
            )
        }
        return result;
    }

    function staticCallUint(address target, bytes memory data)
        internal
        view
        returns (uint256 ret)
    {
        bool result;
        assembly {
            /* solium-disable-line */
            let size := 0x20
            let free := mload(0x40)
            result := staticcall(
                gas(),
                target,
                add(data, 0x20),
                mload(data),
                free,
                size
            )
            ret := mload(free)
        }
        require(result, "Static call failed");
        return ret;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ArrayUtils
 * @author OasisX Protocol | cryptoware.eth
 */
library ArrayUtils {
    /**
     * Replace bytes in an array with bytes in another array, guarded by a bitmask
     * Efficiency of this function is a bit unpredictable because of the EVM's word-specific model (arrays under 32 bytes will be slower)
     * Modifies the provided byte array parameter in place
     *
     * @dev Mask must be the size of the byte array. A nonzero byte means the byte array can be changed.
     * @param array The original array
     * @param desired The target array
     * @param mask The mask specifying which bits can be changed
     */
    function guardedArrayReplace(
        bytes memory array,
        bytes memory desired,
        bytes memory mask
    ) internal pure {
        require(
            array.length == desired.length,
            "Arrays have different lengths"
        );
        require(
            array.length == mask.length,
            "Array and mask have different lengths"
        );

        uint256 words = array.length / 0x20;
        uint256 index = words * 0x20;
        assert(index / 0x20 == words);
        uint256 i;

        for (i = 0; i < words; i++) {
            /* Conceptually: array[i] = (!mask[i] && array[i]) || (mask[i] && desired[i]), bitwise in word chunks. */
            assembly {
                /* solium-disable-line */
                let commonIndex := mul(0x20, add(1, i))
                let maskValue := mload(add(mask, commonIndex))
                mstore(
                    add(array, commonIndex),
                    or(
                        and(not(maskValue), mload(add(array, commonIndex))),
                        and(maskValue, mload(add(desired, commonIndex)))
                    )
                )
            }
        }

        /* Deal with the last section of the byte array. */
        if (words > 0) {
            /* This overlaps with bytes already set but is still more efficient than iterating through each of the remaining bytes individually. */
            i = words;
            assembly {
                /* solium-disable-line */
                let commonIndex := mul(0x20, add(1, i))
                let maskValue := mload(add(mask, commonIndex))
                mstore(
                    add(array, commonIndex),
                    or(
                        and(not(maskValue), mload(add(array, commonIndex))),
                        and(maskValue, mload(add(desired, commonIndex)))
                    )
                )
            }
        } else {
            /* If the byte array is shorter than a word, we must unfortunately do the whole thing bytewise.
               (bounds checks could still probably be optimized away in assembly, but this is a rare case) */
            for (i = index; i < array.length; i++) {
                array[i] =
                    ((mask[i] ^ 0xff) & array[i]) |
                    (mask[i] & desired[i]);
            }
        }
    }

    /**
     * Test if two arrays are equal
     * Source: https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol
     *
     * @dev Arrays must be of equal length, otherwise will return false
     * @param a First array
     * @param b Second array
     * @return Whether or not all bytes in the arrays are equal
     */
    function arrayEq(bytes memory a, bytes memory b)
        internal
        pure
        returns (bool)
    {
        bool success = true;

        assembly {
            /* solium-disable-line */
            let length := mload(a)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(b))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(a, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(b, 0x20)
                    // the next line is the loop condition:
                    // while(uint(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    /**
     * Drop the beginning of an array
     *
     * @param _bytes array
     * @param _start start index
     * @return Whether or not all bytes in the arrays are equal
     */
    function arrayDrop(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (bytes memory)
    {
        uint256 _length = _bytes.length - _start;
        return arraySlice(_bytes, _start, _length);
    }

    /**
     * Take from the beginning of an array
     *
     * @param _bytes array
     * @param _length elements to take
     * @return Whether or not all bytes in the arrays are equal
     */
    function arrayTake(bytes memory _bytes, uint256 _length)
        internal
        pure
        returns (bytes memory)
    {
        return arraySlice(_bytes, 0, _length);
    }

    /**
     * Slice an array
     * Source: https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol
     *
     * @param _bytes array
     * @param _start start index
     * @param _length length to take
     * @return Whether or not all bytes in the arrays are equal
     */
    function arraySlice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        bytes memory tempBytes;

        assembly {
            /* solium-disable-line */
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(
                    add(tempBytes, lengthmod),
                    mul(0x20, iszero(lengthmod))
                )
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(
                        add(
                            add(_bytes, lengthmod),
                            mul(0x20, iszero(lengthmod))
                        ),
                        _start
                    )
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    /**
     * Unsafe write byte array into a memory location
     *
     * @param index Memory location
     * @param source Byte array to write
     * @return End memory index
     */
    function unsafeWriteBytes(uint256 index, bytes memory source)
        internal
        pure
        returns (uint256)
    {
        if (source.length > 0) {
            assembly {
                /* solium-disable-line */
                let length := mload(source)
                let end := add(source, add(0x20, length))
                let arrIndex := add(source, 0x20)
                let tempIndex := index
                for {

                } eq(lt(arrIndex, end), 1) {
                    arrIndex := add(arrIndex, 0x20)
                    tempIndex := add(tempIndex, 0x20)
                } {
                    mstore(tempIndex, mload(arrIndex))
                }
                index := add(index, length)
            }
        }
        return index;
    }

    /**
     * Unsafe write address into a memory location
     *
     * @param index Memory location
     * @param source Address to write
     * @return End memory index
     */
    function unsafeWriteAddress(uint256 index, address source)
        internal
        pure
        returns (uint256)
    {
        uint256 conv = uint256(uint160(source)) << 0x60;
        assembly {
            /* solium-disable-line */
            mstore(index, conv)
            index := add(index, 0x14)
        }
        return index;
    }

    /**
     * Unsafe write uint into a memory location
     *
     * @param index Memory location
     * @param source uint to write
     * @return End memory index
     */
    function unsafeWriteUint(uint256 index, uint256 source)
        internal
        pure
        returns (uint256)
    {
        assembly {
            /* solium-disable-line */
            mstore(index, source)
            index := add(index, 0x20)
        }
        return index;
    }

    /**
     * Unsafe write uint8 into a memory location
     *
     * @param index Memory location
     * @param source uint8 to write
     * @return End memory index
     */
    function unsafeWriteUint8(uint256 index, uint8 source)
        internal
        pure
        returns (uint256)
    {
        assembly {
            /* solium-disable-line */
            mstore8(index, source)
            index := add(index, 0x1)
        }
        return index;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}