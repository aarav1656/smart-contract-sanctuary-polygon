// SPDX-License-Identifier:	BSD-2-Clause

// Mango.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
pragma solidity ^0.8.10;

pragma abicoder v2;

import "./MangoStorage.sol";
import "./MangoImplementation.sol";
import "../../abstract/Direct.sol";
import "../../../routers/AbstractRouter.sol";
import "../../../routers/SimpleRouter.sol";
import {MgvLib} from "mgv_src/MgvLib.sol";

/**
 * Discrete automated market making strat
 */
/**
 * This AMM is headless (no price model) and market makes on `NSLOTS` price ranges
 */
/**
 * current `Pmin` is the price of an offer at position `0`, current `Pmax` is the price of an offer at position `NSLOTS-1`
 */
/**
 * Initially `Pmin = P(0) = QUOTE_0/BASE_0` and the general term is P(i) = __quote_progression__(i)/BASE_0
 */
/**
 * NB `__quote_progression__` is a hook that defines how price increases with positions and is by default an arithmetic progression, i.e __quote_progression__(i) = QUOTE_0 + `delta`*i
 */
/**
 * When one of its offer is matched on Mangrove, the headless strat does the following:
 */
/**
 * Each time this strat receives b `BASE` tokens (bid was taken) at price position i, it increases the offered (`BASE`) volume of the ask at position i+1 of 'b'
 */
/**
 * Each time this strat receives q `QUOTE` tokens (ask was taken) at price position i, it increases the offered (`QUOTE`) volume of the bid at position i-1 of 'q'
 */
/**
 * In case of a partial fill of an offer at position i, the offer residual is reposted (see `Persistent` strat class)
 */

contract Mango is Direct {
  // emitted when init function has been called and AMM becomes active
  event Initialized(uint from, uint to);

  address private immutable IMPLEMENTATION;

  uint public immutable NSLOTS;
  IERC20 public immutable BASE;
  IERC20 public immutable QUOTE;

  // Asks and bids offer Ids are stored in `ASKS` and `BIDS` arrays respectively.

  constructor(
    IMangrove mgv,
    IERC20 base,
    IERC20 quote,
    uint base_0,
    uint quote_0,
    uint nslots,
    uint price_incr,
    address deployer
  )
    Direct(
      mgv,
      new SimpleRouter() // routes liqudity from (to) reserve to (from) this contract
    )
  {
    MangoStorage.Layout storage mStr = MangoStorage.getStorage();
    AbstractRouter router_ = router();

    // sanity check
    require(
      nslots > 0 && address(mgv) != address(0) && uint16(nslots) == nslots && uint96(base_0) == base_0
        && uint96(quote_0) == quote_0,
      "Mango/constructor/invalidArguments"
    );

    NSLOTS = nslots;

    // implementation should have correct immutables
    IMPLEMENTATION = address(
      new MangoImplementation(
        mgv,
        base,
        quote,
        uint96(base_0),
        uint96(quote_0),
        nslots
      )
    );
    BASE = base;
    QUOTE = quote;
    // setting local storage
    mStr.asks = new uint[](nslots);
    mStr.bids = new uint[](nslots);
    mStr.delta = price_incr;
    // logs `BID/ASKatMin/MaxPosition` events when only 1 slot remains
    mStr.min_buffer = 1;

    // activates Mango on `quote` and `base`
    __activate__(base);
    __activate__(quote);

    // in order to let deployer's EOA have control over liquidity
    setReserve(deployer);

    // adding `this` to the authorized makers of the router.
    router_.bind(address(this));
    // `this` deployed the router, letting admin take control over it.
    router_.setAdmin(deployer);

    // should cover cost of reposting the offer + dual offer
    setGasreq(150_000);

    // setting admin of contract if a static address deployment was used
    if (deployer != msg.sender) {
      setAdmin(deployer);
    }
  }

  // populate mangrove order book with bids or/and asks in the price range R = [`from`, `to`[
  // tokenAmounts are always expressed `gives`units, i.e in BASE when asking and in QUOTE when bidding
  function initialize(
    bool reset,
    uint lastBidPosition, // if `lastBidPosition` is in R, then all offers before `lastBidPosition` (included) will be bids, offers strictly after will be asks.
    uint from, // first price position to be populated
    uint to, // last price position to be populated
    uint[][2] calldata pivotIds, // `pivotIds[0][i]` ith pivots for bids, `pivotIds[1][i]` ith pivot for asks
    uint[] calldata tokenAmounts // `tokenAmounts[i]` is the amount of `BASE` or `QUOTE` tokens (dePENDING on `withBase` flag) that is used to fixed one parameter of the price at position `from+i`.
  ) public mgvOrAdmin {
    // making sure a router has been defined between deployment and initialization
    require(address(router()) != address(0), "Mango/initialize/0xRouter");

    (bool success, bytes memory retdata) = IMPLEMENTATION.delegatecall(
      abi.encodeWithSelector(
        MangoImplementation.$initialize.selector,
        reset,
        lastBidPosition,
        from,
        to,
        pivotIds,
        tokenAmounts,
        offerGasreq()
      )
    );
    if (!success) {
      MangoStorage.revertWithData(retdata);
    } else {
      emit Initialized({from: from, to: to});
    }
  }

  function resetPending() external onlyAdmin {
    MangoStorage.Layout storage mStr = MangoStorage.getStorage();
    mStr.pending_base = 0;
    mStr.pending_quote = 0;
  }

  /**
   * Setters and getters
   */
  function delta() external view onlyAdmin returns (uint) {
    return MangoStorage.getStorage().delta;
  }

  function setDelta(uint _delta) public mgvOrAdmin {
    MangoStorage.getStorage().delta = _delta;
  }

  function shift() external view onlyAdmin returns (int) {
    return MangoStorage.getStorage().shift;
  }

  function pending() external view onlyAdmin returns (uint[2] memory) {
    MangoStorage.Layout storage mStr = MangoStorage.getStorage();
    return [mStr.pending_base, mStr.pending_quote];
  }

  // with ba=0:bids only, ba=1: asks only ba>1 all
  function retractOffers(uint ba, uint from, uint to) external onlyAdmin returns (uint collected) {
    // with ba=0:bids only, ba=1: asks only ba>1 all
    MangoStorage.Layout storage mStr = MangoStorage.getStorage();
    for (uint i = from; i < to; i++) {
      if (ba > 0) {
        // asks or bids+asks
        collected += mStr.asks[i] > 0 ? retractOffer(BASE, QUOTE, mStr.asks[i], true) : 0;
      }
      if (ba == 0 || ba > 1) {
        // bids or bids + asks
        collected += mStr.bids[i] > 0 ? retractOffer(QUOTE, BASE, mStr.bids[i], true) : 0;
      }
    }
  }

  /**
   * Shift the price (induced by quote amount) of n slots down or up
   */
  /**
   * price at position i will be shifted (up or down dePENDING on the sign of `shift`)
   */
  /**
   * New positions 0<= i < s are initialized with amount[i] in base tokens if `withBase`. In quote tokens otherwise
   */
  function setShift(int s, bool withBase, uint[] calldata amounts) public mgvOrAdmin {
    (bool success, bytes memory retdata) = IMPLEMENTATION.delegatecall(
      abi.encodeWithSelector(MangoImplementation.$setShift.selector, s, withBase, amounts, offerGasreq())
    );
    if (!success) {
      MangoStorage.revertWithData(retdata);
    }
  }

  function setMinOfferType(uint m) external mgvOrAdmin {
    MangoStorage.getStorage().min_buffer = m;
  }

  function _staticdelegatecall(bytes calldata data) external onlyCaller(address(this)) {
    (bool success, bytes memory retdata) = IMPLEMENTATION.delegatecall(data);
    if (!success) {
      MangoStorage.revertWithData(retdata);
    }
    assembly {
      return(add(retdata, 32), returndatasize())
    }
  }

  // return Mango offer Ids on Mangrove. If `liveOnly` will only return offer Ids that are live (0 otherwise).
  function getOffers(bool liveOnly) external view returns (uint[][2] memory offers) {
    (bool success, bytes memory retdata) = address(this).staticcall(
      abi.encodeWithSelector(
        this._staticdelegatecall.selector, abi.encodeWithSelector(MangoImplementation.$getOffers.selector, liveOnly)
      )
    );
    if (!success) {
      MangoStorage.revertWithData(retdata);
    } else {
      return abi.decode(retdata, (uint[][2]));
    }
  }

  // starts reneging all offers
  // NB reneged offers will not be reposted
  function pause() public mgvOrAdmin {
    MangoStorage.getStorage().paused = true;
  }

  function restart() external onlyAdmin {
    MangoStorage.getStorage().paused = false;
  }

  function isPaused() external view returns (bool) {
    return MangoStorage.getStorage().paused;
  }

  // this overrides is read during `makerExecute` call (see `MangroveOffer`)
  function __lastLook__(MgvLib.SingleOrder calldata order) internal virtual override returns (bytes32) {
    order; //shh
    require(!MangoStorage.getStorage().paused, "Mango/paused");
    return "";
  }

  // residual gives is default (i.e offer.gives - order.wants) + PENDING
  // this overrides the corresponding function in `Persistent`
  function __residualGives__(MgvLib.SingleOrder calldata order) internal virtual override returns (uint) {
    MangoStorage.Layout storage mStr = MangoStorage.getStorage();
    if (order.outbound_tkn == address(BASE)) {
      // Ask offer
      return super.__residualGives__(order) + mStr.pending_base;
    } else {
      // Bid offer
      return super.__residualGives__(order) + mStr.pending_quote;
    }
  }

  // for reposting partial filled offers one always gives the residual (default behavior)
  // and adapts wants to the new price (if different).
  // this overrides the corresponding function in `Persistent`
  function __residualWants__(MgvLib.SingleOrder calldata order) internal virtual override returns (uint) {
    uint residual = __residualGives__(order);
    if (residual == 0) {
      return 0;
    }
    (bool success, bytes memory retdata) =
      IMPLEMENTATION.delegatecall(abi.encodeWithSelector(MangoImplementation.$residualWants.selector, order, residual));
    if (!success) {
      MangoStorage.revertWithData(retdata);
    } else {
      return abi.decode(retdata, (uint));
    }
  }

  function __posthookSuccess__(MgvLib.SingleOrder calldata order, bytes32 maker_data)
    internal
    virtual
    override
    returns (bytes32)
  {
    MangoStorage.Layout storage mStr = MangoStorage.getStorage();
    bytes32 posthook_data = super.__posthookSuccess__(order, maker_data);
    // checking whether repost failed
    bool repost_success = (posthook_data == "posthook/reposted" || posthook_data == "posthook/completeFill");
    if (order.outbound_tkn == address(BASE)) {
      if (!repost_success) {
        // residual could not be reposted --either below density or Mango went out of provision on Mangrove
        mStr.pending_base = __residualGives__(order); // this includes previous `pending_base`
      } else {
        mStr.pending_base = 0;
      }
    } else {
      if (!repost_success) {
        // residual could not be reposted --either below density or Mango went out of provision on Mangrove
        mStr.pending_quote = __residualGives__(order); // this includes previous `pending_base`
      } else {
        mStr.pending_quote = 0;
      }
    }

    (bool success, bytes memory retdata) = IMPLEMENTATION.delegatecall(
      abi.encodeWithSelector(MangoImplementation.$postDualOffer.selector, order, offerGasreq())
    );
    if (!success) {
      MangoStorage.revertWithData(retdata);
    } else {
      return abi.decode(retdata, (bytes32));
    }
  }
}

// SPDX-License-Identifier:	BSD-2-Clause

// MangoStorage.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
pragma solidity ^0.8.10;

pragma abicoder v2;

import "mgv_src/strategies/routers/AbstractRouter.sol";

library MangoStorage {
  /**
   * Strat specific events
   */

  struct Layout {
    uint[] asks;
    uint[] bids;
    // amount of base (resp quote) tokens that failed to be published on the Market
    uint pending_base;
    uint pending_quote;
    // offerId -> index in ASKS/BIDS maps
    mapping(uint => uint) index_of_bid; // bidId -> index
    mapping(uint => uint) index_of_ask; // askId -> index
    // Price shift is in number of price increments (or decrements when shift < 0) since deployment of the strat.
    // e.g. for arithmetic progression, `shift = -3` indicates that Pmin is now (`QUOTE_0` - 3*`delta`)/`BASE_0`
    int shift;
    // parameter for price progression
    // NB for arithmetic progression, price(i+1) = price(i) + delta/`BASE_0`
    uint delta; // quote increment
    // triggers `__boundariesReached__` whenever amounts of bids/asks is below `min_buffer`
    uint min_buffer;
    // puts the strat into a (cancellable) state where it reneges on all incoming taker orders.
    // NB reneged offers are removed from Mangrove's OB
    bool paused;
    // Base and quote router contract
    AbstractRouter router;
    // reserve address for the router (external treasury -e.g EOA-, Mango or the router itself)
    // if the router is lender based, this is the location of the overlying
    address reserve;
  }

  function getStorage() internal pure returns (Layout storage st) {
    bytes32 storagePosition = keccak256("Mangrove.MangoStorage.Layout");
    assembly {
      st.slot := storagePosition
    }
  }

  function revertWithData(bytes memory retdata) internal pure {
    if (retdata.length == 0) {
      revert("MangoStorage/revertNoReason");
    }
    assembly {
      revert(add(retdata, 32), mload(retdata))
    }
  }

  function quote_price_jumps(uint delta, uint position, uint quote_min) internal pure returns (uint) {
    return delta * position + quote_min;
  }
}

// SPDX-License-Identifier:	BSD-2-Clause

// MangoImplementation.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
pragma solidity ^0.8.10;

pragma abicoder v2;

import "mgv_src/IMangrove.sol";
import "./MangoStorage.sol";
import "mgv_src/strategies/utils/TransferLib.sol";
import {MgvLib, MgvStructs} from "mgv_src/MgvLib.sol";

//import "../routers/AbstractRouter.sol";

/**
 * Discrete automated market making strat
 */
/**
 * This AMM is headless (no price model) and market makes on `NSLOTS` price ranges
 */
/**
 * current `Pmin` is the price of an offer at position `0`, current `Pmax` is the price of an offer at position `NSLOTS-1`
 */
/**
 * Initially `Pmin = P(0) = QUOTE_0/BASE_0` and the general term is P(i) = __quote_progression__(i)/BASE_0
 */
/**
 * NB `__quote_progression__` is a hook that defines how price increases with positions and is by default an arithmetic progression, i.e __quote_progression__(i) = QUOTE_0 + `delta`*i
 */
/**
 * When one of its offer is matched on Mangrove, the headless strat does the following:
 */
/**
 * Each time this strat receives b `BASE` tokens (bid was taken) at price position i, it increases the offered (`BASE`) volume of the ask at position i+1 of 'b'
 */
/**
 * Each time this strat receives q `QUOTE` tokens (ask was taken) at price position i, it increases the offered (`QUOTE`) volume of the bid at position i-1 of 'q'
 */
/**
 * In case of a partial fill of an offer at position i, the offer residual is reposted (see `Persistent` strat class)
 */

contract MangoImplementation {
  event BidAtMaxPosition();
  // emitted when strat has reached max amount of Asks and needs rebalancing (should shift of x<0 positions in order to have ask prices that are better for the taker)
  event AskAtMinPosition();

  modifier delegated() {
    require(address(this) == PROXY, "MangoImplementation/invalidCall");
    _;
  }

  // total number of Asks (resp. Bids)
  uint immutable NSLOTS;
  // initial min price given by `QUOTE_0/BASE_0`
  uint96 immutable BASE_0;
  uint96 immutable QUOTE_0;
  // Market on which Mango will be acting
  IERC20 immutable BASE;
  IERC20 immutable QUOTE;

  address immutable PROXY;
  IMangrove immutable MGV;

  constructor(IMangrove mgv, IERC20 base, IERC20 quote, uint96 base_0, uint96 quote_0, uint nslots) {
    // setting immutable fields to match those of `Mango`
    MGV = mgv;
    BASE = base;
    QUOTE = quote;
    NSLOTS = nslots;
    BASE_0 = base_0;
    QUOTE_0 = quote_0;
    PROXY = msg.sender;
  }

  // populate mangrove order book with bids or/and asks in the price range R = [`from`, `to`[
  // tokenAmounts are always expressed `gives`units, i.e in BASE when asking and in QUOTE when bidding
  function $initialize(
    bool reset,
    uint lastBidPosition, // if `lastBidPosition` is in R, then all offers before `lastBidPosition` (included) will be bids, offers strictly after will be asks.
    uint from, // first price position to be populated
    uint to, // last price position to be populated
    uint[][2] calldata pivotIds, // `pivotIds[0][i]` ith pivots for bids, `pivotIds[1][i]` ith pivot for asks
    uint[] calldata tokenAmounts, // `tokenAmounts[i]` is the amount of `BASE` or `QUOTE` tokens (dePENDING on `withBase` flag) that is used to fixed one parameter of the price at position `from+i`.
    uint gasreq // gas required for new offers
  ) external delegated {
    MangoStorage.Layout storage mStr = MangoStorage.getStorage();
    /**
     * Initializing Asks and Bids
     */
    /**
     * NB we assume Mangrove is already provisioned for posting NSLOTS asks and NSLOTS bids
     */
    /**
     * NB cannot post newOffer with infinite gasreq since fallback ofr_gasreq is not defined yet (and default is likely wrong)
     */
    require(to > from, "Mango/initialize/invalidSlice");
    require(
      tokenAmounts.length == NSLOTS && pivotIds.length == 2 && pivotIds[0].length == NSLOTS
        && pivotIds[1].length == NSLOTS,
      "Mango/initialize/invalidArrayLength"
    );
    require(lastBidPosition < NSLOTS - 1, "Mango/initialize/NoSlotForAsks"); // bidding => slice doesn't fill the book
    uint pos;
    for (pos = from; pos < to; pos++) {
      // if shift is not 0, must convert
      uint i = index_of_position(pos);

      if (pos <= lastBidPosition) {
        uint bidPivot = pivotIds[0][pos];
        bidPivot = bidPivot > 0
          ? bidPivot // taking pivot from the user
          : pos > 0 ? mStr.bids[index_of_position(pos - 1)] : 0; // otherwise getting last inserted offer as pivot
        updateBid({
          index: i,
          reset: reset, // overwrites old value
          amount: tokenAmounts[pos],
          pivotId: bidPivot,
          gasreq: gasreq
        });
        if (mStr.asks[i] > 0) {
          // if an ASK is also positioned, remove it to prevent spread crossing
          // (should not happen if this is the first initialization of the strat)
          MGV.retractOffer(address(BASE), address(QUOTE), mStr.asks[i], false);
        }
      } else {
        uint askPivot = pivotIds[1][pos];
        askPivot = askPivot > 0
          ? askPivot // taking pivot from the user
          : pos > 0 ? mStr.asks[index_of_position(pos - 1)] : 0; // otherwise getting last inserted offer as pivot
        updateAsk({index: i, reset: reset, amount: tokenAmounts[pos], pivotId: askPivot, gasreq: gasreq});
        if (mStr.bids[i] > 0) {
          // if a BID is also positioned, remove it to prevent spread crossing
          // (should not happen if this is the first initialization of the strat)
          MGV.retractOffer(address(QUOTE), address(BASE), mStr.bids[i], false);
        }
      }
    }
  }

  /**
   * Shift the price (induced by quote amount) of n slots down or up
   */
  /**
   * price at position i will be shifted (up or down dePENDING on the sign of `shift`)
   */
  /**
   * New positions 0<= i < s are initialized with amount[i] in base tokens if `withBase`. In quote tokens otherwise
   */
  function $setShift(int s, bool withBase, uint[] calldata amounts, uint gasreq) external delegated {
    require(amounts.length == (s < 0 ? uint(-s) : uint(s)), "Mango/setShift/notEnoughAmounts");
    if (s < 0) {
      negative_shift(uint(-s), withBase, amounts, gasreq);
    } else {
      positive_shift(uint(s), withBase, amounts, gasreq);
    }
  }

  // return Mango offer Ids on Mangrove. If `liveOnly` will only return offer Ids that are live (0 otherwise).
  function $getOffers(bool liveOnly) external view returns (uint[][2] memory offers) {
    MangoStorage.Layout storage mStr = MangoStorage.getStorage();
    offers[0] = new uint[](NSLOTS);
    offers[1] = new uint[](NSLOTS);
    for (uint i = 0; i < NSLOTS; i++) {
      uint askId = mStr.asks[index_of_position(i)];
      uint bidId = mStr.bids[index_of_position(i)];

      offers[0][i] = (MGV.offers(address(QUOTE), address(BASE), bidId).gives() > 0 || !liveOnly)
        ? mStr.bids[index_of_position(i)]
        : 0;
      offers[1][i] = (MGV.offers(address(BASE), address(QUOTE), askId).gives() > 0 || !liveOnly)
        ? mStr.asks[index_of_position(i)]
        : 0;
    }
  }

  struct WriteData {
    uint index;
    uint wants;
    uint gives;
    uint ofr_gr;
    uint pivotId;
    bool allowPending;
  }

  // posts or updates ask at position of `index`
  // returns the amount of `BASE` tokens that failed to be published at that position
  // `writeOffer` is split into `writeAsk` and `writeBid` to avoid stack too deep exception
  function writeAsk(WriteData memory wd) internal returns (uint) {
    MangoStorage.Layout storage mStr = MangoStorage.getStorage();
    if (mStr.asks[wd.index] == 0) {
      // offer slot not initialized yet
      try MGV.newOffer({
        outbound_tkn: address(BASE),
        inbound_tkn: address(QUOTE),
        wants: wd.wants,
        gives: wd.gives,
        gasreq: wd.ofr_gr,
        gasprice: 0,
        pivotId: wd.pivotId
      }) returns (uint offerId) {
        mStr.asks[wd.index] = offerId;
        mStr.index_of_ask[mStr.asks[wd.index]] = wd.index;
        return 0;
      } catch Error(string memory reason){
        if (wd.allowPending) {
        // `newOffer` can fail when Mango is underprovisioned or if `offer.gives` is below density
          return wd.gives;
        } else {
          revert(reason);
        }
      }
    } else {
      try MGV.updateOffer({
        outbound_tkn: address(BASE),
        inbound_tkn: address(QUOTE),
        wants: wd.wants,
        gives: wd.gives,
        gasreq: wd.ofr_gr,
        gasprice: 0,
        pivotId: wd.pivotId,
        offerId: mStr.asks[wd.index]
      }) {
        // updateOffer succeeded
        return 0;
      } catch Error(string memory reason){
        if (wd.allowPending) {
          // update offer might fail because residual is below density (this is OK)
          // it may also fail because there is not enough provision on Mangrove (this is Not OK so we log)
          // updateOffer failed but `offer` might still be live (i.e with `offer.gives>0`)
          uint oldGives = MGV.offers(address(BASE), address(QUOTE), mStr.asks[wd.index]).gives();
          // if not during initialize we necessarily have gives > oldGives
          // otherwise we are trying to reset the offer and oldGives is irrelevant
          return (wd.gives > oldGives) ? wd.gives - oldGives : wd.gives;
        } else {
          revert(reason);
        }
      }
    }
  }

  function writeBid(WriteData memory wd) internal returns (uint) {
    MangoStorage.Layout storage mStr = MangoStorage.getStorage();
    if (mStr.bids[wd.index] == 0) {
      try MGV.newOffer({
        outbound_tkn: address(QUOTE),
        inbound_tkn: address(BASE),
        wants: wd.wants,
        gives: wd.gives,
        gasreq: wd.ofr_gr,
        gasprice: 0,
        pivotId: wd.pivotId
      }) returns (uint offerId) {
        mStr.bids[wd.index] = offerId;
        mStr.index_of_bid[mStr.bids[wd.index]] = wd.index;
        return 0;
      } catch Error (string memory reason) {
        if (wd.allowPending) {
          return wd.gives;
        } else {
          revert(reason);
        }

      }
    } else {
      try MGV.updateOffer({
        outbound_tkn: address(QUOTE),
        inbound_tkn: address(BASE),
        wants: wd.wants,
        gives: wd.gives,
        gasreq: wd.ofr_gr,
        gasprice: 0,
        pivotId: wd.pivotId,
        offerId: mStr.bids[wd.index]
      }) {
        return 0;
      } catch Error(string memory reason) {
        if (wd.allowPending) {
          // updateOffer failed but `offer` might still be live (i.e with `offer.gives>0`)
          uint oldGives = MGV.offers(address(QUOTE), address(BASE), mStr.bids[wd.index]).gives();
          // if not during initialize we necessarily have gives > oldGives
          // otherwise we are trying to reset the offer and oldGives is irrelevant
          return (wd.gives > oldGives) ? wd.gives - oldGives : wd.gives;
        } else {
          revert (reason);
        }
      }
    }
  }

  /**
   * Writes (creates or updates) a maker offer on Mangrove's order book
   */
  function safeWriteOffer(
    uint index,
    IERC20 outbound_tkn,
    uint wants,
    uint gives,
    uint ofr_gr,
    bool withPending, // whether `gives` amount includes current pending tokens
    uint pivotId
  ) internal {
    MangoStorage.Layout storage mStr = MangoStorage.getStorage();
    if (outbound_tkn == BASE) {
      uint not_published =
        writeAsk(WriteData({index: index, wants: wants, gives: gives, ofr_gr: ofr_gr, pivotId: pivotId, allowPending: withPending}));
      if (not_published > 0) {
        // Ask could not be written on the book (density or provision issue)
        mStr.pending_base = withPending ? not_published : (mStr.pending_base + not_published);
      } else {
        if (withPending) {
          mStr.pending_base = 0;
        }
      }
    } else {
      uint not_published =
        writeBid(WriteData({index: index, wants: wants, gives: gives, ofr_gr: ofr_gr, pivotId: pivotId, allowPending: withPending}));
      if (not_published > 0) {
        mStr.pending_quote = withPending ? not_published : (mStr.pending_quote + not_published);
      } else {
        if (withPending) {
          mStr.pending_quote = 0;
        }
      }
    }
  }

  // returns the value of x in the ring [0,m]
  // i.e if x>=0 this is just x % m
  // if x<0 this is m + (x % m)
  function modulo(int x, uint m) internal pure returns (uint) {
    if (x >= 0) {
      return uint(x) % m;
    } else {
      return uint(int(m) + (x % int(m)));
    }
  }

  /**
   * Minimal amount of quotes for the general term of the `quote_progression`
   */
  /**
   * If min price was not shifted this is just `QUOTE_0`
   */
  /**
   * In general this is QUOTE_0 + shift*delta
   */
  function quote_min() internal view returns (uint) {
    MangoStorage.Layout storage mStr = MangoStorage.getStorage();
    int qm = int(uint(QUOTE_0)) + mStr.shift * int(mStr.delta);
    require(qm > 0, "Mango/quote_min/ShiftUnderflow");
    return (uint(qm));
  }

  /**
   * Returns the price position in the order book of the offer associated to this index `i`
   */
  function position_of_index(uint i) internal view returns (uint) {
    // position(i) = (i+shift) % N
    return modulo(int(i) - MangoStorage.getStorage().shift, NSLOTS);
  }

  /**
   * Returns the index in the ring of offers at which the offer Id at position `p` in the book is stored
   */
  function index_of_position(uint p) internal view returns (uint) {
    return modulo(int(p) + MangoStorage.getStorage().shift, NSLOTS);
  }

  /**
   * Next index in the ring of offers
   */
  function next_index(uint i) internal view returns (uint) {
    return (i + 1) % NSLOTS;
  }

  /**
   * Previous index in the ring of offers
   */
  function prev_index(uint i) internal view returns (uint) {
    return i > 0 ? i - 1 : NSLOTS - 1;
  }

  /**
   * Function that determines the amount of quotes that are offered at position i of the OB dePENDING on initial_price and paramater delta
   */
  /**
   * Here the default is an arithmetic progression
   */
  function quote_progression(uint position) internal view returns (uint) {
    return MangoStorage.quote_price_jumps(MangoStorage.getStorage().delta, position, quote_min());
  }

  /**
   * Returns the quantity of quote tokens for an offer at position `p` given an amount of Base tokens (eq. 2)
   */
  function quotes_of_position(uint p, uint base_amount) internal view returns (uint) {
    return (quote_progression(p) * base_amount) / BASE_0;
  }

  /**
   * Returns the quantity of base tokens for an offer at position `p` given an amount of quote tokens (eq. 3)
   */
  function bases_of_position(uint p, uint quote_amount) internal view returns (uint) {
    return (quote_amount * BASE_0) / quote_progression(p);
  }

  /**
   * Recenter the order book by shifting min price up `s` positions in the book
   */
  /**
   * As a consequence `s` Bids will be cancelled and `s` new asks will be posted
   */
  function positive_shift(uint s, bool withBase, uint[] calldata amounts, uint gasreq) internal {
    MangoStorage.Layout storage mStr = MangoStorage.getStorage();
    require(s < NSLOTS, "Mango/shift/positiveShiftTooLarge");
    uint index = index_of_position(0);
    mStr.shift += int(s); // updating new shift
    // Warning: from now on position_of_index reflects the new shift
    // One must progress relative to index when retracting offers
    uint cpt = 0;
    while (cpt < s) {
      // slots occupied by [Bids[index],..,Bids[index+`s` % N]] are retracted
      if (mStr.bids[index] != 0) {
        MGV.retractOffer({
          outbound_tkn: address(QUOTE),
          inbound_tkn: address(BASE),
          offerId: mStr.bids[index],
          deprovision: false
        });
      }

      // slots are replaced by `s` Asks.
      // NB the price of Ask[index] is computed given the new position associated to `index`
      // because the shift has been updated above

      // `pos` is the offer position in the OB (not the array)
      uint pos = position_of_index(index);
      uint new_gives;
      uint new_wants;
      if (withBase) {
        // posting new ASKS with base amount fixed
        new_gives = amounts[cpt];
        new_wants = quotes_of_position(pos, amounts[cpt]);
      } else {
        // posting new ASKS with quote amount fixed
        new_wants = amounts[cpt];
        new_gives = bases_of_position(pos, amounts[cpt]);
      }
      safeWriteOffer({
        index: index,
        outbound_tkn: BASE,
        wants: new_wants,
        gives: new_gives,
        ofr_gr: gasreq,
        withPending: false, // don't add pending liqudity in new offers (they are far from mid price)
        pivotId: pos > 0 ? mStr.asks[index_of_position(pos - 1)] : 0
      });
      cpt++;
      index = next_index(index);
    }
  }

  /**
   * Recenter the order book by shifting max price down `s` positions in the book
   */
  /**
   * As a consequence `s` Asks will be cancelled and `s` new Bids will be posted
   */
  function negative_shift(uint s, bool withBase, uint[] calldata amounts, uint gasreq) internal {
    MangoStorage.Layout storage mStr = MangoStorage.getStorage();
    require(s < NSLOTS, "Mango/shift/NegativeShiftTooLarge");
    uint index = index_of_position(NSLOTS - 1);
    mStr.shift -= int(s); // updating new shift
    // Warning: from now on position_of_index reflects the new shift
    // One must progress relative to index when retracting offers
    uint cpt;
    while (cpt < s) {
      // slots occupied by [Asks[index-`s` % N],..,Asks[index]] are retracted
      if (mStr.asks[index] != 0) {
        MGV.retractOffer({
          outbound_tkn: address(BASE),
          inbound_tkn: address(QUOTE),
          offerId: mStr.asks[index],
          deprovision: false
        });
      }
      // slots are replaced by `s` Bids.
      // NB the price of Bids[index] is computed given the new position associated to `index`
      // because the shift has been updated above

      // `pos` is the offer position in the OB (not the array)
      uint pos = position_of_index(index);
      uint new_gives;
      uint new_wants;
      if (withBase) {
        // amounts in base
        new_wants = amounts[cpt];
        new_gives = quotes_of_position(pos, amounts[cpt]);
      } else {
        // amounts in quote
        new_wants = bases_of_position(pos, amounts[cpt]);
        new_gives = amounts[cpt];
      }
      safeWriteOffer({
        index: index,
        outbound_tkn: QUOTE,
        wants: new_wants,
        gives: new_gives,
        ofr_gr: gasreq,
        withPending: false,
        pivotId: pos < NSLOTS - 1 ? mStr.bids[index_of_position(pos + 1)] : 0
      });
      cpt++;
      index = prev_index(index);
    }
  }

  function $residualWants(MgvLib.SingleOrder calldata order, uint residual) external view returns (uint) {
    MangoStorage.Layout storage mStr = MangoStorage.getStorage();
    if (order.outbound_tkn == address(BASE)) {
      // Ask offer (wants QUOTE)
      uint index = mStr.index_of_ask[order.offerId];
      return quotes_of_position(position_of_index(index), residual);
    } else {
      // Bid order (wants BASE)
      uint index = mStr.index_of_bid[order.offerId];
      return bases_of_position(position_of_index(index), residual);
    }
  }

  // TODO add LogIncident and Bid/AskatMax logs
  function $postDualOffer(MgvLib.SingleOrder calldata order, uint gasreq) external delegated returns (bytes32 status) {
    MangoStorage.Layout storage mStr = MangoStorage.getStorage();

    // reposting residual of offer using override `__newWants__` and `__newGives__` for new price
    if (order.outbound_tkn == address(BASE)) {
      //// Posting dual bid offer
      uint index = mStr.index_of_ask[order.offerId];

      uint pos = position_of_index(index);
      // bid for some BASE token with the received QUOTE tokens @ pos-1
      if (pos > 0) {
        // updateBid will include PENDING_QUOTES if any
        updateBid({
          index: index_of_position(pos - 1),
          reset: false, // top up old value with received amount
          amount: order.gives, // in QUOTES
          pivotId: 0,
          gasreq: gasreq
        });
        if (pos - 1 <= mStr.min_buffer) {
          emit BidAtMaxPosition();
        }
        return "Mango/BidPosted";
      } else {
        // Ask cannot be at Pmin unless a shift has eliminated all bids
        // reverting so that Mangrove's logs the problem
        revert("Mango/BidOutOfRange");
      }
    } else {
      // Bid offer (`this` contract just bought some BASE)

      uint index = mStr.index_of_bid[order.offerId];
      // offer was not posted using newOffer
      uint pos = position_of_index(index);
      // ask for some QUOTE tokens in exchange of the received BASE tokens @ pos+1
      if (pos < NSLOTS - 1) {
        // updateAsk will include mStr.pending_baseS if any
        updateAsk({
          index: index_of_position(pos + 1),
          reset: false, // top up old value with received amount
          amount: order.gives, // in BASE
          pivotId: 0,
          gasreq: gasreq
        });
        if (pos + 1 >= NSLOTS - mStr.min_buffer) {
          emit AskAtMinPosition();
        }
        return "Mango";
      } else {
        revert("Mango/AskOutOfRange");
      }
    }
  }

  function updateBid(
    uint index,
    bool reset, // whether this call is part of an `initialize` procedure
    uint amount, // in QUOTE tokens
    uint pivotId,
    uint gasreq
  ) internal {
    MangoStorage.Layout storage mStr = MangoStorage.getStorage();
    // outbound : QUOTE, inbound: BASE
    MgvStructs.OfferPacked offer = MGV.offers(address(QUOTE), address(BASE), mStr.bids[index]);

    uint position = position_of_index(index);

    uint new_gives = reset ? amount : (amount + offer.gives() + mStr.pending_quote);
    uint new_wants = bases_of_position(position, new_gives);

    uint pivot;
    if (offer.gives() == 0) {
      // offer was not live
      if (pivotId != 0) {
        pivot = pivotId;
      } else {
        if (position > 0) {
          pivot = mStr.bids[index_of_position(position - 1)]; // if this offer is no longer in the book will start form best
        } else {
          pivot = offer.prev(); // trying previous offer on Mangrove as a pivot
        }
      }
    } else {
      // offer is live, so reusing its id for pivot
      pivot = mStr.bids[index];
    }
    safeWriteOffer({
      index: index,
      outbound_tkn: QUOTE,
      wants: new_wants,
      gives: new_gives,
      ofr_gr: gasreq,
      withPending: !reset,
      pivotId: pivot
    });
  }

  function updateAsk(
    uint index,
    bool reset, // whether this call is part of an `initialize` procedure
    uint amount, // in BASE tokens
    uint pivotId,
    uint gasreq
  ) internal {
    MangoStorage.Layout storage mStr = MangoStorage.getStorage();
    // outbound : BASE, inbound: QUOTE
    MgvStructs.OfferPacked offer = MGV.offers(address(BASE), address(QUOTE), mStr.asks[index]);
    uint position = position_of_index(index);

    uint new_gives = reset ? amount : (amount + offer.gives() + mStr.pending_base); // in BASE
    uint new_wants = quotes_of_position(position, new_gives);

    uint pivot;
    if (offer.gives() == 0) {
      // offer was not live
      if (pivotId != 0) {
        pivot = pivotId;
      } else {
        if (position > 0) {
          pivot = mStr.asks[index_of_position(position - 1)]; // if this offer is no longer in the book will start form best
        } else {
          pivot = offer.prev(); // trying previous offer on Mangrove as a pivot
        }
      }
    } else {
      // offer is live, so reusing its id for pivot
      pivot = mStr.asks[index];
    }
    safeWriteOffer({
      index: index,
      outbound_tkn: BASE,
      wants: new_wants,
      gives: new_gives,
      ofr_gr: gasreq,
      withPending: !reset,
      pivotId: pivot
    });
  }
}

// SPDX-License-Identifier:	BSD-2-Clause

// Direct.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
pragma solidity ^0.8.10;

pragma abicoder v2;

import "mgv_src/strategies/MangroveOffer.sol";
import {MgvLib} from "mgv_src/MgvLib.sol";
import "mgv_src/strategies/utils/TransferLib.sol";

/// MangroveOffer is the basic building block to implement a reactive offer that interfaces with the Mangrove
abstract contract Direct is MangroveOffer {
  constructor(IMangrove mgv, AbstractRouter router_) MangroveOffer(mgv) {
    // default reserve is router's address if router is defined
    // if not then default reserve is `this` contract
    if (router_ == NO_ROUTER) {
      setReserve(address(this));
    } else {
      setReserve(address(router_));
      setRouter(router_);
    }
  }

  function reserve() public view override returns (address) {
    return _reserve(address(this));
  }

  function setReserve(address reserve_) public override onlyAdmin {
    _setReserve(address(this), reserve_);
  }

  function withdrawToken(IERC20 token, address receiver, uint amount)
    external
    override
    onlyAdmin
    returns (bool success)
  {
    require(receiver != address(0), "Direct/withdrawToken/0xReceiver");
    AbstractRouter router_ = router();
    if (router_ == NO_ROUTER) {
      return TransferLib.transferToken(IERC20(token), receiver, amount);
    } else {
      return router_.withdrawToken(token, reserve(), receiver, amount);
    }
  }

  function pull(IERC20 outbound_tkn, uint amount, bool strict) internal returns (uint) {
    AbstractRouter router_ = router();
    if (router_ == NO_ROUTER) {
      require(
        TransferLib.transferTokenFrom(outbound_tkn, reserve(), address(this), amount), //noop if reserve is `this`
        "Direct/pull/transferFail"
      );
      return amount;
    } else {
      // letting specific router pull the funds from reserve
      return router_.pull(outbound_tkn, reserve(), amount, strict);
    }
  }

  function push(IERC20 token, uint amount) internal {
    AbstractRouter router_ = router();
    if (router_ == NO_ROUTER) {
      return; // nothing to do
    } else {
      // noop if reserve == address(this)
      router_.push(token, reserve(), amount);
    }
  }

  function tokenBalance(IERC20 token) external view override returns (uint) {
    AbstractRouter router_ = router();
    return router_ == NO_ROUTER ? token.balanceOf(reserve()) : router_.reserveBalance(token, reserve());
  }

  function flush(IERC20[] memory tokens) internal {
    AbstractRouter _router = MOS.getStorage().router;
    if (_router == NO_ROUTER) {
      for (uint i = 0; i < tokens.length; i++) {
        require(
          TransferLib.transferToken(tokens[i], reserve(), tokens[i].balanceOf(address(this))),
          "Direct/flush/transferFail"
        );
      }
      return;
    } else {
      _router.flush(tokens, reserve());
    }
  }

  // Updates offer `offerId` on the (`outbound_tkn,inbound_tkn`) Offer List of Mangrove.
  // NB #1: Offer maker MUST:
  // * Make sure that offer maker has enough WEI provision on Mangrove to cover for the new offer bounty in case Mangrove gasprice has increased (function is payable so that caller can increase provision prior to updating the offer)
  // * Make sure that `gasreq` and `gives` yield a sufficient offer density
  // NB #2: This function will revert when the above points are not met
  function updateOffer(
    IERC20 outbound_tkn,
    IERC20 inbound_tkn,
    uint wants,
    uint gives,
    uint gasreq,
    uint gasprice,
    uint pivotId,
    uint offerId
  )
    public
    payable
    override
    mgvOrAdmin
  {
    MGV.updateOffer{value: msg.value}(
      address(outbound_tkn),
      address(inbound_tkn),
      wants,
      gives,
      gasreq > type(uint24).max ? offerGasreq() : gasreq,
      gasprice,
      pivotId,
      offerId
    );
  }

  // Retracts `offerId` from the (`outbound_tkn`,`inbound_tkn`) Offer list of Mangrove.
  // Function call will throw if `this` contract is not the owner of `offerId`.
  // Returned value is the amount of ethers that have been credited to `this` contract balance on Mangrove (always 0 if `deprovision=false`)
  // NB `mgvOrAdmin` modifier guarantees that this function is either called by contract admin or (indirectly) during trade execution by Mangrove
  function retractOffer(
    IERC20 outbound_tkn,
    IERC20 inbound_tkn,
    uint offerId,
    bool deprovision // if set to `true`, `this` contract will receive the remaining provision (in WEI) associated to `offerId`.
  )
    public
    override
    mgvOrAdmin
    returns (uint free_wei)
  {
    free_wei = MGV.retractOffer(address(outbound_tkn), address(inbound_tkn), offerId, deprovision);
    if (free_wei > 0) {
      require(MGV.withdraw(free_wei), "Direct/withdrawFromMgv/withdrawFail");
      // sending native tokens to `msg.sender` prevents reentrancy issues
      // (the context call of `retractOffer` could be coming from `makerExecute` and a different recipient of transfer than `msg.sender` could use this call to make offer fail)
      (bool noRevert,) = msg.sender.call{value: free_wei}("");
      require(noRevert, "Direct/weiTransferFail");
    }
  }

  ///@inheritdoc IOfferLogic
  function provisionOf(IERC20 outbound_tkn, IERC20 inbound_tkn, uint offerId)
    external
    view
    override
    returns (uint provision)
  {
    MgvStructs.OfferDetailPacked offer_detail = MGV.offerDetails(address(outbound_tkn), address(inbound_tkn), offerId);
    (, MgvStructs.LocalPacked local) = MGV.config(address(outbound_tkn), address(inbound_tkn));
    unchecked {
      provision = offer_detail.gasprice() * 10 ** 9 * (local.offer_gasbase() + offer_detail.gasreq());
    }
  }

  function __put__(uint, /*amount*/ MgvLib.SingleOrder calldata) internal virtual override returns (uint missing) {
    // singleUser contract do not need to do anything specific with incoming funds during trade
    // one should overrides this function if one wishes to leverage taker's fund during trade execution
    return 0;
  }

  // default `__get__` hook for `Direct` is to pull liquidity from `reserve()`
  // letting router handle the specifics if any
  function __get__(uint amount, MgvLib.SingleOrder calldata order) internal virtual override returns (uint missing) {
    // pulling liquidity from reserve
    // depending on the router, this may result in pulling more/less liquidity than required
    // so one should check local balance to compute missing liquidity
    uint local_balance = IERC20(order.outbound_tkn).balanceOf(address(this));
    if (local_balance >= amount) {
      return 0;
    }
    uint pulled = pull(IERC20(order.outbound_tkn), amount - local_balance, false);
    missing = pulled >= amount - local_balance ? 0 : amount - local_balance - pulled;
  }

  function __posthookSuccess__(MgvLib.SingleOrder calldata order, bytes32 makerData)
    internal
    virtual
    override
    returns (bytes32)
  {
    IERC20[] memory tokens = new IERC20[](2);
    tokens[0] = IERC20(order.outbound_tkn); // flushing outbound tokens if this contract pulled more liquidity than required during `makerExecute`
    tokens[1] = IERC20(order.inbound_tkn); // flushing liquidity brought by taker
    // sends all tokens to the reserve (noop if reserve() == address(this))
    flush(tokens);
    // reposting offer residual if any
    return super.__posthookSuccess__(order, makerData);
  }

  function __checkList__(IERC20 token) internal view virtual override {
    AbstractRouter router_ = router();
    if (router_ != NO_ROUTER) {
      router().checkList(token, reserve());
    }
    super.__checkList__(token);
  }
}

// SPDX-License-Identifier:	BSD-2-Clause

//AbstractRouter.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

pragma solidity ^0.8.10;

pragma abicoder v2;

import {AccessControlled} from "mgv_src/strategies/utils/AccessControlled.sol";
import {AbstractRouterStorage as ARSt} from "./AbstractRouterStorage.sol";
import {IERC20} from "mgv_src/MgvLib.sol";

/// @title AbstractRouter
/// @notice Partial implementation and requirements for liquidity routers.

abstract contract AbstractRouter is AccessControlled {
  modifier onlyMakers() {
    require(makers(msg.sender), "Router/unauthorized");
    _;
  }

  modifier makersOrAdmin() {
    require(msg.sender == admin() || makers(msg.sender), "Router/unauthorized");
    _;
  }

  ///@notice constructor for abstract routers.
  ///@param gas_overhead is the amount of gas that is required for this router to be able to perform a `pull` and a `push`.
  constructor(uint gas_overhead) AccessControlled(msg.sender) {
    require(uint24(gas_overhead) == gas_overhead, "Router/overheadTooHigh");
    ARSt.getStorage().gas_overhead = gas_overhead;
  }

  ///@notice getter for the `makers: addr => bool` mapping
  ///@param mkr the address of a maker
  ///@return true if `mkr` is authorized to call this router.
  function makers(address mkr) public view returns (bool) {
    return ARSt.getStorage().makers[mkr];
  }

  ///@notice view for gas overhead of this router.
  ///@return overhead the added (overapproximated) gas cost of `push` and `pull`.
  function gasOverhead() public view returns (uint overhead) {
    return ARSt.getStorage().gas_overhead;
  }

  ///@notice pulls liquidity from an offer maker's reserve to `msg.sender`'s balance
  ///@param token is the ERC20 managing the pulled asset
  ///@param reserve is the address identifying where `amount` of `token` should be pulled from
  ///@param amount of `token` the maker contract wishes to get
  ///@param strict when the calling maker contract accepts to receive more `token` than required (this may happen for gas optimization)
  function pull(IERC20 token, address reserve, uint amount, bool strict) external onlyMakers returns (uint pulled) {
    pulled = __pull__({token: token, reserve: reserve, maker: msg.sender, amount: amount, strict: strict});
  }

  ///@notice router-dependant implementation of the `pull` function
  function __pull__(IERC20 token, address reserve, address maker, uint amount, bool strict)
    internal
    virtual
    returns (uint);

  ///@notice pushes assets from maker contract's balance to the specified reserve
  ///@param token is the asset the maker is pushing
  ///@param reserve is the address identifying where the transferred assets should be placed to
  ///@param amount is the amount of asset that should be transferred from the calling maker contract
  function push(IERC20 token, address reserve, uint amount) external onlyMakers {
    __push__({token: token, reserve: reserve, maker: msg.sender, amount: amount});
  }

  ///@notice router-dependant implementation of the `push` function
  function __push__(IERC20 token, address reserve, address maker, uint amount) internal virtual;

  ///@notice gas saving implementation of an iterative `push`
  function flush(IERC20[] calldata tokens, address reserve) external onlyMakers {
    for (uint i = 0; i < tokens.length; i++) {
      uint amount = tokens[i].balanceOf(msg.sender);
      if (amount > 0) {
        __push__(tokens[i], reserve, msg.sender, amount);
      }
    }
  }

  ///@notice returns the amount of `token`s that can be made available for pulling by the maker contract
  ///@dev when this router is pulling from a lender, this must return the amount of asset that can be withdrawn from reserve
  ///@param token is the asset one wishes to know the balance of
  ///@param reserve is the address identifying the location of the assets
  function reserveBalance(IERC20 token, address reserve) external view virtual returns (uint);

  ///@notice withdraws `amount` of reserve tokens and sends them to `recipient`
  ///@dev this is called by maker's contract when originator wishes to withdraw funds from it.
  ///@param token is the asset one wishes to withdraw
  ///@param reserve is the address identifying the location of the assets
  ///@param recipient is the address identifying the location of the recipient
  ///@param amount is the amount of asset that should be withdrawn
  /// this function is necessary because the maker contract is agnostic w.r.t reserve management
  function withdrawToken(IERC20 token, address reserve, address recipient, uint amount)
    public
    onlyMakers
    returns (bool)
  {
    return __withdrawToken__(token, reserve, recipient, amount);
  }

  ///@notice router-dependant implementation of the `withdrawToken` function
  function __withdrawToken__(IERC20 token, address reserve, address to, uint amount) internal virtual returns (bool);

  ///@notice adds a maker contract address to the allowed callers of this router
  ///@dev this function is callable by router's admin to bootstrap, but later on an allowed maker contract can add another address
  function bind(address maker) public onlyAdmin {
    ARSt.getStorage().makers[maker] = true;
  }

  ///@notice removes a maker contract address from the allowed callers of this router
  function unbind(address maker) public onlyAdmin {
    ARSt.getStorage().makers[maker] = false;
  }

  ///@notice removes a maker contract address from the allowed callers of this router
  function unbind() external onlyMakers {
    ARSt.getStorage().makers[msg.sender] = false;
  }

  ///@notice verifies all required approval involving `this` router (either as a spender or owner)
  ///@dev `checkList` returns normally if all needed approval are strictly positive. It reverts otherwise with a reason.
  ///@param token is the asset (and possibly its overlyings) whose approval must be checked
  ///@param reserve the reserve that requires asset pulling/pushing
  function checkList(IERC20 token, address reserve) external view {
    // checking basic requirement
    require(token.allowance(msg.sender, address(this)) > 0, "Router/NotApprovedByMakerContract");
    __checkList__(token, reserve);
  }

  ///@notice router-dependent implementation of the `checkList` function
  function __checkList__(IERC20 token, address reserve) internal view virtual;

  ///@notice performs necessary approval to activate router function on a particular asset
  ///@param token the asset one wishes to use the router for
  function activate(IERC20 token) external makersOrAdmin {
    __activate__(token);
  }

  ///@notice router-dependent implementation of the `activate` function
  function __activate__(IERC20 token) internal virtual {
    token; //ssh
  }
}

// SPDX-License-Identifier:	BSD-2-Clause

//SimpleRouter.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

pragma solidity ^0.8.10;

pragma abicoder v2;

import "mgv_src/strategies/utils/AccessControlled.sol";
import "mgv_src/strategies/utils/TransferLib.sol";
import "./AbstractRouter.sol";

///@notice `SimpleRouter` instances pull (push) liquidity direclty from (to) the reserve
/// If called by a `SingleUser` contract instance this will be the vault of the contract
/// If called by a `MultiUser` instance, this will be the address of a contract user (typically an EOA)
///@dev Maker contracts using this router must make sur that reserve approves the router for all asset that will be pulled (outbound tokens)
/// Thus contract using a vault that is not an EOA must make sure this vault has approval capacities.

contract SimpleRouter is
  AbstractRouter(70_000) // fails for < 70K with Direct strat
{
  // requires approval of `reserve`
  function __pull__(IERC20 token, address reserve, address maker, uint amount, bool strict)
    internal
    virtual
    override
    returns (uint pulled)
  {
    strict; // this pull strategy is only strict
    if (TransferLib.transferTokenFrom(token, reserve, maker, amount)) {
      return amount;
    } else {
      return 0;
    }
  }

  // requires approval of Maker
  function __push__(IERC20 token, address reserve, address maker, uint amount) internal virtual override {
    require(TransferLib.transferTokenFrom(token, maker, reserve, amount), "SimpleRouter/push/transferFail");
  }

  function __withdrawToken__(IERC20 token, address reserve, address to, uint amount)
    internal
    virtual
    override
    returns (bool)
  {
    return TransferLib.transferTokenFrom(token, reserve, to, amount);
  }

  function reserveBalance(IERC20 token, address reserve) external view override returns (uint) {
    return token.balanceOf(reserve);
  }

  function __checkList__(IERC20 token, address reserve) internal view virtual override {
    // verifying that `this` router can withdraw tokens from reserve (required for `withdrawToken` and `pull`)
    require(
      reserve == address(this) || token.allowance(reserve, address(this)) > 0, "SimpleRouter/NotApprovedByReserve"
    );
  }
}

// SPDX-License-Identifier: Unlicense

// MgvLib.sol

// This is free and unencumbered software released into the public domain.

// Anyone is free to copy, modify, publish, use, compile, sell, or distribute this software, either in source code form or as a compiled binary, for any purpose, commercial or non-commercial, and by any means.

// In jurisdictions that recognize copyright laws, the author or authors of this software dedicate any and all copyright interest in the software to the public domain. We make this dedication for the benefit of the public at large and to the detriment of our heirs and successors. We intend this dedication to be an overt act of relinquishment in perpetuity of all present and future rights to this software under copyright law.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// For more information, please refer to <https://unlicense.org/>

/* `MgvLib` contains data structures returned by external calls to Mangrove and the interfaces it uses for its own external calls. */

pragma solidity ^0.8.10;

pragma abicoder v2;

import "./preprocessed/MgvStructs.post.sol" as MgvStructs;

/* # Structs
The structs defined in `structs.js` have their counterpart as solidity structs that are easy to manipulate for outside contracts / callers of view functions. */

library MgvLib {
  /*
   Some miscellaneous data types useful to `Mangrove` and external contracts */
  //+clear+

  /* `SingleOrder` holds data about an order-offer match in a struct. Used by `marketOrder` and `internalSnipes` (and some of their nested functions) to avoid stack too deep errors. */
  struct SingleOrder {
    address outbound_tkn;
    address inbound_tkn;
    uint offerId;
    MgvStructs.OfferPacked offer;
    /* `wants`/`gives` mutate over execution. Initially the `wants`/`gives` from the taker's pov, then actual `wants`/`gives` adjusted by offer's price and volume. */
    uint wants;
    uint gives;
    /* `offerDetail` is only populated when necessary. */
    MgvStructs.OfferDetailPacked offerDetail;
    MgvStructs.GlobalPacked global;
    MgvStructs.LocalPacked local;
  }

  /* <a id="MgvLib/OrderResult"></a> `OrderResult` holds additional data for the maker and is given to them _after_ they fulfilled an offer. It gives them their own returned data from the previous call, and an `mgvData` specifying whether the Mangrove encountered an error. */

  struct OrderResult {
    /* `makerdata` holds a message that was either returned by the maker or passed as revert message at the end of the trade execution*/
    bytes32 makerData;
    /* `mgvData` is an [internal Mangrove status code](#MgvOfferTaking/statusCodes) code. */
    bytes32 mgvData;
  }
}

/* # Events
The events emitted for use by bots are listed here: */
contract HasMgvEvents {
  /* * Emitted at the creation of the new Mangrove contract on the pair (`inbound_tkn`, `outbound_tkn`)*/
  event NewMgv();

  /* Mangrove adds or removes wei from `maker`'s account */
  /* * Credit event occurs when an offer is removed from the Mangrove or when the `fund` function is called*/
  event Credit(address indexed maker, uint amount);
  /* * Debit event occurs when an offer is posted or when the `withdraw` function is called */
  event Debit(address indexed maker, uint amount);

  /* * Mangrove reconfiguration */
  event SetActive(address indexed outbound_tkn, address indexed inbound_tkn, bool value);
  event SetFee(address indexed outbound_tkn, address indexed inbound_tkn, uint value);
  event SetGasbase(address indexed outbound_tkn, address indexed inbound_tkn, uint offer_gasbase);
  event SetGovernance(address value);
  event SetMonitor(address value);
  event SetVault(address value);
  event SetUseOracle(bool value);
  event SetNotify(bool value);
  event SetGasmax(uint value);
  event SetDensity(address indexed outbound_tkn, address indexed inbound_tkn, uint value);
  event SetGasprice(uint value);

  /* Market order execution */
  event OrderStart();
  event OrderComplete(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    address indexed taker,
    uint takerGot,
    uint takerGave,
    uint penalty,
    uint feePaid
  );

  /* * Offer execution */
  event OfferSuccess(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint id,
    // `maker` is not logged because it can be retrieved from the state using `(outbound_tkn,inbound_tkn,id)`.
    address taker,
    uint takerWants,
    uint takerGives
  );

  /* Log information when a trade execution reverts or returns a non empty bytes32 word */
  event OfferFail(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint id,
    // `maker` is not logged because it can be retrieved from the state using `(outbound_tkn,inbound_tkn,id)`.
    address taker,
    uint takerWants,
    uint takerGives,
    // `mgvData` may only be `"mgv/makerRevert"`, `"mgv/makerTransferFail"` or `"mgv/makerReceiveFail"`
    bytes32 mgvData
  );

  /* Log information when a posthook reverts */
  event PosthookFail(address indexed outbound_tkn, address indexed inbound_tkn, uint offerId, bytes32 posthookData);

  /* * After `permit` and `approve` */
  event Approval(address indexed outbound_tkn, address indexed inbound_tkn, address owner, address spender, uint value);

  /* * Mangrove closure */
  event Kill();

  /* * An offer was created or updated.
  A few words about why we include a `prev` field, and why we don't include a
  `next` field: in theory clients should need neither `prev` nor a `next` field.
  They could just 1. Read the order book state at a given block `b`.  2. On
  every event, update a local copy of the orderbook.  But in practice, we do not
  want to force clients to keep a copy of the *entire* orderbook. There may be a
  long tail of spam. Now if they only start with the first $N$ offers and
  receive a new offer that goes to the end of the book, they cannot tell if
  there are missing offers between the new offer and the end of the local copy
  of the book.
  
  So we add a prev pointer so clients with only a prefix of the book can receive
  out-of-prefix offers and know what to do with them. The `next` pointer is an
  optimization useful in Solidity (we traverse fewer memory locations) but
  useless in client code.
  */
  event OfferWrite(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    address maker,
    uint wants,
    uint gives,
    uint gasprice,
    uint gasreq,
    uint id,
    uint prev
  );

  /* * `offerId` was present and is now removed from the book. */
  event OfferRetract(address indexed outbound_tkn, address indexed inbound_tkn, uint id);
}

/* # IMaker interface */
interface IMaker {
  /* Called upon offer execution. 
  - If the call fails, Mangrove will not try to transfer funds.
  - If the call succeeds but returndata's first 32 bytes are not 0, Mangrove will not try to transfer funds either.
  - If the call succeeds and returndata's first 32 bytes are 0, Mangrove will try to transfer funds.
  In other words, you may declare failure by reverting or by returning nonzero data. In both cases, those 32 first bytes will be passed back to you during the call to `makerPosthook` in the `result.mgvData` field.
     ```
     function tradeRevert(bytes32 data) internal pure {
       bytes memory revData = new bytes(32);
         assembly {
           mstore(add(revData, 32), data)
           revert(add(revData, 32), 32)
         }
     }
     ```
     */
  function makerExecute(MgvLib.SingleOrder calldata order) external returns (bytes32);

  /* Called after all offers of an order have been executed. Posthook of the last executed order is called first and full reentrancy into the Mangrove is enabled at this time. `order` recalls key arguments of the order that was processed and `result` recalls important information for updating the current offer. (see [above](#MgvLib/OrderResult))*/
  function makerPosthook(MgvLib.SingleOrder calldata order, MgvLib.OrderResult calldata result) external;
}

/* # ITaker interface */
interface ITaker {
  /* Inverted mangrove only: call to taker after loans went through */
  function takerTrade(
    address outbound_tkn,
    address inbound_tkn,
    // total amount of outbound_tkn token that was flashloaned to the taker
    uint totalGot,
    // total amount of inbound_tkn token that should be made available
    uint totalGives
  ) external;
}

/* # Monitor interface
If enabled, the monitor receives notification after each offer execution and is read for each pair's `gasprice` and `density`. */
interface IMgvMonitor {
  function notifySuccess(MgvLib.SingleOrder calldata sor, address taker) external;

  function notifyFail(MgvLib.SingleOrder calldata sor, address taker) external;

  function read(address outbound_tkn, address inbound_tkn) external view returns (uint gasprice, uint density);
}

interface IERC20 {
  function totalSupply() external view returns (uint);

  function balanceOf(address account) external view returns (uint);

  function transfer(address recipient, uint amount) external returns (bool);

  function allowance(address owner, address spender) external view returns (uint);

  function approve(address spender, uint amount) external returns (bool);

  function transferFrom(address sender, address recipient, uint amount) external returns (bool);

  function symbol() external view returns (string memory);

  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);

  /// for wETH contract
  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: UNLICENSED
// This file was manually adapted from a file generated by abi-to-sol. It must
// be kept up-to-date with the actual Mangrove interface. Fully automatic
// generation is not yet possible due to user-generated types in the external
// interface lost in the abi generation.

pragma solidity >=0.7.0 <0.9.0;

pragma experimental ABIEncoderV2;

import {MgvLib, MgvStructs, IMaker} from "./MgvLib.sol";

interface IMangrove {
  event Approval(address indexed outbound_tkn, address indexed inbound_tkn, address owner, address spender, uint value);
  event Credit(address indexed maker, uint amount);
  event Debit(address indexed maker, uint amount);
  event Kill();
  event NewMgv();
  event OfferFail(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint id,
    address taker,
    uint takerWants,
    uint takerGives,
    bytes32 mgvData
  );
  event OfferRetract(address indexed outbound_tkn, address indexed inbound_tkn, uint id);
  event OfferSuccess(
    address indexed outbound_tkn, address indexed inbound_tkn, uint id, address taker, uint takerWants, uint takerGives
  );
  event OfferWrite(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    address maker,
    uint wants,
    uint gives,
    uint gasprice,
    uint gasreq,
    uint id,
    uint prev
  );
  event OrderComplete(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    address indexed taker,
    uint takerGot,
    uint takerGave,
    uint penalty
  );
  event OrderStart();
  event PosthookFail(address indexed outbound_tkn, address indexed inbound_tkn, uint offerId);
  event SetActive(address indexed outbound_tkn, address indexed inbound_tkn, bool value);
  event SetDensity(address indexed outbound_tkn, address indexed inbound_tkn, uint value);
  event SetFee(address indexed outbound_tkn, address indexed inbound_tkn, uint value);
  event SetGasbase(address indexed outbound_tkn, address indexed inbound_tkn, uint offer_gasbase);
  event SetGasmax(uint value);
  event SetGasprice(uint value);
  event SetGovernance(address value);
  event SetMonitor(address value);
  event SetNotify(bool value);
  event SetUseOracle(bool value);
  event SetVault(address value);

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function PERMIT_TYPEHASH() external view returns (bytes32);

  function activate(address outbound_tkn, address inbound_tkn, uint fee, uint density, uint offer_gasbase) external;

  function allowances(address, address, address, address) external view returns (uint);

  function approve(address outbound_tkn, address inbound_tkn, address spender, uint value) external returns (bool);

  function balanceOf(address) external view returns (uint);

  function best(address outbound_tkn, address inbound_tkn) external view returns (uint);

  function config(address outbound_tkn, address inbound_tkn)
    external
    view
    returns (MgvStructs.GlobalPacked, MgvStructs.LocalPacked);

  function configInfo(address outbound_tkn, address inbound_tkn)
    external
    view
    returns (MgvStructs.GlobalUnpacked memory global, MgvStructs.LocalUnpacked memory local);

  function deactivate(address outbound_tkn, address inbound_tkn) external;

  function flashloan(MgvLib.SingleOrder memory sor, address taker) external returns (uint gasused);

  function fund(address maker) external payable;

  function fund() external payable;

  function governance() external view returns (address);

  function isLive(MgvStructs.OfferPacked offer) external pure returns (bool);

  function kill() external;

  function locked(address outbound_tkn, address inbound_tkn) external view returns (bool);

  function marketOrder(address outbound_tkn, address inbound_tkn, uint takerWants, uint takerGives, bool fillWants)
    external
    returns (uint takerGot, uint takerGave, uint bounty, uint fee);

  function marketOrderFor(
    address outbound_tkn,
    address inbound_tkn,
    uint takerWants,
    uint takerGives,
    bool fillWants,
    address taker
  ) external returns (uint takerGot, uint takerGave, uint bounty, uint fee);

  function newOffer(
    address outbound_tkn,
    address inbound_tkn,
    uint wants,
    uint gives,
    uint gasreq,
    uint gasprice,
    uint pivotId
  ) external payable returns (uint);

  function nonces(address) external view returns (uint);

  function offerDetails(address, address, uint) external view returns (MgvStructs.OfferDetailPacked);

  function offerInfo(address outbound_tkn, address inbound_tkn, uint offerId)
    external
    view
    returns (MgvStructs.OfferUnpacked memory offer, MgvStructs.OfferDetailUnpacked memory offerDetail);

  function offers(address, address, uint) external view returns (MgvStructs.OfferPacked);

  function permit(
    address outbound_tkn,
    address inbound_tkn,
    address owner,
    address spender,
    uint value,
    uint deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  function retractOffer(address outbound_tkn, address inbound_tkn, uint offerId, bool deprovision)
    external
    returns (uint provision);

  function setDensity(address outbound_tkn, address inbound_tkn, uint density) external;

  function setFee(address outbound_tkn, address inbound_tkn, uint fee) external;

  function setGasbase(address outbound_tkn, address inbound_tkn, uint offer_gasbase) external;

  function setGasmax(uint gasmax) external;

  function setGasprice(uint gasprice) external;

  function setGovernance(address governanceAddress) external;

  function setMonitor(address monitor) external;

  function setNotify(bool notify) external;

  function setUseOracle(bool useOracle) external;

  function setVault(address vaultAddress) external;

  function snipes(address outbound_tkn, address inbound_tkn, uint[4][] memory targets, bool fillWants)
    external
    returns (uint successes, uint takerGot, uint takerGave, uint bounty, uint fee);

  function snipesFor(address outbound_tkn, address inbound_tkn, uint[4][] memory targets, bool fillWants, address taker)
    external
    returns (uint successes, uint takerGot, uint takerGave, uint bounty, uint fee);

  function updateOffer(
    address outbound_tkn,
    address inbound_tkn,
    uint wants,
    uint gives,
    uint gasreq,
    uint gasprice,
    uint pivotId,
    uint offerId
  ) external payable;

  function vault() external view returns (address);

  function withdraw(uint amount) external returns (bool noRevert);

  receive() external payable;
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"inputs":[{"internalType":"address","name":"governance","type":"address"},{"internalType":"uint256","name":"gasprice","type":"uint256"},{"internalType":"uint256","name":"gasmax","type":"uint256"}],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"outbound_tkn","type":"address"},{"indexed":true,"internalType":"address","name":"inbound_tkn","type":"address"},{"indexed":false,"internalType":"address","name":"owner","type":"address"},{"indexed":false,"internalType":"address","name":"spender","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"Approval","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"maker","type":"address"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"}],"name":"Credit","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"maker","type":"address"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"}],"name":"Debit","type":"event"},{"anonymous":false,"inputs":[],"name":"Kill","type":"event"},{"anonymous":false,"inputs":[],"name":"NewMgv","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"outbound_tkn","type":"address"},{"indexed":true,"internalType":"address","name":"inbound_tkn","type":"address"},{"indexed":false,"internalType":"uint256","name":"id","type":"uint256"},{"indexed":false,"internalType":"address","name":"taker","type":"address"},{"indexed":false,"internalType":"uint256","name":"takerWants","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"takerGives","type":"uint256"},{"indexed":false,"internalType":"bytes32","name":"mgvData","type":"bytes32"}],"name":"OfferFail","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"outbound_tkn","type":"address"},{"indexed":true,"internalType":"address","name":"inbound_tkn","type":"address"},{"indexed":false,"internalType":"uint256","name":"id","type":"uint256"}],"name":"OfferRetract","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"outbound_tkn","type":"address"},{"indexed":true,"internalType":"address","name":"inbound_tkn","type":"address"},{"indexed":false,"internalType":"uint256","name":"id","type":"uint256"},{"indexed":false,"internalType":"address","name":"taker","type":"address"},{"indexed":false,"internalType":"uint256","name":"takerWants","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"takerGives","type":"uint256"}],"name":"OfferSuccess","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"outbound_tkn","type":"address"},{"indexed":true,"internalType":"address","name":"inbound_tkn","type":"address"},{"indexed":false,"internalType":"address","name":"maker","type":"address"},{"indexed":false,"internalType":"uint256","name":"wants","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"gives","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"gasprice","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"gasreq","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"id","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"prev","type":"uint256"}],"name":"OfferWrite","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"outbound_tkn","type":"address"},{"indexed":true,"internalType":"address","name":"inbound_tkn","type":"address"},{"indexed":true,"internalType":"address","name":"taker","type":"address"},{"indexed":false,"internalType":"uint256","name":"takerGot","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"takerGave","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"penalty","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"feePaid","type":"uint256"}],"name":"OrderComplete","type":"event"},{"anonymous":false,"inputs":[],"name":"OrderStart","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"outbound_tkn","type":"address"},{"indexed":true,"internalType":"address","name":"inbound_tkn","type":"address"},{"indexed":false,"internalType":"uint256","name":"offerId","type":"uint256"},{"indexed":false,"internalType":"bytes32","name":"posthookData","type":"bytes32"}],"name":"PosthookFail","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"outbound_tkn","type":"address"},{"indexed":true,"internalType":"address","name":"inbound_tkn","type":"address"},{"indexed":false,"internalType":"bool","name":"value","type":"bool"}],"name":"SetActive","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"outbound_tkn","type":"address"},{"indexed":true,"internalType":"address","name":"inbound_tkn","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"SetDensity","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"outbound_tkn","type":"address"},{"indexed":true,"internalType":"address","name":"inbound_tkn","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"SetFee","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"outbound_tkn","type":"address"},{"indexed":true,"internalType":"address","name":"inbound_tkn","type":"address"},{"indexed":false,"internalType":"uint256","name":"offer_gasbase","type":"uint256"}],"name":"SetGasbase","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"SetGasmax","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"SetGasprice","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"value","type":"address"}],"name":"SetGovernance","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"value","type":"address"}],"name":"SetMonitor","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"bool","name":"value","type":"bool"}],"name":"SetNotify","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"bool","name":"value","type":"bool"}],"name":"SetUseOracle","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"value","type":"address"}],"name":"SetVault","type":"event"},{"inputs":[],"name":"DOMAIN_SEPARATOR","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"PERMIT_TYPEHASH","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"outbound_tkn","type":"address"},{"internalType":"address","name":"inbound_tkn","type":"address"},{"internalType":"uint256","name":"fee","type":"uint256"},{"internalType":"uint256","name":"density","type":"uint256"},{"internalType":"uint256","name":"offer_gasbase","type":"uint256"}],"name":"activate","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"},{"internalType":"address","name":"","type":"address"},{"internalType":"address","name":"","type":"address"},{"internalType":"address","name":"","type":"address"}],"name":"allowances","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"outbound_tkn","type":"address"},{"internalType":"address","name":"inbound_tkn","type":"address"},{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"value","type":"uint256"}],"name":"approve","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"outbound_tkn","type":"address"},{"internalType":"address","name":"inbound_tkn","type":"address"}],"name":"best","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"outbound_tkn","type":"address"},{"internalType":"address","name":"inbound_tkn","type":"address"}],"name":"config","outputs":[{"internalType":"GlobalPacked","name":"_global","type":"uint256"},{"internalType":"LocalPacked","name":"_local","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"outbound_tkn","type":"address"},{"internalType":"address","name":"inbound_tkn","type":"address"}],"name":"configInfo","outputs":[{"components":[{"internalType":"address","name":"monitor","type":"address"},{"internalType":"bool","name":"useOracle","type":"bool"},{"internalType":"bool","name":"notify","type":"bool"},{"internalType":"uint256","name":"gasprice","type":"uint256"},{"internalType":"uint256","name":"gasmax","type":"uint256"},{"internalType":"bool","name":"dead","type":"bool"}],"internalType":"structGlobalUnpacked","name":"global","type":"tuple"},{"components":[{"internalType":"bool","name":"active","type":"bool"},{"internalType":"uint256","name":"fee","type":"uint256"},{"internalType":"uint256","name":"density","type":"uint256"},{"internalType":"uint256","name":"offer_gasbase","type":"uint256"},{"internalType":"bool","name":"lock","type":"bool"},{"internalType":"uint256","name":"best","type":"uint256"},{"internalType":"uint256","name":"last","type":"uint256"}],"internalType":"structLocalUnpacked","name":"local","type":"tuple"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"outbound_tkn","type":"address"},{"internalType":"address","name":"inbound_tkn","type":"address"}],"name":"deactivate","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"components":[{"internalType":"address","name":"outbound_tkn","type":"address"},{"internalType":"address","name":"inbound_tkn","type":"address"},{"internalType":"uint256","name":"offerId","type":"uint256"},{"internalType":"OfferPacked","name":"offer","type":"uint256"},{"internalType":"uint256","name":"wants","type":"uint256"},{"internalType":"uint256","name":"gives","type":"uint256"},{"internalType":"OfferDetailPacked","name":"offerDetail","type":"uint256"},{"internalType":"GlobalPacked","name":"global","type":"uint256"},{"internalType":"LocalPacked","name":"local","type":"uint256"}],"internalType":"structMgvLib.SingleOrder","name":"sor","type":"tuple"},{"internalType":"address","name":"taker","type":"address"}],"name":"flashloan","outputs":[{"internalType":"uint256","name":"gasused","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"maker","type":"address"}],"name":"fund","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[],"name":"fund","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[],"name":"governance","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"OfferPacked","name":"offer","type":"uint256"}],"name":"isLive","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"kill","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"outbound_tkn","type":"address"},{"internalType":"address","name":"inbound_tkn","type":"address"}],"name":"locked","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"outbound_tkn","type":"address"},{"internalType":"address","name":"inbound_tkn","type":"address"},{"internalType":"uint256","name":"takerWants","type":"uint256"},{"internalType":"uint256","name":"takerGives","type":"uint256"},{"internalType":"bool","name":"fillWants","type":"bool"}],"name":"marketOrder","outputs":[{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"outbound_tkn","type":"address"},{"internalType":"address","name":"inbound_tkn","type":"address"},{"internalType":"uint256","name":"takerWants","type":"uint256"},{"internalType":"uint256","name":"takerGives","type":"uint256"},{"internalType":"bool","name":"fillWants","type":"bool"},{"internalType":"address","name":"taker","type":"address"}],"name":"marketOrderFor","outputs":[{"internalType":"uint256","name":"takerGot","type":"uint256"},{"internalType":"uint256","name":"takerGave","type":"uint256"},{"internalType":"uint256","name":"bounty","type":"uint256"},{"internalType":"uint256","name":"feePaid","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"outbound_tkn","type":"address"},{"internalType":"address","name":"inbound_tkn","type":"address"},{"internalType":"uint256","name":"wants","type":"uint256"},{"internalType":"uint256","name":"gives","type":"uint256"},{"internalType":"uint256","name":"gasreq","type":"uint256"},{"internalType":"uint256","name":"gasprice","type":"uint256"},{"internalType":"uint256","name":"pivotId","type":"uint256"}],"name":"newOffer","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"nonces","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"},{"internalType":"address","name":"","type":"address"},{"internalType":"uint256","name":"","type":"uint256"}],"name":"offerDetails","outputs":[{"internalType":"OfferDetailPacked","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"outbound_tkn","type":"address"},{"internalType":"address","name":"inbound_tkn","type":"address"},{"internalType":"uint256","name":"offerId","type":"uint256"}],"name":"offerInfo","outputs":[{"components":[{"internalType":"uint256","name":"prev","type":"uint256"},{"internalType":"uint256","name":"next","type":"uint256"},{"internalType":"uint256","name":"wants","type":"uint256"},{"internalType":"uint256","name":"gives","type":"uint256"}],"internalType":"structOfferUnpacked","name":"offer","type":"tuple"},{"components":[{"internalType":"address","name":"maker","type":"address"},{"internalType":"uint256","name":"gasreq","type":"uint256"},{"internalType":"uint256","name":"offer_gasbase","type":"uint256"},{"internalType":"uint256","name":"gasprice","type":"uint256"}],"internalType":"structOfferDetailUnpacked","name":"offerDetail","type":"tuple"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"},{"internalType":"address","name":"","type":"address"},{"internalType":"uint256","name":"","type":"uint256"}],"name":"offers","outputs":[{"internalType":"OfferPacked","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"outbound_tkn","type":"address"},{"internalType":"address","name":"inbound_tkn","type":"address"},{"internalType":"address","name":"owner","type":"address"},{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"value","type":"uint256"},{"internalType":"uint256","name":"deadline","type":"uint256"},{"internalType":"uint8","name":"v","type":"uint8"},{"internalType":"bytes32","name":"r","type":"bytes32"},{"internalType":"bytes32","name":"s","type":"bytes32"}],"name":"permit","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"outbound_tkn","type":"address"},{"internalType":"address","name":"inbound_tkn","type":"address"},{"internalType":"uint256","name":"offerId","type":"uint256"},{"internalType":"bool","name":"deprovision","type":"bool"}],"name":"retractOffer","outputs":[{"internalType":"uint256","name":"provision","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"outbound_tkn","type":"address"},{"internalType":"address","name":"inbound_tkn","type":"address"},{"internalType":"uint256","name":"density","type":"uint256"}],"name":"setDensity","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"outbound_tkn","type":"address"},{"internalType":"address","name":"inbound_tkn","type":"address"},{"internalType":"uint256","name":"fee","type":"uint256"}],"name":"setFee","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"outbound_tkn","type":"address"},{"internalType":"address","name":"inbound_tkn","type":"address"},{"internalType":"uint256","name":"offer_gasbase","type":"uint256"}],"name":"setGasbase","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"gasmax","type":"uint256"}],"name":"setGasmax","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"gasprice","type":"uint256"}],"name":"setGasprice","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"governanceAddress","type":"address"}],"name":"setGovernance","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"monitor","type":"address"}],"name":"setMonitor","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bool","name":"notify","type":"bool"}],"name":"setNotify","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bool","name":"useOracle","type":"bool"}],"name":"setUseOracle","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"vaultAddress","type":"address"}],"name":"setVault","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"outbound_tkn","type":"address"},{"internalType":"address","name":"inbound_tkn","type":"address"},{"internalType":"uint256[4][]","name":"targets","type":"uint256[4][]"},{"internalType":"bool","name":"fillWants","type":"bool"}],"name":"snipes","outputs":[{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"outbound_tkn","type":"address"},{"internalType":"address","name":"inbound_tkn","type":"address"},{"internalType":"uint256[4][]","name":"targets","type":"uint256[4][]"},{"internalType":"bool","name":"fillWants","type":"bool"},{"internalType":"address","name":"taker","type":"address"}],"name":"snipesFor","outputs":[{"internalType":"uint256","name":"successes","type":"uint256"},{"internalType":"uint256","name":"takerGot","type":"uint256"},{"internalType":"uint256","name":"takerGave","type":"uint256"},{"internalType":"uint256","name":"bounty","type":"uint256"},{"internalType":"uint256","name":"feePaid","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"outbound_tkn","type":"address"},{"internalType":"address","name":"inbound_tkn","type":"address"},{"internalType":"uint256","name":"wants","type":"uint256"},{"internalType":"uint256","name":"gives","type":"uint256"},{"internalType":"uint256","name":"gasreq","type":"uint256"},{"internalType":"uint256","name":"gasprice","type":"uint256"},{"internalType":"uint256","name":"pivotId","type":"uint256"},{"internalType":"uint256","name":"offerId","type":"uint256"}],"name":"updateOffer","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[],"name":"vault","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"withdraw","outputs":[{"internalType":"bool","name":"noRevert","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"stateMutability":"payable","type":"receive"}]
*/

// SPDX-License-Identifier:	BSD-2-Clause

// TransferLib.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
pragma solidity ^0.8.10;

pragma abicoder v2;

import {IERC20} from "mgv_src/MgvLib.sol";

// TODO-foundry-merge explain what this contract does

library TransferLib {
  // utils
  ///@notice This transfer amount of token to recipient address
  ///@param token Token to be transferred
  ///@param recipient Address of the recipient the tokens will be transferred to
  ///@param amount The amount of tokens to be transferred
  function transferToken(IERC20 token, address recipient, uint amount) internal returns (bool) {
    if (amount == 0 || recipient == address(this)) {
      return true;
    }
    (bool success, bytes memory data) =
      address(token).call(abi.encodeWithSelector(token.transfer.selector, recipient, amount));
    return (success && (data.length == 0 || abi.decode(data, (bool))));
  }

  ///@notice This transfer amount of token to recipient address from spender address
  ///@param token Token to be transferred
  ///@param spender Address of the spender, where the tokens will be transferred from
  ///@param recipient Address of the recipient, where the tokens will be transferred to
  ///@param amount The amount of tokens to be transferred
  function transferTokenFrom(IERC20 token, address spender, address recipient, uint amount) internal returns (bool) {
    if (amount == 0 || spender == recipient) {
      return true;
    }
    // optim to avoid requiring contract to approve itself
    if (spender == address(this)) {
      return transferToken(token, recipient, amount);
    }
    (bool success, bytes memory data) =
      address(token).call(abi.encodeWithSelector(token.transferFrom.selector, spender, recipient, amount));
    return (success && (data.length == 0 || abi.decode(data, (bool))));
  }
}

// SPDX-License-Identifier:	BSD-2-Clause

// MangroveOffer.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
pragma solidity ^0.8.10;

pragma abicoder v2;

import {AccessControlled} from "mgv_src/strategies/utils/AccessControlled.sol";
import {MangroveOfferStorage as MOS} from "./MangroveOfferStorage.sol";
import {IOfferLogic} from "mgv_src/strategies/interfaces/IOfferLogic.sol";
import {MgvLib, IERC20, MgvStructs} from "mgv_src/MgvLib.sol";
import {IMangrove} from "mgv_src/IMangrove.sol";
import {AbstractRouter} from "mgv_src/strategies/routers/AbstractRouter.sol";

/// @title This contract is the basic building block for Mangrove strats.
/// @notice It contains the mandatory interface expected by Mangrove (`IOfferLogic` is `IMaker`) and enforces additional functions implementations (via `IOfferLogic`).
/// In the comments we use the term "offer maker" to designate the address that controls updates of an offer on mangrove.
/// In `Direct` strategies, `this` contract is the offer maker, in `Forwarder` strategies, the offer maker should be `msg.sender` of the annotated function.
/// @dev Naming scheme:
/// `f() public`: can be used, as is, in all descendants of `this` contract
/// `_f() internal`: descendant of this contract should provide a public wrapper of this function
/// `__f__() virtual internal`: descendant of this contract may override this function to specialize behaviour of `makerExecute` or `makerPosthook`

abstract contract MangroveOffer is AccessControlled, IOfferLogic {
  IMangrove public immutable MGV;
  AbstractRouter public constant NO_ROUTER = AbstractRouter(address(0));
  bytes32 constant OUT_OF_FUNDS = keccak256("mgv/insufficientProvision");
  bytes32 constant BELOW_DENSITY = keccak256("mgv/writeOffer/density/tooLow");

  modifier mgvOrAdmin() {
    require(msg.sender == admin() || msg.sender == address(MGV), "AccessControlled/Invalid");
    _;
  }

  ///@notice Mandatory function to allow `this` contract to receive native tokens from Mangrove after a call to `MGV.withdraw()`
  ///@dev override this function if `this` contract needs to handle local accounting of user funds.
  receive() external payable virtual {}

  /**
   * @notice `MangroveOffer`'s constructor
   * @param mgv The Mangrove deployment that is allowed to call `this` contract for trade execution and posthook and on which `this` contract will post offers.
   */
  constructor(IMangrove mgv) AccessControlled(msg.sender) {
    MGV = mgv;
  }

  /// @inheritdoc IOfferLogic
  function offerGasreq() public view returns (uint) {
    AbstractRouter router_ = router();
    if (router_ != NO_ROUTER) {
      return MOS.getStorage().ofr_gasreq + router_.gasOverhead();
    } else {
      return MOS.getStorage().ofr_gasreq;
    }
  }

  ///*****************************
  /// Mandatory callback functions
  ///*****************************

  ///@notice `makerExecute` is the callback function to execute all offers that were posted on Mangrove by `this` contract.
  ///@param order a data structure that recapitulates the taker order and the offer as it was posted on mangrove
  ///@return ret a bytes32 word to pass information (if needed) to the posthook
  ///@dev it may not be overriden although it can be customized using `__lastLook__`, `__put__` and `__get__` hooks.
  /// NB #1: if `makerExecute` reverts, the offer will be considered to be refusing the trade.
  /// NB #2: `makerExecute` may return a `bytes32` word to pass information to posthook w/o using storage reads/writes.
  /// NB #3: Reneging on trade will have the following effects:
  /// * Offer is removed from the Order Book
  /// * Offer bounty will be withdrawn from offer provision and sent to the offer taker. The remaining provision will be credited to the maker account on Mangrove
  function makerExecute(MgvLib.SingleOrder calldata order)
    external
    override
    onlyCaller(address(MGV))
    returns (bytes32 ret)
  {
    ret = __lastLook__(order);
    if (__put__(order.gives, order) > 0) {
      revert("mgvOffer/abort/putFailed");
    }
    if (__get__(order.wants, order) > 0) {
      revert("mgvOffer/abort/getFailed");
    }
  }

  /// @notice `makerPosthook` is the callback function that is called by Mangrove *after* the offer execution.
  /// @param order a data structure that recapitulates the taker order and the offer as it was posted on mangrove
  /// @param result a data structure that gathers information about trade execution
  /// @dev It may not be overridden although it can be customized via the post-hooks `__posthookSuccess__` and `__posthookFallback__` (see below).
  /// NB: If `makerPosthook` reverts, mangrove will log the first 32 bytes of the revert reason in the `PosthookFail` log.
  /// NB: Reverting posthook does not revert trade execution
  function makerPosthook(MgvLib.SingleOrder calldata order, MgvLib.OrderResult calldata result)
    external
    override
    onlyCaller(address(MGV))
  {
    if (result.mgvData == "mgv/tradeSuccess") {
      // toplevel posthook may ignore returned value which is only usefull for (vertical) compositionality
      __posthookSuccess__(order, result.makerData);
    } else {
      emit LogIncident(
        MGV, IERC20(order.outbound_tkn), IERC20(order.inbound_tkn), order.offerId, result.makerData, result.mgvData
        );
      __posthookFallback__(order, result);
    }
  }

  /// @inheritdoc IOfferLogic
  function setGasreq(uint gasreq) public override onlyAdmin {
    require(uint24(gasreq) == gasreq, "mgvOffer/gasreq/overflow");
    MOS.getStorage().ofr_gasreq = gasreq;
    emit SetGasreq(gasreq);
  }

  /// @inheritdoc IOfferLogic
  function setRouter(AbstractRouter router_) public override onlyAdmin {
    MOS.getStorage().router = router_;
    emit SetRouter(router_);
  }

  /// @inheritdoc IOfferLogic
  function router() public view returns (AbstractRouter) {
    return MOS.getStorage().router;
  }

  /// @inheritdoc IOfferLogic
  function approve(IERC20 token, address spender, uint amount) public override onlyAdmin returns (bool) {
    return token.approve(spender, amount);
  }

  /// @notice getter of the address where offer maker is storing its liquidity
  /// @param maker the address of the offer maker one wishes to know the reserve of.
  /// @return reserve_ the address of the offer maker's reserve of liquidity.
  /// @dev if `this` contract is not acting of behalf of some user, `_reserve(address(this))` must be defined at all time.
  /// for `Direct` strategies, if  `_reserve(address(this)) != address(this)` then `this` contract must use a router to pull/push liquidity to its reserve.
  function _reserve(address maker) internal view returns (address reserve_) {
    reserve_ = MOS.getStorage().reserves[maker];
  }

  /// @notice sets reserve of an offer maker.
  /// @param maker the address of the offer maker
  /// @param reserve_ the address of the offer maker's reserve of liquidity
  /// @dev use `_setReserve(address(this), '0x...')` when `this` contract is the offer maker (`Direct` strats)
  function _setReserve(address maker, address reserve_) internal {
    require(reserve_ != address(0), "SingleUser/0xReserve");
    MOS.getStorage().reserves[maker] = reserve_;
  }

  /// @inheritdoc IOfferLogic
  function activate(IERC20[] calldata tokens) external override onlyAdmin {
    for (uint i = 0; i < tokens.length; i++) {
      __activate__(tokens[i]);
    }
  }

  /// @inheritdoc IOfferLogic
  function checkList(IERC20[] calldata tokens) external view override {
    AbstractRouter router_ = router();
    for (uint i = 0; i < tokens.length; i++) {
      // checking `this` contract's approval
      require(tokens[i].allowance(address(this), address(MGV)) > 0, "MangroveOffer/LogicMustApproveMangrove");
      // if contract has a router, checking router is allowed
      if (router_ != NO_ROUTER) {
        require(tokens[i].allowance(address(this), address(router_)) > 0, "MangroveOffer/LogicMustApproveRouter");
      }
      __checkList__(tokens[i]);
    }
  }

  /// @inheritdoc IOfferLogic
  function withdrawFromMangrove(uint amount, address payable receiver) external onlyAdmin {
    if (amount == type(uint).max) {
      amount = MGV.balanceOf(address(this));
      if (amount == 0) {
        return; // optimization
      }
    }
    require(MGV.withdraw(amount), "mgvOffer/withdrawFromMgv/withdrawFail");
    (bool noRevert,) = receiver.call{value: amount}("");
    require(noRevert, "mgvOffer/withdrawFromMgv/payableCallFail");
  }

  ///@notice strat-specific additional activation steps (override if needed).
  ///@param token the ERC20 one wishes this contract to trade on.
  ///@custom:hook overrides of this hook should be conservative and call `super.__activate__(token)`
  function __activate__(IERC20 token) internal virtual {
    AbstractRouter router_ = router();
    // any strat requires `this` contract to approve Mangrove for pulling funds at the end of `makerExecute`
    require(token.approve(address(MGV), type(uint).max), "mgvOffer/approveMangrove/Fail");
    if (router_ != NO_ROUTER) {
      // allowing router to pull `token` from this contract (for the `push` function of the router)
      require(token.approve(address(router_), type(uint).max), "mgvOffer/activate/approveRouterFail");
      // letting router performs additional necessary approvals (if any)
      // this will only work is `this` contract is an authorized maker of the router (`router.bind(address(this))` has been called).
      router_.activate(token);
    }
  }

  ///@notice strat-specific additional activation check list
  ///@param token the ERC20 one wishes this contract to trade on.
  ///@custom:hook overrides of this hook should be conservative and call `super.__checkList__(token)`
  function __checkList__(IERC20 token) internal view virtual {
    token; //ssh
  }

  ///@notice Hook that implements where the inbound token, which are brought by the Offer Taker, should go during Taker Order's execution.
  ///@param amount of `inbound` tokens that are on `this` contract's balance and still need to be deposited somewhere
  ///@param order is a recall of the taker order that is at the origin of the current trade.
  ///@return missingPut (<=`amount`) is the amount of `inbound` tokens whose deposit location has not been decided (possibly because of a failure) during this function execution
  ///@dev if the last nested call to `__put__` returns a non zero value, trade execution will revert
  ///@custom:hook overrides of this hook should be conservative and call `super.__put__(missing, order)`
  function __put__(uint amount, MgvLib.SingleOrder calldata order) internal virtual returns (uint missingPut);

  ///@notice Hook that implements where the outbound token, which are promised to the taker, should be fetched from, during Taker Order's execution.
  ///@param amount of `outbound` tokens that still needs to be brought to the balance of `this` contract when entering this function
  ///@param order is a recall of the taker order that is at the origin of the current trade.
  ///@return missingGet (<=`amount`), which is the amount of `outbound` tokens still need to be fetched at the end of this function
  ///@dev if the last nested call to `__get__` returns a non zero value, trade execution will revert
  ///@custom:hook overrides of this hook should be conservative and call `super.__get__(missing, order)`
  function __get__(uint amount, MgvLib.SingleOrder calldata order) internal virtual returns (uint missingGet);

  /// @notice Hook that implements a last look check during Taker Order's execution.
  /// @param order is a recall of the taker order that is at the origin of the current trade.
  /// @return data is a message that will be passed to posthook provided `makerExecute` does not revert.
  /// @dev __lastLook__ should revert if trade is to be reneged on. If not, returned `bytes32` are passed to `makerPosthook` in the `makerData` field.
  // @custom:hook overrides of this hook should be conservative and call `super.__lastLook__(order)`.
  // Special bytes32 word can be used to switch a particular behavior of `__posthookSuccess__`, e.g not to repost offer in case of a partial fill. */

  function __lastLook__(MgvLib.SingleOrder calldata order) internal virtual returns (bytes32 data) {
    order; //shh
    return "mgvOffer/tradeSuccess";
  }

  ///@notice Post-hook that implements fallback behavior when Taker Order's execution failed unexpectedly.
  ///@param order is a recall of the taker order that is at the origin of the current trade.
  ///@param result contains information about trade.
  /**
   * @dev `result.mgvData` is Mangrove's verdict about trade success
   * `result.makerData` either contains the first 32 bytes of revert reason if `makerExecute` reverted
   */
  /// @custom:hook overrides of this hook should be conservative and call `super.__posthookFallback__(order, result)`
  function __posthookFallback__(MgvLib.SingleOrder calldata order, MgvLib.OrderResult calldata result)
    internal
    virtual
    returns (bytes32)
  {
    order;
    result;
    return "";
  }

  ///@notice Given the current taker order that (partially) consumes an offer, this hook is used to declare how much `order.inbound_tkn` the offer wants after it is reposted.
  ///@param order is a recall of the taker order that is being treated.
  ///@return new_wants the new volume of `inbound_tkn` the offer will ask for on Mangrove
  ///@dev default is to require the original amount of tokens minus those that have been given by the taker during trade execution.
  function __residualWants__(MgvLib.SingleOrder calldata order) internal virtual returns (uint new_wants) {
    new_wants = order.offer.wants() - order.gives;
  }

  ///@notice Given the current taker order that (partially) consumes an offer, this hook is used to declare how much `order.outbound_tkn` the offer gives after it is reposted.
  ///@param order is a recall of the taker order that is being treated.
  ///@return new_gives the new volume of `outbound_tkn` the offer will give if fully taken.
  ///@dev default is to require the original amount of tokens minus those that have been sent to the taker during trade execution.
  function __residualGives__(MgvLib.SingleOrder calldata order) internal virtual returns (uint) {
    return order.offer.gives() - order.wants;
  }

  ///@notice Post-hook that implements default behavior when Taker Order's execution succeeded.
  ///@param order is a recall of the taker order that is at the origin of the current trade.
  ///@param maker_data is the returned value of the `__lastLook__` hook, triggered during trade execution. The special value `"lastLook/retract"` should be treated as an instruction not to repost the offer on the book.
  /// @custom:hook overrides of this hook should be conservative and call `super.__posthookSuccess__(order, maker_data)`
  function __posthookSuccess__(MgvLib.SingleOrder calldata order, bytes32 maker_data)
    internal
    virtual
    returns (bytes32 data)
  {
    maker_data; // maker_data can be used in overrides to skip reposting for instance. It is ignored in the default behavior.
    // now trying to repost residual
    uint new_gives = __residualGives__(order);
    // Density check at each repost would be too gas costly.
    // We only treat the special case of `gives==0` (total fill).
    // Offer below the density will cause Mangrove to throw so we encapsulate the call to `updateOffer` in order not to revert posthook for posting at dust level.
    if (new_gives == 0) {
      return "posthook/filled";
    }
    uint new_wants = __residualWants__(order);
    try MGV.updateOffer(
      order.outbound_tkn,
      order.inbound_tkn,
      new_wants,
      new_gives,
      order.offerDetail.gasreq(),
      order.offerDetail.gasprice(),
      order.offer.next(),
      order.offerId
    ) {
      return "posthook/reposted";
    } catch Error(string memory reason) {
      // `updateOffer` can fail when this contract is under provisioned
      // or if `offer.gives` is below density
      // Log incident only if under provisioned
      bytes32 reason_hsh = keccak256(bytes(reason));
      if (reason_hsh == BELOW_DENSITY) {
        return "posthook/dustRemainder"; // offer not reposted
      } else {
        // for all other reason we let the revert propagate (Mangrove logs revert reason in the `PosthookFail` event).
        revert(reason);
      }
    }
  }

  ///@inheritdoc IOfferLogic
  ///@param outbound_tkn the outbound token used to identify the order book
  ///@param inbound_tkn the inbound token used to identify the order book
  ///@param gasreq the gas required by the offer. Give > type(uint24).max to use `this.offerGasreq()`
  ///@param gasprice the upper bound on gas price. Give 0 to use Mangrove's gasprice
  ///@param offerId the offer id. Set this to 0 if one is not reposting an offer
  ///@dev if `offerId` is not in the Order Book, will simply return how much is needed to post
  function getMissingProvision(IERC20 outbound_tkn, IERC20 inbound_tkn, uint gasreq, uint gasprice, uint offerId)
    public
    view
    returns (uint)
  {
    (MgvStructs.GlobalPacked globalData, MgvStructs.LocalPacked localData) =
      MGV.config(address(outbound_tkn), address(inbound_tkn));
    MgvStructs.OfferDetailPacked offerDetailData =
      MGV.offerDetails(address(outbound_tkn), address(inbound_tkn), offerId);
    uint _gp;
    if (globalData.gasprice() > gasprice) {
      _gp = globalData.gasprice();
    } else {
      _gp = gasprice;
    }
    if (gasreq >= type(uint24).max) {
      gasreq = offerGasreq(); // this includes overhead of router if any
    }
    uint bounty = (gasreq + localData.offer_gasbase()) * _gp * 10 ** 9; // in WEI
    // if `offerId` is not in the OfferList or deprovisioned, computed value below will be 0
    uint currentProvisionLocked =
      (offerDetailData.gasreq() + offerDetailData.offer_gasbase()) * offerDetailData.gasprice() * 10 ** 9;
    return (currentProvisionLocked >= bounty ? 0 : bounty - currentProvisionLocked);
  }
}

// SPDX-License-Identifier:	BSD-2-Clause

// AccessedControlled.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
pragma solidity ^0.8.10;

pragma abicoder v2;

import {AccessControlledStorage as ACS} from "./AccessControlledStorage.sol";

/// @title This contract is used to restrict access to privileged functions of inheriting contracts through modifiers.
/// @notice The contract stores an admin address which is checked against `msg.sender` in the `onlyAdmin` modifier.
/// @notice Additionally, a specific `msg.sender` can be verified with the `onlyCaller` modifier.
contract AccessControlled {
  /**
   * @notice `AccessControlled`'s constructor
   * @param _admin The address of the admin that can access privileged functions and also allowed to change the admin. Cannot be `address(0)`.
   */
  constructor(address _admin) {
    require(_admin != address(0), "accessControlled/0xAdmin");
    ACS.getStorage().admin = _admin;
  }

  //TODO [lnist] It does not seem like onlyCaller is used with caller being address(0). To avoid accidents, it seems safer to remove the option.
  /**
   * @notice This modifier verifies that if the `caller` parameter is not `address(0)`, then `msg.sender` is the caller.
   * @param caller The address of the caller (or address(0)) that can access the modified function.
   */
  modifier onlyCaller(address caller) {
    require(caller == address(0) || msg.sender == caller, "AccessControlled/Invalid");
    _;
  }

  /**
   * @notice Retrieves the current admin.
   */
  function admin() public view returns (address) {
    return ACS.getStorage().admin;
  }

  /**
   * @notice This modifier verifies that `msg.sender` is the admin.
   */
  modifier onlyAdmin() {
    require(msg.sender == admin(), "AccessControlled/Invalid");
    _;
  }

  /**
   * @notice This sets the admin. Only the current admin can change the admin.
   * @param _admin The new admin. Cannot be `address(0)`.
   */
  function setAdmin(address _admin) public onlyAdmin {
    require(_admin != address(0), "AccessControlled/0xAdmin");
    ACS.getStorage().admin = _admin;
  }
}

// SPDX-License-Identifier:	BSD-2-Clause

//AbstractRouterStorage.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

pragma solidity ^0.8.10;

pragma abicoder v2;

library AbstractRouterStorage {
  struct Layout {
    mapping(address => bool) makers;
    uint gas_overhead;
  }

  function getStorage() internal pure returns (Layout storage st) {
    bytes32 storagePosition = keccak256("Mangrove.AbstractRouterStorageLib.Layout");
    assembly {
      st.slot := storagePosition
    }
  }
}

pragma solidity ^0.8.13;

// SPDX-License-Identifier: Unlicense

// MgvPack.sol

// This is free and unencumbered software released into the public domain.

// Anyone is free to copy, modify, publish, use, compile, sell, or distribute this software, either in source code form or as a compiled binary, for any purpose, commercial or non-commercial, and by any means.

// In jurisdictions that recognize copyright laws, the author or authors of this software dedicate any and all copyright interest in the software to the public domain. We make this dedication for the benefit of the public at large and to the detriment of our heirs and successors. We intend this dedication to be an overt act of relinquishment in perpetuity of all present and future rights to this software under copyright law.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// For more information, please refer to <https://unlicense.org/>

/* ************************************************** *
            GENERATED FILE. DO NOT EDIT.
 * ************************************************** */

// Note: can't do Type.Unpacked because typechain mixes up multiple 'Unpacked' structs under different namespaces. So for consistency we don't do Type.Packed either. We do TypeUnpacked and TypePacked.

import {OfferPacked, OfferUnpacked} from "./MgvOffer.post.sol";
import "./MgvOffer.post.sol" as Offer;
import {OfferDetailPacked, OfferDetailUnpacked} from "./MgvOfferDetail.post.sol";
import "./MgvOfferDetail.post.sol" as OfferDetail;
import {GlobalPacked, GlobalUnpacked} from "./MgvGlobal.post.sol";
import "./MgvGlobal.post.sol" as Global;
import {LocalPacked, LocalUnpacked} from "./MgvLocal.post.sol";
import "./MgvLocal.post.sol" as Local;

// SPDX-License-Identifier:	BSD-2-Clause

// MangroveOffer.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
pragma solidity ^0.8.10;

pragma abicoder v2;

import "mgv_src/strategies/interfaces/IOfferLogic.sol";

// Naming scheme:
// `f() public`: can be used as is in all descendants of `this` contract
// `_f() internal`: descendant of this contract should provide a public wrapper of this function
// `__f__() virtual internal`: descendant of this contract may override this function to specialize the strat

/// MangroveOffer is the basic building block to implement a reactive offer that interfaces with the Mangrove
library MangroveOfferStorage {
  struct Layout {
    // default values
    uint ofr_gasreq;
    AbstractRouter router;
    mapping(address => address) reserves;
  }

  function getStorage() internal pure returns (Layout storage st) {
    bytes32 storagePosition = keccak256("Mangrove.MangroveOfferStorage");
    assembly {
      st.slot := storagePosition
    }
  }
}

// SPDX-License-Identifier:	BSD-2-Clause

// IOfferLogic.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

pragma solidity >=0.8.0;

pragma abicoder v2;

import {IMangrove} from "mgv_src/IMangrove.sol";
import {IERC20, IMaker} from "mgv_src/MgvLib.sol";
import {AbstractRouter} from "mgv_src/strategies/routers/AbstractRouter.sol";

///@title IOfferLogic interface for offer management
///@notice It is an IMaker for Mangrove

interface IOfferLogic is IMaker {
  ///@notice Log incident (during post trade execution)
  event LogIncident(
    IMangrove mangrove,
    IERC20 indexed outbound_tkn,
    IERC20 indexed inbound_tkn,
    uint indexed offerId,
    bytes32 makerData,
    bytes32 mgvData
  );

  ///@notice Logging change of router address
  event SetRouter(AbstractRouter);

  ///@notice Logging change in default gasreq
  event SetGasreq(uint);

  ///@notice Actual gas requirement when posting offers via `this` strategy. Returned value may change if `this` contract's router is updated.
  ///@return total gas cost including router specific costs (if any).
  function offerGasreq() external view returns (uint);

  ///@notice Computes missing provision to repost `offerId` at given `gasreq` and `gasprice` ignoring current contract's balance on Mangrove.
  ///@return missingProvision to repost `offerId`.
  function getMissingProvision(IERC20 outbound_tkn, IERC20 inbound_tkn, uint gasreq, uint gasprice, uint offerId)
    external
    view
    returns (uint missingProvision);

  ///@notice sets `this` contract's default gasreq for `new/updateOffer`.
  ///@param gasreq an overapproximation of the gas required to handle trade and posthook without considering liquidity routing specific costs.
  ///@dev this should only take into account the gas cost of managing offer posting/updating during trade execution. Router specific gas cost are taken into account in the getter `offerGasreq()`
  function setGasreq(uint gasreq) external;

  ///@notice sets a new router to pull outbound tokens from contract's reserve to `this` and push inbound tokens to reserve.
  ///@param router_ the new router contract that this contract should use. Use `NO_ROUTER` for no router.
  ///@dev new router needs to be approved by `this` contract to push funds to reserve (see `activate` function). It also needs to be approved by reserve to pull from it.
  function setRouter(AbstractRouter router_) external;

  ///@notice Approves a spender to transfer a certain amount of tokens on behalf of `this` contract.
  ///@param token the ERC20 token contract
  ///@param spender the approved spender
  ///@param amount the spending amount
  ///@dev admin may use this function to revoke approvals of `this` contract that are set after a call to `activate`.
  function approve(IERC20 token, address spender, uint amount) external returns (bool);

  ///@notice  withdraw ERC20 tokens from `reserve()`
  ///@param token the ERC20 token one wishes to withdraw.
  ///@param receiver the address of the receiver of the withdrawn tokens.
  ///@param amount the amount of tokens one wishes to withdraw.
  function withdrawToken(IERC20 token, address receiver, uint amount) external returns (bool success);

  ///@notice computes the provision that can be redeemed when deprovisioning a certain offer.
  ///@param outbound_tkn the outbound token of the offer list
  ///@param inbound_tkn the inbound token of the offer list
  ///@param offerId the identifier of the offer in the offer list
  ///@return provision the amount of native tokens that can be redeemed when deprovisioning the offer
  function provisionOf(IERC20 outbound_tkn, IERC20 inbound_tkn, uint offerId) external view returns (uint provision);

  ///@notice verifies that this contract's current state is ready to be used by msg.sender to post offers on Mangrove
  ///@dev throws with a reason when there is a missing approval
  function checkList(IERC20[] calldata tokens) external view;

  ///@return balance the `token` amount that `msg.sender` has in the contract's reserve
  function tokenBalance(IERC20 token) external view returns (uint balance);

  /// @notice allows `this` contract to be a liquidity provider for a particular asset by performing the necessary approvals
  /// @param tokens the ERC20 `this` contract will approve to be able to trade on Mangrove's corresponding markets.
  function activate(IERC20[] calldata tokens) external;

  ///@notice withdraws ETH from the `this` contract's balance on Mangrove.
  ///@param amount the amount of WEI one wishes to withdraw.
  ///@param receiver the address of the receiver of the funds.
  ///@dev Since a call is made to the `receiver`, this function is subject to reentrancy.
  function withdrawFromMangrove(uint amount, address payable receiver) external;

  ///@notice updates an offer existing on Mangrove (not necessarily live).
  ///@param outbound_tkn the outbound token of the offer list of the offer
  ///@param inbound_tkn the outbound token of the offer list of the offer
  ///@param wants the new amount of outbound tokens the offer maker requires for a complete fill
  ///@param gives the new amount of inbound tokens the offer maker gives for a complete fill
  ///@param gasreq the new amount of gas units that are required to execute the trade (use type(uint).max for using `this.offerGasReq()`)
  ///@param gasprice the new gasprice used to compute offer's provision (use 0 to use Mangrove's gasprice)
  ///@param pivotId the pivot to use for re-inserting the offer in the list (use `offerId` if updated offer is live)
  ///@param offerId the id of the offer in the offer list.
  function updateOffer(
    IERC20 outbound_tkn,
    IERC20 inbound_tkn,
    uint wants,
    uint gives,
    uint gasreq,
    uint gasprice,
    uint pivotId,
    uint offerId
  ) external
    payable;

  ///@notice Retracts `offerId` from the (`outbound_tkn`,`inbound_tkn`) Offer list of Mangrove. Function call will throw if `this` contract is not the owner of `offerId`.
  ///@param deprovision is true if offer owner wishes to have the offer's provision pushed to its reserve
  ///@return received the amount of WEI thar are returned to `msg.sender` if `deprovision` is positioned.
  function retractOffer(
    IERC20 outbound_tkn,
    IERC20 inbound_tkn,
    uint offerId,
    bool deprovision // if set to `true`, `this` contract will receive the remaining provision (in WEI) associated to `offerId`.
  ) external
    returns (uint received);

  ///@notice returns the address of the vault holding offer maker's liquidity
  /// for `Direct` logics, this corresponds to the reserve of `this` contract
  /// for `Forwarder` logics, the returned reserve is the one of `msg.sender`
  ///@return reserve_ the address of the reserve of offer Maker.
  function reserve() external view returns (address reserve_);

  /**
   * @notice sets the address of the reserve of maker(s).
   * If `this` contract is a forwarder the call sets the reserve for `msg.sender`. Otherwise it sets the reserve for `address(this)`.
   */
  /// @param reserve the new address of offer maker's reserve
  function setReserve(address reserve) external;

  /// @notice Contract's router getter.
  /// @dev contract has a router if `this.router() != this.NO_ROUTER()`
  function router() external view returns (AbstractRouter);
}

// SPDX-License-Identifier:	BSD-2-Clause

// AccessedControlled.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
pragma solidity ^0.8.10;

pragma abicoder v2;

// TODO-foundry-merge explain what this contract does

library AccessControlledStorage {
  struct Layout {
    address admin;
  }

  function getStorage() internal pure returns (Layout storage st) {
    bytes32 storagePosition = keccak256("Mangrove.AccessControlledStorage");
    assembly {
      st.slot := storagePosition
    }
  }
}

pragma solidity ^0.8.13;

// SPDX-License-Identifier: Unlicense

// This is free and unencumbered software released into the public domain.

// Anyone is free to copy, modify, publish, use, compile, sell, or distribute this software, either in source code form or as a compiled binary, for any purpose, commercial or non-commercial, and by any means.

// In jurisdictions that recognize copyright laws, the author or authors of this software dedicate any and all copyright interest in the software to the public domain. We make this dedication for the benefit of the public at large and to the detriment of our heirs and successors. We intend this dedication to be an overt act of relinquishment in perpetuity of all present and future rights to this software under copyright law.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// For more information, please refer to <https://unlicense.org/>

// fields are of the form [name,bits,type]

// struct_defs are of the form [name,obj]

/* ************************************************** *
            GENERATED FILE. DO NOT EDIT.
 * ************************************************** */

/* since you can't convert bool to uint in an expression without conditionals,
 * we add a file-level function and rely on compiler optimization
 */
function uint_of_bool(bool b) pure returns (uint u) {
  assembly { u := b }
}

struct OfferUnpacked {
  uint prev;
  uint next;
  uint wants;
  uint gives;
}

//some type safety for each struct
type OfferPacked is uint;
using Library for OfferPacked global;

uint constant prev_bits  = 32;
uint constant next_bits  = 32;
uint constant wants_bits = 96;
uint constant gives_bits = 96;

uint constant prev_before  = 0;
uint constant next_before  = prev_before  + prev_bits ;
uint constant wants_before = next_before  + next_bits ;
uint constant gives_before = wants_before + wants_bits;

uint constant prev_mask  = 0x00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
uint constant next_mask  = 0xffffffff00000000ffffffffffffffffffffffffffffffffffffffffffffffff;
uint constant wants_mask = 0xffffffffffffffff000000000000000000000000ffffffffffffffffffffffff;
uint constant gives_mask = 0xffffffffffffffffffffffffffffffffffffffff000000000000000000000000;

library Library {
  function to_struct(OfferPacked __packed) internal pure returns (OfferUnpacked memory __s) { unchecked {
    __s.prev = (OfferPacked.unwrap(__packed) << prev_before) >> (256-prev_bits);
    __s.next = (OfferPacked.unwrap(__packed) << next_before) >> (256-next_bits);
    __s.wants = (OfferPacked.unwrap(__packed) << wants_before) >> (256-wants_bits);
    __s.gives = (OfferPacked.unwrap(__packed) << gives_before) >> (256-gives_bits);
  }}

  function eq(OfferPacked __packed1, OfferPacked __packed2) internal pure returns (bool) { unchecked {
    return OfferPacked.unwrap(__packed1) == OfferPacked.unwrap(__packed2);
  }}

  function unpack(OfferPacked __packed) internal pure returns (uint __prev, uint __next, uint __wants, uint __gives) { unchecked {
    __prev = (OfferPacked.unwrap(__packed) << prev_before) >> (256-prev_bits);
    __next = (OfferPacked.unwrap(__packed) << next_before) >> (256-next_bits);
    __wants = (OfferPacked.unwrap(__packed) << wants_before) >> (256-wants_bits);
    __gives = (OfferPacked.unwrap(__packed) << gives_before) >> (256-gives_bits);
  }}

  function prev(OfferPacked __packed) internal pure returns(uint) { unchecked {
    return (OfferPacked.unwrap(__packed) << prev_before) >> (256-prev_bits);
  }}
  function prev(OfferPacked __packed,uint val) internal pure returns(OfferPacked) { unchecked {
    return OfferPacked.wrap((OfferPacked.unwrap(__packed) & prev_mask)
                                | ((val << (256-prev_bits) >> prev_before)));
  }}
  function next(OfferPacked __packed) internal pure returns(uint) { unchecked {
    return (OfferPacked.unwrap(__packed) << next_before) >> (256-next_bits);
  }}
  function next(OfferPacked __packed,uint val) internal pure returns(OfferPacked) { unchecked {
    return OfferPacked.wrap((OfferPacked.unwrap(__packed) & next_mask)
                                | ((val << (256-next_bits) >> next_before)));
  }}
  function wants(OfferPacked __packed) internal pure returns(uint) { unchecked {
    return (OfferPacked.unwrap(__packed) << wants_before) >> (256-wants_bits);
  }}
  function wants(OfferPacked __packed,uint val) internal pure returns(OfferPacked) { unchecked {
    return OfferPacked.wrap((OfferPacked.unwrap(__packed) & wants_mask)
                                | ((val << (256-wants_bits) >> wants_before)));
  }}
  function gives(OfferPacked __packed) internal pure returns(uint) { unchecked {
    return (OfferPacked.unwrap(__packed) << gives_before) >> (256-gives_bits);
  }}
  function gives(OfferPacked __packed,uint val) internal pure returns(OfferPacked) { unchecked {
    return OfferPacked.wrap((OfferPacked.unwrap(__packed) & gives_mask)
                                | ((val << (256-gives_bits) >> gives_before)));
  }}
}

function t_of_struct(OfferUnpacked memory __s) pure returns (OfferPacked) { unchecked {
  return pack(__s.prev, __s.next, __s.wants, __s.gives);
}}

function pack(uint __prev, uint __next, uint __wants, uint __gives) pure returns (OfferPacked) { unchecked {
  return OfferPacked.wrap(((((0
                              | ((__prev << (256-prev_bits)) >> prev_before))
                              | ((__next << (256-next_bits)) >> next_before))
                              | ((__wants << (256-wants_bits)) >> wants_before))
                              | ((__gives << (256-gives_bits)) >> gives_before)));
}}

pragma solidity ^0.8.13;

// SPDX-License-Identifier: Unlicense

// This is free and unencumbered software released into the public domain.

// Anyone is free to copy, modify, publish, use, compile, sell, or distribute this software, either in source code form or as a compiled binary, for any purpose, commercial or non-commercial, and by any means.

// In jurisdictions that recognize copyright laws, the author or authors of this software dedicate any and all copyright interest in the software to the public domain. We make this dedication for the benefit of the public at large and to the detriment of our heirs and successors. We intend this dedication to be an overt act of relinquishment in perpetuity of all present and future rights to this software under copyright law.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// For more information, please refer to <https://unlicense.org/>

// fields are of the form [name,bits,type]

// struct_defs are of the form [name,obj]

/* ************************************************** *
            GENERATED FILE. DO NOT EDIT.
 * ************************************************** */

/* since you can't convert bool to uint in an expression without conditionals,
 * we add a file-level function and rely on compiler optimization
 */
function uint_of_bool(bool b) pure returns (uint u) {
  assembly { u := b }
}

struct OfferDetailUnpacked {
  address maker;
  uint gasreq;
  uint offer_gasbase;
  uint gasprice;
}

//some type safety for each struct
type OfferDetailPacked is uint;
using Library for OfferDetailPacked global;

uint constant maker_bits         = 160;
uint constant gasreq_bits        = 24;
uint constant offer_gasbase_bits = 24;
uint constant gasprice_bits      = 16;

uint constant maker_before         = 0;
uint constant gasreq_before        = maker_before         + maker_bits        ;
uint constant offer_gasbase_before = gasreq_before        + gasreq_bits       ;
uint constant gasprice_before      = offer_gasbase_before + offer_gasbase_bits;

uint constant maker_mask         = 0x0000000000000000000000000000000000000000ffffffffffffffffffffffff;
uint constant gasreq_mask        = 0xffffffffffffffffffffffffffffffffffffffff000000ffffffffffffffffff;
uint constant offer_gasbase_mask = 0xffffffffffffffffffffffffffffffffffffffffffffff000000ffffffffffff;
uint constant gasprice_mask      = 0xffffffffffffffffffffffffffffffffffffffffffffffffffff0000ffffffff;

library Library {
  function to_struct(OfferDetailPacked __packed) internal pure returns (OfferDetailUnpacked memory __s) { unchecked {
    __s.maker = address(uint160((OfferDetailPacked.unwrap(__packed) << maker_before) >> (256-maker_bits)));
    __s.gasreq = (OfferDetailPacked.unwrap(__packed) << gasreq_before) >> (256-gasreq_bits);
    __s.offer_gasbase = (OfferDetailPacked.unwrap(__packed) << offer_gasbase_before) >> (256-offer_gasbase_bits);
    __s.gasprice = (OfferDetailPacked.unwrap(__packed) << gasprice_before) >> (256-gasprice_bits);
  }}

  function eq(OfferDetailPacked __packed1, OfferDetailPacked __packed2) internal pure returns (bool) { unchecked {
    return OfferDetailPacked.unwrap(__packed1) == OfferDetailPacked.unwrap(__packed2);
  }}

  function unpack(OfferDetailPacked __packed) internal pure returns (address __maker, uint __gasreq, uint __offer_gasbase, uint __gasprice) { unchecked {
    __maker = address(uint160((OfferDetailPacked.unwrap(__packed) << maker_before) >> (256-maker_bits)));
    __gasreq = (OfferDetailPacked.unwrap(__packed) << gasreq_before) >> (256-gasreq_bits);
    __offer_gasbase = (OfferDetailPacked.unwrap(__packed) << offer_gasbase_before) >> (256-offer_gasbase_bits);
    __gasprice = (OfferDetailPacked.unwrap(__packed) << gasprice_before) >> (256-gasprice_bits);
  }}

  function maker(OfferDetailPacked __packed) internal pure returns(address) { unchecked {
    return address(uint160((OfferDetailPacked.unwrap(__packed) << maker_before) >> (256-maker_bits)));
  }}
  function maker(OfferDetailPacked __packed,address val) internal pure returns(OfferDetailPacked) { unchecked {
    return OfferDetailPacked.wrap((OfferDetailPacked.unwrap(__packed) & maker_mask)
                                | ((uint(uint160(val)) << (256-maker_bits) >> maker_before)));
  }}
  function gasreq(OfferDetailPacked __packed) internal pure returns(uint) { unchecked {
    return (OfferDetailPacked.unwrap(__packed) << gasreq_before) >> (256-gasreq_bits);
  }}
  function gasreq(OfferDetailPacked __packed,uint val) internal pure returns(OfferDetailPacked) { unchecked {
    return OfferDetailPacked.wrap((OfferDetailPacked.unwrap(__packed) & gasreq_mask)
                                | ((val << (256-gasreq_bits) >> gasreq_before)));
  }}
  function offer_gasbase(OfferDetailPacked __packed) internal pure returns(uint) { unchecked {
    return (OfferDetailPacked.unwrap(__packed) << offer_gasbase_before) >> (256-offer_gasbase_bits);
  }}
  function offer_gasbase(OfferDetailPacked __packed,uint val) internal pure returns(OfferDetailPacked) { unchecked {
    return OfferDetailPacked.wrap((OfferDetailPacked.unwrap(__packed) & offer_gasbase_mask)
                                | ((val << (256-offer_gasbase_bits) >> offer_gasbase_before)));
  }}
  function gasprice(OfferDetailPacked __packed) internal pure returns(uint) { unchecked {
    return (OfferDetailPacked.unwrap(__packed) << gasprice_before) >> (256-gasprice_bits);
  }}
  function gasprice(OfferDetailPacked __packed,uint val) internal pure returns(OfferDetailPacked) { unchecked {
    return OfferDetailPacked.wrap((OfferDetailPacked.unwrap(__packed) & gasprice_mask)
                                | ((val << (256-gasprice_bits) >> gasprice_before)));
  }}
}

function t_of_struct(OfferDetailUnpacked memory __s) pure returns (OfferDetailPacked) { unchecked {
  return pack(__s.maker, __s.gasreq, __s.offer_gasbase, __s.gasprice);
}}

function pack(address __maker, uint __gasreq, uint __offer_gasbase, uint __gasprice) pure returns (OfferDetailPacked) { unchecked {
  return OfferDetailPacked.wrap(((((0
                              | ((uint(uint160(__maker)) << (256-maker_bits)) >> maker_before))
                              | ((__gasreq << (256-gasreq_bits)) >> gasreq_before))
                              | ((__offer_gasbase << (256-offer_gasbase_bits)) >> offer_gasbase_before))
                              | ((__gasprice << (256-gasprice_bits)) >> gasprice_before)));
}}

pragma solidity ^0.8.13;

// SPDX-License-Identifier: Unlicense

// This is free and unencumbered software released into the public domain.

// Anyone is free to copy, modify, publish, use, compile, sell, or distribute this software, either in source code form or as a compiled binary, for any purpose, commercial or non-commercial, and by any means.

// In jurisdictions that recognize copyright laws, the author or authors of this software dedicate any and all copyright interest in the software to the public domain. We make this dedication for the benefit of the public at large and to the detriment of our heirs and successors. We intend this dedication to be an overt act of relinquishment in perpetuity of all present and future rights to this software under copyright law.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// For more information, please refer to <https://unlicense.org/>

// fields are of the form [name,bits,type]

// struct_defs are of the form [name,obj]

/* ************************************************** *
            GENERATED FILE. DO NOT EDIT.
 * ************************************************** */

/* since you can't convert bool to uint in an expression without conditionals,
 * we add a file-level function and rely on compiler optimization
 */
function uint_of_bool(bool b) pure returns (uint u) {
  assembly { u := b }
}

struct GlobalUnpacked {
  address monitor;
  bool useOracle;
  bool notify;
  uint gasprice;
  uint gasmax;
  bool dead;
}

//some type safety for each struct
type GlobalPacked is uint;
using Library for GlobalPacked global;

uint constant monitor_bits   = 160;
uint constant useOracle_bits = 8;
uint constant notify_bits    = 8;
uint constant gasprice_bits  = 16;
uint constant gasmax_bits    = 24;
uint constant dead_bits      = 8;

uint constant monitor_before   = 0;
uint constant useOracle_before = monitor_before   + monitor_bits  ;
uint constant notify_before    = useOracle_before + useOracle_bits;
uint constant gasprice_before  = notify_before    + notify_bits   ;
uint constant gasmax_before    = gasprice_before  + gasprice_bits ;
uint constant dead_before      = gasmax_before    + gasmax_bits   ;

uint constant monitor_mask   = 0x0000000000000000000000000000000000000000ffffffffffffffffffffffff;
uint constant useOracle_mask = 0xffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffff;
uint constant notify_mask    = 0xffffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffff;
uint constant gasprice_mask  = 0xffffffffffffffffffffffffffffffffffffffffffff0000ffffffffffffffff;
uint constant gasmax_mask    = 0xffffffffffffffffffffffffffffffffffffffffffffffff000000ffffffffff;
uint constant dead_mask      = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffff00ffffffff;

library Library {
  function to_struct(GlobalPacked __packed) internal pure returns (GlobalUnpacked memory __s) { unchecked {
    __s.monitor = address(uint160((GlobalPacked.unwrap(__packed) << monitor_before) >> (256-monitor_bits)));
    __s.useOracle = (((GlobalPacked.unwrap(__packed) << useOracle_before) >> (256-useOracle_bits)) > 0);
    __s.notify = (((GlobalPacked.unwrap(__packed) << notify_before) >> (256-notify_bits)) > 0);
    __s.gasprice = (GlobalPacked.unwrap(__packed) << gasprice_before) >> (256-gasprice_bits);
    __s.gasmax = (GlobalPacked.unwrap(__packed) << gasmax_before) >> (256-gasmax_bits);
    __s.dead = (((GlobalPacked.unwrap(__packed) << dead_before) >> (256-dead_bits)) > 0);
  }}

  function eq(GlobalPacked __packed1, GlobalPacked __packed2) internal pure returns (bool) { unchecked {
    return GlobalPacked.unwrap(__packed1) == GlobalPacked.unwrap(__packed2);
  }}

  function unpack(GlobalPacked __packed) internal pure returns (address __monitor, bool __useOracle, bool __notify, uint __gasprice, uint __gasmax, bool __dead) { unchecked {
    __monitor = address(uint160((GlobalPacked.unwrap(__packed) << monitor_before) >> (256-monitor_bits)));
    __useOracle = (((GlobalPacked.unwrap(__packed) << useOracle_before) >> (256-useOracle_bits)) > 0);
    __notify = (((GlobalPacked.unwrap(__packed) << notify_before) >> (256-notify_bits)) > 0);
    __gasprice = (GlobalPacked.unwrap(__packed) << gasprice_before) >> (256-gasprice_bits);
    __gasmax = (GlobalPacked.unwrap(__packed) << gasmax_before) >> (256-gasmax_bits);
    __dead = (((GlobalPacked.unwrap(__packed) << dead_before) >> (256-dead_bits)) > 0);
  }}

  function monitor(GlobalPacked __packed) internal pure returns(address) { unchecked {
    return address(uint160((GlobalPacked.unwrap(__packed) << monitor_before) >> (256-monitor_bits)));
  }}
  function monitor(GlobalPacked __packed,address val) internal pure returns(GlobalPacked) { unchecked {
    return GlobalPacked.wrap((GlobalPacked.unwrap(__packed) & monitor_mask)
                                | ((uint(uint160(val)) << (256-monitor_bits) >> monitor_before)));
  }}
  function useOracle(GlobalPacked __packed) internal pure returns(bool) { unchecked {
    return (((GlobalPacked.unwrap(__packed) << useOracle_before) >> (256-useOracle_bits)) > 0);
  }}
  function useOracle(GlobalPacked __packed,bool val) internal pure returns(GlobalPacked) { unchecked {
    return GlobalPacked.wrap((GlobalPacked.unwrap(__packed) & useOracle_mask)
                                | ((uint_of_bool(val) << (256-useOracle_bits) >> useOracle_before)));
  }}
  function notify(GlobalPacked __packed) internal pure returns(bool) { unchecked {
    return (((GlobalPacked.unwrap(__packed) << notify_before) >> (256-notify_bits)) > 0);
  }}
  function notify(GlobalPacked __packed,bool val) internal pure returns(GlobalPacked) { unchecked {
    return GlobalPacked.wrap((GlobalPacked.unwrap(__packed) & notify_mask)
                                | ((uint_of_bool(val) << (256-notify_bits) >> notify_before)));
  }}
  function gasprice(GlobalPacked __packed) internal pure returns(uint) { unchecked {
    return (GlobalPacked.unwrap(__packed) << gasprice_before) >> (256-gasprice_bits);
  }}
  function gasprice(GlobalPacked __packed,uint val) internal pure returns(GlobalPacked) { unchecked {
    return GlobalPacked.wrap((GlobalPacked.unwrap(__packed) & gasprice_mask)
                                | ((val << (256-gasprice_bits) >> gasprice_before)));
  }}
  function gasmax(GlobalPacked __packed) internal pure returns(uint) { unchecked {
    return (GlobalPacked.unwrap(__packed) << gasmax_before) >> (256-gasmax_bits);
  }}
  function gasmax(GlobalPacked __packed,uint val) internal pure returns(GlobalPacked) { unchecked {
    return GlobalPacked.wrap((GlobalPacked.unwrap(__packed) & gasmax_mask)
                                | ((val << (256-gasmax_bits) >> gasmax_before)));
  }}
  function dead(GlobalPacked __packed) internal pure returns(bool) { unchecked {
    return (((GlobalPacked.unwrap(__packed) << dead_before) >> (256-dead_bits)) > 0);
  }}
  function dead(GlobalPacked __packed,bool val) internal pure returns(GlobalPacked) { unchecked {
    return GlobalPacked.wrap((GlobalPacked.unwrap(__packed) & dead_mask)
                                | ((uint_of_bool(val) << (256-dead_bits) >> dead_before)));
  }}
}

function t_of_struct(GlobalUnpacked memory __s) pure returns (GlobalPacked) { unchecked {
  return pack(__s.monitor, __s.useOracle, __s.notify, __s.gasprice, __s.gasmax, __s.dead);
}}

function pack(address __monitor, bool __useOracle, bool __notify, uint __gasprice, uint __gasmax, bool __dead) pure returns (GlobalPacked) { unchecked {
  return GlobalPacked.wrap(((((((0
                              | ((uint(uint160(__monitor)) << (256-monitor_bits)) >> monitor_before))
                              | ((uint_of_bool(__useOracle) << (256-useOracle_bits)) >> useOracle_before))
                              | ((uint_of_bool(__notify) << (256-notify_bits)) >> notify_before))
                              | ((__gasprice << (256-gasprice_bits)) >> gasprice_before))
                              | ((__gasmax << (256-gasmax_bits)) >> gasmax_before))
                              | ((uint_of_bool(__dead) << (256-dead_bits)) >> dead_before)));
}}

pragma solidity ^0.8.13;

// SPDX-License-Identifier: Unlicense

// This is free and unencumbered software released into the public domain.

// Anyone is free to copy, modify, publish, use, compile, sell, or distribute this software, either in source code form or as a compiled binary, for any purpose, commercial or non-commercial, and by any means.

// In jurisdictions that recognize copyright laws, the author or authors of this software dedicate any and all copyright interest in the software to the public domain. We make this dedication for the benefit of the public at large and to the detriment of our heirs and successors. We intend this dedication to be an overt act of relinquishment in perpetuity of all present and future rights to this software under copyright law.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// For more information, please refer to <https://unlicense.org/>

// fields are of the form [name,bits,type]

// struct_defs are of the form [name,obj]

/* ************************************************** *
            GENERATED FILE. DO NOT EDIT.
 * ************************************************** */

/* since you can't convert bool to uint in an expression without conditionals,
 * we add a file-level function and rely on compiler optimization
 */
function uint_of_bool(bool b) pure returns (uint u) {
  assembly { u := b }
}

struct LocalUnpacked {
  bool active;
  uint fee;
  uint density;
  uint offer_gasbase;
  bool lock;
  uint best;
  uint last;
}

//some type safety for each struct
type LocalPacked is uint;
using Library for LocalPacked global;

uint constant active_bits        = 8;
uint constant fee_bits           = 16;
uint constant density_bits       = 112;
uint constant offer_gasbase_bits = 24;
uint constant lock_bits          = 8;
uint constant best_bits          = 32;
uint constant last_bits          = 32;

uint constant active_before        = 0;
uint constant fee_before           = active_before        + active_bits       ;
uint constant density_before       = fee_before           + fee_bits          ;
uint constant offer_gasbase_before = density_before       + density_bits      ;
uint constant lock_before          = offer_gasbase_before + offer_gasbase_bits;
uint constant best_before          = lock_before          + lock_bits         ;
uint constant last_before          = best_before          + best_bits         ;

uint constant active_mask        = 0x00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
uint constant fee_mask           = 0xff0000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
uint constant density_mask       = 0xffffff0000000000000000000000000000ffffffffffffffffffffffffffffff;
uint constant offer_gasbase_mask = 0xffffffffffffffffffffffffffffffffff000000ffffffffffffffffffffffff;
uint constant lock_mask          = 0xffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffff;
uint constant best_mask          = 0xffffffffffffffffffffffffffffffffffffffffff00000000ffffffffffffff;
uint constant last_mask          = 0xffffffffffffffffffffffffffffffffffffffffffffffffff00000000ffffff;

library Library {
  function to_struct(LocalPacked __packed) internal pure returns (LocalUnpacked memory __s) { unchecked {
    __s.active = (((LocalPacked.unwrap(__packed) << active_before) >> (256-active_bits)) > 0);
    __s.fee = (LocalPacked.unwrap(__packed) << fee_before) >> (256-fee_bits);
    __s.density = (LocalPacked.unwrap(__packed) << density_before) >> (256-density_bits);
    __s.offer_gasbase = (LocalPacked.unwrap(__packed) << offer_gasbase_before) >> (256-offer_gasbase_bits);
    __s.lock = (((LocalPacked.unwrap(__packed) << lock_before) >> (256-lock_bits)) > 0);
    __s.best = (LocalPacked.unwrap(__packed) << best_before) >> (256-best_bits);
    __s.last = (LocalPacked.unwrap(__packed) << last_before) >> (256-last_bits);
  }}

  function eq(LocalPacked __packed1, LocalPacked __packed2) internal pure returns (bool) { unchecked {
    return LocalPacked.unwrap(__packed1) == LocalPacked.unwrap(__packed2);
  }}

  function unpack(LocalPacked __packed) internal pure returns (bool __active, uint __fee, uint __density, uint __offer_gasbase, bool __lock, uint __best, uint __last) { unchecked {
    __active = (((LocalPacked.unwrap(__packed) << active_before) >> (256-active_bits)) > 0);
    __fee = (LocalPacked.unwrap(__packed) << fee_before) >> (256-fee_bits);
    __density = (LocalPacked.unwrap(__packed) << density_before) >> (256-density_bits);
    __offer_gasbase = (LocalPacked.unwrap(__packed) << offer_gasbase_before) >> (256-offer_gasbase_bits);
    __lock = (((LocalPacked.unwrap(__packed) << lock_before) >> (256-lock_bits)) > 0);
    __best = (LocalPacked.unwrap(__packed) << best_before) >> (256-best_bits);
    __last = (LocalPacked.unwrap(__packed) << last_before) >> (256-last_bits);
  }}

  function active(LocalPacked __packed) internal pure returns(bool) { unchecked {
    return (((LocalPacked.unwrap(__packed) << active_before) >> (256-active_bits)) > 0);
  }}
  function active(LocalPacked __packed,bool val) internal pure returns(LocalPacked) { unchecked {
    return LocalPacked.wrap((LocalPacked.unwrap(__packed) & active_mask)
                                | ((uint_of_bool(val) << (256-active_bits) >> active_before)));
  }}
  function fee(LocalPacked __packed) internal pure returns(uint) { unchecked {
    return (LocalPacked.unwrap(__packed) << fee_before) >> (256-fee_bits);
  }}
  function fee(LocalPacked __packed,uint val) internal pure returns(LocalPacked) { unchecked {
    return LocalPacked.wrap((LocalPacked.unwrap(__packed) & fee_mask)
                                | ((val << (256-fee_bits) >> fee_before)));
  }}
  function density(LocalPacked __packed) internal pure returns(uint) { unchecked {
    return (LocalPacked.unwrap(__packed) << density_before) >> (256-density_bits);
  }}
  function density(LocalPacked __packed,uint val) internal pure returns(LocalPacked) { unchecked {
    return LocalPacked.wrap((LocalPacked.unwrap(__packed) & density_mask)
                                | ((val << (256-density_bits) >> density_before)));
  }}
  function offer_gasbase(LocalPacked __packed) internal pure returns(uint) { unchecked {
    return (LocalPacked.unwrap(__packed) << offer_gasbase_before) >> (256-offer_gasbase_bits);
  }}
  function offer_gasbase(LocalPacked __packed,uint val) internal pure returns(LocalPacked) { unchecked {
    return LocalPacked.wrap((LocalPacked.unwrap(__packed) & offer_gasbase_mask)
                                | ((val << (256-offer_gasbase_bits) >> offer_gasbase_before)));
  }}
  function lock(LocalPacked __packed) internal pure returns(bool) { unchecked {
    return (((LocalPacked.unwrap(__packed) << lock_before) >> (256-lock_bits)) > 0);
  }}
  function lock(LocalPacked __packed,bool val) internal pure returns(LocalPacked) { unchecked {
    return LocalPacked.wrap((LocalPacked.unwrap(__packed) & lock_mask)
                                | ((uint_of_bool(val) << (256-lock_bits) >> lock_before)));
  }}
  function best(LocalPacked __packed) internal pure returns(uint) { unchecked {
    return (LocalPacked.unwrap(__packed) << best_before) >> (256-best_bits);
  }}
  function best(LocalPacked __packed,uint val) internal pure returns(LocalPacked) { unchecked {
    return LocalPacked.wrap((LocalPacked.unwrap(__packed) & best_mask)
                                | ((val << (256-best_bits) >> best_before)));
  }}
  function last(LocalPacked __packed) internal pure returns(uint) { unchecked {
    return (LocalPacked.unwrap(__packed) << last_before) >> (256-last_bits);
  }}
  function last(LocalPacked __packed,uint val) internal pure returns(LocalPacked) { unchecked {
    return LocalPacked.wrap((LocalPacked.unwrap(__packed) & last_mask)
                                | ((val << (256-last_bits) >> last_before)));
  }}
}

function t_of_struct(LocalUnpacked memory __s) pure returns (LocalPacked) { unchecked {
  return pack(__s.active, __s.fee, __s.density, __s.offer_gasbase, __s.lock, __s.best, __s.last);
}}

function pack(bool __active, uint __fee, uint __density, uint __offer_gasbase, bool __lock, uint __best, uint __last) pure returns (LocalPacked) { unchecked {
  return LocalPacked.wrap((((((((0
                              | ((uint_of_bool(__active) << (256-active_bits)) >> active_before))
                              | ((__fee << (256-fee_bits)) >> fee_before))
                              | ((__density << (256-density_bits)) >> density_before))
                              | ((__offer_gasbase << (256-offer_gasbase_bits)) >> offer_gasbase_before))
                              | ((uint_of_bool(__lock) << (256-lock_bits)) >> lock_before))
                              | ((__best << (256-best_bits)) >> best_before))
                              | ((__last << (256-last_bits)) >> last_before)));
}}