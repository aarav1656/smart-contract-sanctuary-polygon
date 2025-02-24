// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Context } from "@openzeppelin/contracts/utils/Context.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { Metapool } from "./structs/Metapool.sol";
import { EPosition } from "./EPosition.sol";
import { PariPoolContract } from "./PariPoolContract.sol";

import { IRewardCollector } from "../../interfaces/IRewardCollector.sol";
import { IRewardCalculator } from "../../interfaces/IRewardCalculator.sol";

// import { console } from "hardhat/console.sol";

contract PariMarket is Context, ReentrancyGuard, PariPoolContract {

  using SafeERC20 for IERC20;
  using SafeMath for uint;
  using Address for address;

  mapping(address => bool) private __FATAL_INSUFFICIENT_PRIZEFUNDS_ERROR__;

  // solhint-disable-next-line
  address immutable public STAKING_CONTRACT;
  IRewardCollector immutable internal stakersRewardCollector;

  // solhint-disable-next-line
  address immutable public MENTORING_CONTRACT;
  IRewardCollector immutable internal mentorsRewardCollector;
  IRewardCalculator immutable internal mentorsRewardCalculator;

  // solhint-disable-next-line
  address immutable public DISTRIBUTOR_EOA;

  constructor(
    address distributorEOA_,
    address stakingContract_,
    address mentoringContract_,
    address metapoolContract_
  )
    PariPoolContract(metapoolContract_)
  {
    if (!stakingContract_.isContract()) {
      revert("CannotUseEOAAsDistributorContract");
    }

    if (!mentoringContract_.isContract()) {
      revert("CannotUseEOAAsDistributorContract");
    }

    if (distributorEOA_.isContract()) {
      revert("CannotUseContractAsDistributorEOA");
    }

    STAKING_CONTRACT = stakingContract_;
    stakersRewardCollector = IRewardCollector(stakingContract_);

    MENTORING_CONTRACT = mentoringContract_;
    mentorsRewardCollector = IRewardCollector(mentoringContract_);
    mentorsRewardCalculator = IRewardCalculator(mentoringContract_);

    DISTRIBUTOR_EOA = distributorEOA_;

  }

  function resolve(
    bytes32 poolid,
    uint80 resolutionPriceid,
    uint80 controlPriceid
  )
    external
    onlyOffChainCallable
  {

    _resolve(poolid, resolutionPriceid, controlPriceid);

  }

  function placePari(
    uint amount,
    uint8 position,
    bytes32 metapoolid,
    bytes32 poolid
  )
    external
    nonReentrant
    onlyOffChainCallable
  {

    Metapool memory metapool = metapoolContract.getMetapool(metapoolid);
    if (metapoolid == 0x0 || metapoolid != metapool.metapoolid) {
      revert("NotSupportedMetapool");
    }
    if (metapool.blocked) {
      revert("CannotPlacePariMetapoolIsBlocked");
    }

    if (__FATAL_INSUFFICIENT_PRIZEFUNDS_ERROR__[metapool.erc20]) {
      revert("CannotPlacePariERC20TokenIsBlocked");
    }

    if (
      position != uint8(EPosition.Up) &&
      position != uint8(EPosition.Down) &&
      position != uint8(EPosition.Zero)
    ) {
      revert("NotSupportedPosition");
    }

    if (amount < metapool.minWager) {
      revert("UnacceptableWagerAmount");
    }

    address bettor = _msgSender();
    IERC20 wagerToken = IERC20(metapool.erc20);
    if (wagerToken.balanceOf(bettor) < amount) {
      revert("InsufficientFunds");
    }
    if (wagerToken.allowance(bettor, address(this)) < amount) {
      revert("InsufficientAllowance");
    }

    uint sincestart = SafeMath.mod(block.timestamp, metapool.schedule);
    uint startDate = SafeMath.sub(block.timestamp, sincestart);
    bytes32 actualpoolid = keccak256(abi.encode(metapool.metapoolid, startDate));
    if (actualpoolid != poolid) {
      revert("CannotPlacePariIntoUnactualPool");
    }

    if (sincestart >= metapool.positioning) {
      revert("CannotPlacePariOutOfPositioningPeriod");
    }

    _updatePool(metapool, poolid, position, amount);
    _updatePari(metapool, poolid, bettor, position, amount);

    wagerToken.safeTransferFrom(bettor, address(this), amount);

  }

  function resolve4withdraw(
    bytes32 poolid,
    bytes32 pariid,
    address erc20,
    uint80 resolutionPriceid,
    uint80 controlPriceid
  )
    external
    nonReentrant
    onlyOffChainCallable
  {

    if (!_isResolved(poolid)) {
      _resolve(poolid, resolutionPriceid, controlPriceid);
    }

    _withdraw(poolid, pariid, erc20);

  }

  function withdraw(
    bytes32 poolid,
    bytes32 pariid,
    address erc20
  )
    external
    nonReentrant
    onlyOffChainCallable
  {

    _withdraw(poolid, pariid, erc20);

  }

  function _withdraw(
    bytes32 poolid,
    bytes32 pariid,
    address erc20
  )
    private
  {

    (uint payout, uint commission) = _claimPari(poolid, pariid, erc20);

    _distributeERC20(
      erc20,
      payout,
      commission
    );

  }

  function _distributeERC20(
    address erc20,
    uint payout,
    uint commission
  )
    private
  {

    address bettor = _msgSender();

    IERC20 wagerToken = IERC20(erc20);
    uint amount = SafeMath.add(payout, commission);
    if (wagerToken.balanceOf(address(this)) < amount) {
      __FATAL_INSUFFICIENT_PRIZEFUNDS_ERROR__[erc20] = true;
      return;
    }

    if (commission != 0) {

      uint stakersReward = commission;

      try
        mentorsRewardCalculator.calculateReward(
          bettor,
          commission
        )
        returns (
          uint metorsReward
        )
      {

        if (metorsReward != 0 && metorsReward <= commission) {

          stakersReward = SafeMath.sub(commission, metorsReward);

          wagerToken.approve(MENTORING_CONTRACT, metorsReward);
          try
            mentorsRewardCollector.collectReward(
              bettor,
              erc20,
              commission
            )
          {

            emit MentorsRewardDistributedViaContract(
              MENTORING_CONTRACT,
              bettor,
              erc20,
              metorsReward
            );

          } catch {

            // NOTE: In case of unexpected exceptions or pouse
            // mentors reward will be send to known EOA reward distributor
            wagerToken.safeTransfer(DISTRIBUTOR_EOA, metorsReward);

            emit MentorsRewardDistributedViaEOA(
              DISTRIBUTOR_EOA,
              bettor,
              erc20,
              metorsReward
            );

          }

        }

      } catch { }

      if (stakersReward != 0) {

        wagerToken.approve(STAKING_CONTRACT, stakersReward);
        try
          stakersRewardCollector.collectReward(
            bettor,
            erc20,
            stakersReward
          )
        {

          emit StakersRewardDistributedViaContract(
            STAKING_CONTRACT,
            bettor,
            erc20,
            stakersReward
          );

        } catch {

          // NOTE: In case of unexpected exceptions or pouse
          // commission will be send to known EOA distributer
          wagerToken.safeTransfer(DISTRIBUTOR_EOA, stakersReward);

          emit StakersRewardDistributedViaEOA(
            DISTRIBUTOR_EOA,
            bettor,
            erc20,
            stakersReward
          );

        }

      }

    }

    if (payout != 0) {
      wagerToken.safeTransfer(bettor, payout);
    }

  }

  modifier onlyOffChainCallable() {
    address sender = _msgSender();
    if (sender.isContract()) {
      revert("OnlyEOASendersAllowed");
    }
    _;
  }

  event MentorsRewardDistributedViaContract(
    address distributor,
    address bettor,
    address erc20,
    uint amount
  );
  event MentorsRewardDistributedViaEOA(
    address distributor,
    address bettor,
    address erc20,
    uint amount
  );
  event StakersRewardDistributedViaContract(
    address distributor,
    address bettor,
    address erc20,
    uint amount
  );
  event StakersRewardDistributedViaEOA(
    address distributor,
    address bettor,
    address erc20,
    uint amount
  );
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Metapool {

  bytes32 metapoolid;
  address pricefeed;
  address erc20;
  uint16 version;
  uint schedule;
  uint positioning;
  uint minWager;
  bool blocked;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

enum EPosition {
  Undefined,
  Down,
  Up,
  Zero,
  NoContest
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import { Context } from "@openzeppelin/contracts/utils/Context.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { EPosition } from "./EPosition.sol";

import { Metapool } from "./structs/Metapool.sol";
import { Pool } from "./structs/Pool.sol";
import { Pari } from "./structs/Pari.sol";
import { Price } from "./structs/Price.sol";

import { MetapoolContract } from "./MetapoolContract.sol";

// import { console } from "hardhat/console.sol";

contract PariPoolContract is Context {

  using SafeMath for uint;
  using EnumerableSet for EnumerableSet.Bytes32Set;
  using Address for address;

  mapping(bytes32 => Pari) internal _paris;
  mapping(bytes32 => Pool) internal _pools;

  mapping(bytes32 => EnumerableSet.Bytes32Set[4]) private _claimedParis;
  mapping(bytes32 => EnumerableSet.Bytes32Set[4]) private _poolParis;

  mapping(bytes32 => uint[2**8]) private _prizefunds;

  uint8 constant public VIGORISH_PERCENT = 1;
  uint8 constant private PRIZEFUND_TOTAL_ID = 0;
  uint8 constant private PRIZEFUND_RELEASED_ID = 255;
  uint256 constant private PRICE_FEED_PHASE_OFFSET = 64;

  // solhint-disable-next-line
  address immutable public METAPOOL_CONTRACT;
  MetapoolContract immutable internal metapoolContract;

  constructor(
    address metapoolContract_
  )
  {
    METAPOOL_CONTRACT = metapoolContract_;
    metapoolContract = MetapoolContract(metapoolContract_);
  }

  function getPari(
    bytes32 pariid
  )
    external
    view
    returns (
      Pari memory
    )
  {
    return _paris[pariid];
  }

  function getPool(
    bytes32 poolid
  )
    external
    view
    returns (
      Pool memory,
      uint[4] memory
    )
  {
    return (
      _pools[poolid],
      [
        _prizefunds[poolid][PRIZEFUND_TOTAL_ID],
        _prizefunds[poolid][uint8(EPosition.Down)],
        _prizefunds[poolid][uint8(EPosition.Up)],
        _prizefunds[poolid][uint8(EPosition.Zero)]
      ]
    );
  }

  function getPoolPrizefunds(
    bytes32 poolid
  )
    external
    view
    returns (
      uint[4] memory
    )
  {

    return [
        _prizefunds[poolid][PRIZEFUND_TOTAL_ID],
        _prizefunds[poolid][uint8(EPosition.Down)],
        _prizefunds[poolid][uint8(EPosition.Up)],
        _prizefunds[poolid][uint8(EPosition.Zero)]
    ];

  }

  function isBettorInPool(
    address bettor,
    bytes32 poolid
  )
    external
    view
    returns (bool)
  {
    bytes32 pariidDown = keccak256(abi.encode(poolid, bettor, uint8(EPosition.Down)));
    if (_paris[pariidDown].pariid == pariidDown) return true;

    bytes32 pariidUp = keccak256(abi.encode(poolid, bettor, uint8(EPosition.Up)));
    if (_paris[pariidUp].pariid == pariidUp) return true;

    bytes32 pariidZero = keccak256(abi.encode(poolid, bettor, uint8(EPosition.Zero)));
    if (_paris[pariidZero].pariid == pariidZero) return true;

    return false;
  }

  function _updatePari(
    Metapool memory metapool,
    bytes32 poolid,
    address bettor,
    uint8 position,
    uint amount
  )
    internal
  {

    bytes32 pariid = keccak256(abi.encode(poolid, bettor, position));

    Pari storage pari = _paris[pariid];
    if (pari.pariid == 0x0) {
      pari.pariid = pariid;
      pari.poolid = poolid;
      pari.metapoolid = metapool.metapoolid;
      pari.bettor = bettor;
      pari.position = position;
      pari.createdAt = block.timestamp;
      pari.erc20 = metapool.erc20;

      _poolParis[poolid][position].add(pariid);

      emit PariCreated(
        pariid,
        poolid,
        bettor,
        position,
        block.timestamp,
        metapool.erc20,
        metapool.metapoolid
      );
    }

    pari.wager = SafeMath.add(pari.wager, amount);

    emit IncreasePariWager(pariid, amount);
  }

  function _updatePool(
    Metapool memory metapool,
    bytes32 poolid,
    uint8 position,
    uint amount
  )
    internal
  {

    _createPool(metapool, poolid);
    _updatePrizefund(poolid, position, amount);

    emit PoolPrizefundAdd(
      poolid,
      metapool.erc20,
      position,
      amount
    );
  }

  function _createPool(
    Metapool memory metapool,
    bytes32 poolid
  )
    private
  {

    Pool storage pool = _pools[poolid];
    if (pool.poolid == 0x0) {
      uint sincestart = SafeMath.mod(block.timestamp, metapool.schedule);
      uint startDate = SafeMath.sub(block.timestamp, sincestart);

      address pricefeed = metapool.pricefeed;

      Price memory openPrice = _getPriceLatest(pricefeed);

      if (openPrice.timestamp < startDate) {
        revert("PoolOpenPriceTimestampTooEarly");
      }

      uint lockDate = SafeMath.add(startDate, metapool.positioning);
      if (openPrice.timestamp >= lockDate) {
        revert("PoolOpenPriceTimestampTooLate");
      }

      uint endDate = SafeMath.add(startDate, metapool.schedule);
      address erc20 = metapool.erc20;
      bytes32 metapoolid = metapool.metapoolid;

      pool.poolid = poolid;
      pool.metapoolid = metapoolid;
      pool.openPrice = openPrice;
      pool.startDate = startDate;
      pool.lockDate = lockDate;
      pool.endDate = endDate;
      pool.openedAt = block.timestamp;
      pool.erc20 = erc20;
      pool.pricefeed = pricefeed;

      emit PoolCreated(
        poolid,
        metapoolid,
        _msgSender(),
        erc20,
        pricefeed,
        openPrice,
        startDate,
        lockDate,
        endDate,
        block.timestamp
      );
    }

  }

  function _isResolved(
    bytes32 poolid
  )
    internal
    view
    returns (
      bool
    )
  {

    return _pools[poolid].resolved;

  }

  function _resolve(
    bytes32 poolid,
    uint80 resolutionPriceid,
    uint80 controlPriceid
  )
    internal
  {

    Pool storage pool = _pools[poolid];
    if (pool.resolved) {
      revert("CannotResolveResolvedPool");
    }

    if (pool.openedAt == 0) {
      revert("CannotResolveUnopenedPool");
    }

    pool.resolved = true;
    pool.resolvedAt = block.timestamp;

    if (_isNoContestEmptyPool(poolid)) {
      if (block.timestamp <= pool.lockDate) {
        revert("CannotResolvePoolDuringPositioning");
      }

      pool.resolution = uint8(EPosition.NoContest);

      emit PoolResolvedNoContest(
        poolid,
        _msgSender(),
        block.timestamp,
        uint8(EPosition.NoContest)
      );

      return;
    }

    uint endDate = pool.endDate;
    if (block.timestamp <= endDate) {
      revert("CannotResolvePoolBeforeEndDate");
    }

    Metapool memory metapool = metapoolContract.getMetapool(pool.metapoolid);
    if (metapool.blocked) {

      pool.resolution = uint8(EPosition.NoContest);

      emit PoolResolvedNoContest(
        poolid,
        _msgSender(),
        block.timestamp,
        uint8(EPosition.NoContest)
      );

      return;
    }

    if (
      resolutionPriceid == 0 ||
      controlPriceid == 0 ||
      resolutionPriceid == controlPriceid
    ) {
      revert("CannotResolvePoolWithoutPricePair");
    }

    Price memory resolutionPrice = _getPrice(pool.pricefeed, resolutionPriceid);
    Price memory controlPrice = _getPrice(pool.pricefeed, controlPriceid);

    if (!_isValidResolution(
      pool,
      resolutionPrice,
      controlPrice
    )) {
      revert("InvalidPoolResolution");
    }

    uint8 resolution = _calculatePoolResolution(poolid, pool.openPrice, resolutionPrice);

    pool.resolutionPrice = resolutionPrice;
    pool.resolution = resolution;

    emit PoolResolved(
      poolid,
      resolutionPrice,
      _msgSender(),
      block.timestamp,
      resolution
    );

  }

  function _isNoContestEmptyPool(bytes32 poolid)
    private
    view
    returns (bool)
  {
    uint prizefundUp = _prizefunds[poolid][uint8(EPosition.Up)];
    uint prizefundDown = _prizefunds[poolid][uint8(EPosition.Down)];
    uint prizefundEqual = _prizefunds[poolid][uint8(EPosition.Zero)];
    uint prizefundTotal = _prizefunds[poolid][PRIZEFUND_TOTAL_ID];

    return (
      prizefundUp == prizefundTotal ||
      prizefundDown == prizefundTotal ||
      prizefundEqual == prizefundTotal
    );
  }

  function _getPrice(
    address pricefeed,
    uint80 _roundid
  )
    private
    view
    returns (
      Price memory
    )
  {

    AggregatorV3Interface _pricefeed = AggregatorV3Interface(pricefeed);

    try
      _pricefeed.getRoundData(_roundid)
      returns (
        uint80 roundid,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
      )
    {

      return Price({
        roundid: roundid,
        value: answer,
        timestamp: updatedAt
      });

    } catch {

      return Price({
        roundid: 0,
        value: 0,
        timestamp: 0
      });

    }

  }

  function _getPriceLatest(
    address pricefeed
  )
    private
    view
    returns (
      Price memory
    )
  {

    AggregatorV3Interface _pricefeed = AggregatorV3Interface(pricefeed);

    (
      uint80 roundid,
      int256 answer,
      /*uint256 startedAt*/,
      uint256 updatedAt,
      /*uint80 answeredInRound*/
    ) = _pricefeed.latestRoundData();

    return Price({
      roundid: roundid,
      value: answer,
      timestamp: updatedAt
    });

  }

  function _isValidResolution(
    Pool memory pool,
    Price memory resolutionPrice,
    Price memory controlPrice
  )
    private
    view
    returns (bool)
  {

    // not confirmed round
    if (resolutionPrice.timestamp == 0) return false;
    if (controlPrice.timestamp == 0) return false;

    // resolution price goes before control price by roundid
    if (resolutionPrice.roundid >= controlPrice.roundid) return false;

    if (resolutionPrice.timestamp < pool.lockDate) return false;
    if (resolutionPrice.timestamp >= pool.endDate) return false;
    if (resolutionPrice.timestamp <= pool.openPrice.timestamp) return false;
    if (controlPrice.timestamp < pool.endDate) return false;

    (uint16 rpPhaseId, uint64 rpAggrRoundId) = _parseRoundid(resolutionPrice.roundid);
    (uint16 cpPhaseId, uint64 cpAggrRoundId) = _parseRoundid(controlPrice.roundid);

    // resolve only with latest avalable phase
    uint16 nextPhaseid = cpPhaseId + 1;
    uint80 nextPhaseRoundid = computeRoundid(nextPhaseid, 1);
    Price memory nextPhasePrice = _getPrice(pool.pricefeed, nextPhaseRoundid);
    if (
      nextPhasePrice.timestamp != 0 &&
      nextPhasePrice.timestamp <= controlPrice.timestamp
    ) return false;

    if (
      // same phase
      rpPhaseId == cpPhaseId &&
      // continuous rounds
      (rpAggrRoundId + 1) == cpAggrRoundId
    ) return true;

    if (
      // continuous phases
      (rpPhaseId + 1) == cpPhaseId &&
      // first rounds
      cpAggrRoundId == 1
    ) {
      uint80 nextRoundid = resolutionPrice.roundid + 1;
      Price memory nextRoundPrice = _getPrice(pool.pricefeed, nextRoundid);

      if (
        nextRoundPrice.timestamp == 0 ||
        nextRoundPrice.timestamp >= controlPrice.timestamp
      ) return true;

    }

    return false;

  }

  function _parseRoundid(
    uint80 roundId
  )
    private
    pure
    returns (uint16, uint64)
  {
    uint16 phaseId = uint16(roundId >> PRICE_FEED_PHASE_OFFSET);
    uint64 aggregatorRoundId = uint64(roundId);

    return (phaseId, aggregatorRoundId);
  }

  function computeRoundid(
    uint16 phaseId,
    uint64 aggregatorRoundId
  )
    internal
    pure
    returns (uint80)
  {
    uint80 roundId = uint80((uint256(phaseId) << 64) | aggregatorRoundId);
    return roundId;
  }

  function _calculatePoolResolution(
    bytes32 poolid,
    Price memory openPrice,
    Price memory resolutionPrice
  )
    private
    view
    returns (uint8)
  {

    uint8 outcome = uint8(EPosition.Undefined);

    if (resolutionPrice.value > openPrice.value) {

      outcome = uint8(EPosition.Up);

    } else if (resolutionPrice.value < openPrice.value) {

      outcome = uint8(EPosition.Down);

    } else if (resolutionPrice.value == openPrice.value) {

      outcome = uint8(EPosition.Zero);

    }

    if (outcome == uint8(EPosition.Undefined)) {

      outcome = uint8(EPosition.NoContest);

    } else if (_isNoContestPool(poolid, outcome)) {

      outcome = uint8(EPosition.NoContest);

    }

    return outcome;

  }

  function _isNoContestPool(bytes32 poolid, uint8 winnning)
    private
    view
    returns (bool)
  {
    uint prizefundWin = _prizefunds[poolid][winnning];
    uint prizefundTotal = _prizefunds[poolid][PRIZEFUND_TOTAL_ID];

    return prizefundWin == 0 || prizefundWin == prizefundTotal;
  }

  function _updatePrizefund(
    bytes32 poolid,
    uint8 position,
    uint amount
  )
    private
  {

    _prizefunds[poolid][position] = SafeMath.add(_prizefunds[poolid][position], amount);
    _prizefunds[poolid][PRIZEFUND_TOTAL_ID] = SafeMath.add(_prizefunds[poolid][PRIZEFUND_TOTAL_ID], amount);

  }

  function _calculatePayout(
    Pari memory pari,
    Pool memory pool
  )
    private
    view
    returns (
      uint,
      uint
    )
  {

    uint payout = 0;
    uint commission = 0;

    if (pari.claimed || !pool.resolved) return ( payout, commission );

    bool nocontest = pool.resolution == uint8(EPosition.NoContest);
    if (nocontest) return ( pari.wager, commission );

    bool win = pool.resolution == pari.position;
    if (win) {

      (uint paripayout, uint paricommission) = _calculatePrize(
        pari.wager,
        _prizefunds[pari.poolid][pari.position],
        _prizefunds[pari.poolid][PRIZEFUND_TOTAL_ID]
      );

      payout = paripayout;
      commission = paricommission;

      // Handle potential rounding error
      uint remainingParis = SafeMath.sub(
        _poolParis[pari.poolid][pari.position].length(),
        _claimedParis[pari.poolid][pari.position].length()
      );

      if (remainingParis == 1) {

        uint remainingPrizefund = SafeMath.sub(
          _prizefunds[pari.poolid][PRIZEFUND_TOTAL_ID],
          _prizefunds[pari.poolid][PRIZEFUND_RELEASED_ID]
        );

        if (remainingPrizefund > SafeMath.add(payout, commission)) {
          commission = SafeMath.sub(remainingPrizefund, payout);
        }

      }

    }

    return ( payout, commission );

  }

  function _calculatePrize(
    uint wager,
    uint positionfunds,
    uint totalfunds
  )
    private
    pure
    returns (
      uint,
      uint
    )
  {

    uint payout = SafeMath.div(
      SafeMath.mul(
        totalfunds,
        wager
      ),
      positionfunds
    );

    uint com = SafeMath.mul(payout, VIGORISH_PERCENT);
    uint commission = SafeMath.div(com, 100);
    uint rest = SafeMath.mod(com, 100);
    if (rest != 0) commission = SafeMath.add(commission, 1); // ceil

    payout = SafeMath.sub(payout, commission);

    return ( payout, commission );

  }

  function _claimPari(
    bytes32 poolid,
    bytes32 pariid,
    address erc20
  )
    internal
    returns (
      uint,
      uint
  ) {

    if (erc20 == address(0)) {
      revert("ERC20AddressZero");
    }

    Pari memory pari = _paris[pariid];
    if (pari.poolid != poolid) {
      revert("PariPoolMismatch");
    }

    Pool memory pool = _pools[poolid];
    if (pool.erc20 != erc20) {
      revert("ERC20PariPoolMismatch");
    }

    if (!_poolParis[pool.poolid][pari.position].contains(pariid)) {
      revert("CannotClaimNonPoolPari");
    }

    address bettor = _msgSender();
    if (pari.bettor != bettor) {
      revert("BettorPariMismatch");
    }

    if (pari.claimed) {
      revert("CannotClaimClaimedPari");
    }

    if (_claimedParis[pool.poolid][pari.position].contains(pari.pariid)) {
      revert("CannotClaimClaimedPari");
    }

    if (!pool.resolved) {
      revert("CannotClaimPariUnresolvedPool");
    }

    if (
      pool.resolution != uint8(EPosition.NoContest) &&
      pool.resolution != pari.position
    ) {
      revert("CannotClaimLostPari");
    }

    (uint payout, uint commission) = _calculatePayout(pari, pool);

    _updateClaimPari(pariid, payout, commission);
    _releasePrizefund(poolid, payout, commission);

    return ( payout, commission );

  }

  function _updateClaimPari(
    bytes32 pariid,
    uint payout,
    uint commission
  )
    private
  {

    Pari storage pari = _paris[pariid];

    if (payout != 0) pari.payout = payout;
    if (commission != 0) pari.commission = commission;
    pari.claimed = true;

    _claimedParis[pari.poolid][pari.position].add(pariid);

    emit PariClaimed(pariid, pari.bettor, pari.erc20, payout, commission);
  }

  function _releasePrizefund(
    bytes32 poolid,
    uint payout,
    uint commission
  )
    private
  {

    uint pariprize = SafeMath.add(payout, commission);
    if (pariprize != 0) {
      _prizefunds[poolid][PRIZEFUND_RELEASED_ID] = SafeMath.add(_prizefunds[poolid][PRIZEFUND_RELEASED_ID], pariprize);
    }

    if (_prizefunds[poolid][PRIZEFUND_RELEASED_ID] > _prizefunds[poolid][PRIZEFUND_TOTAL_ID]) {
      revert("InsufficientPrizefund");
    }

    emit PoolPrizefundReleased(
      poolid,
      payout,
      commission
    );

  }

  event PoolResolvedNoContest(
    bytes32 indexed poolid,
    address resolvedBy,
    uint resolvedAt,
    uint8 resolution
  );
  event PoolResolved(
    bytes32 indexed poolid,
    Price resolutionPrice,
    address resolvedBy,
    uint resolvedAt,
    uint8 resolution
  );
  event PoolCreated(
    bytes32 indexed poolid,
    bytes32 metapoolid,
    address openedBy,
    address erc20,
    address pricefeed,
    Price openPrice,
    uint startDate,
    uint lockDate,
    uint endDate,
    uint openedAt
  );
  event PoolPrizefundAdd(
    bytes32 poolid,
    address erc20,
    uint8 position,
    uint amount
  );
  event PoolPrizefundReleased(
    bytes32 poolid,
    uint payout,
    uint commission
  );
  event PariCreated(
    bytes32 indexed pariid,
    bytes32 poolid,
    address bettor,
    uint8 position,
    uint createdAt,
    address erc20,
    bytes32 metapoolid
  );
  event IncreasePariWager(bytes32 pariid, uint wager);
  event PariClaimed(
    bytes32 pariid,
    address bettor,
    address erc20,
    uint payout,
    uint commission
  );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRewardCollector {
  function collectReward(
    address bettor,
    address erc20,
    uint commission
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRewardCalculator {
  function calculateReward(
    address bettor,
    uint commission
  ) external returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Price } from "./Price.sol";

struct Pool {

  bytes32 poolid;
  bytes32 metapoolid;
  uint8 resolution;
  Price openPrice;
  Price resolutionPrice;
  uint startDate;
  uint lockDate;
  uint endDate;
  uint resolvedAt;
  bool resolved;
  uint openedAt;
  address erc20;
  address pricefeed;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Pari {

  bytes32 pariid;
  bytes32 poolid;
  bytes32 metapoolid;
  address bettor;
  uint8 position;
  uint wager;
  bool claimed;
  uint createdAt;
  uint payout;
  uint commission;
  address erc20;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Price {

  int value;
  uint timestamp;
  uint80 roundid;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Metapool } from "./structs/Metapool.sol";

contract MetapoolContract is Ownable {

  uint constant private SHORTEST_ROUND = 120;
  uint constant private SHORTEST_POSITIONING = 60;

  mapping(bytes32 => Metapool) private _metapools;
  mapping(bytes32 => bool) private _blockedMetapools;

  function addMetapool(

    address pricefeed,
    address erc20,
    uint16 version,
    uint schedule,
    uint positioning,
    uint minWager

  )
    external
    onlyOwner
  {

    if (schedule < SHORTEST_ROUND) {
      revert("CannotAddMetapoolScheduleTooShort");
    }

    if (positioning < SHORTEST_POSITIONING) {
      revert("CannotAddMetapoolPositioningTooShort");
    }

    if (positioning > SafeMath.div(schedule, 2)) {
      revert("CannotAddMetapoolPositioningTooLarge");
    }

    if (minWager == 0) {
      revert("CannotAddMetapoolMinWagerZero");
    }

    if (version == 0) {
      revert("CannotAddMetapoolVersionZero");
    }

    AggregatorV3Interface _priceFeed = AggregatorV3Interface(pricefeed);
    uint8 decimals = _priceFeed.decimals();
    if (decimals == 0) {
      revert("CannotAddMetapoolWithInvalidFeedAddress");
    }

    IERC20 wagerToken = IERC20(erc20);
    uint balance = wagerToken.balanceOf(_msgSender());
    if (balance == 0) {
      revert("CannotAddMetapoolERC20InsufficientFunds");
    }

    bytes32 metapoolid = keccak256(abi.encode(
      pricefeed,
      erc20,
      version,
      schedule,
      positioning
    ));

    if (_metapools[metapoolid].metapoolid != 0x0) {
      revert("CannotAddMetapoolAlreadyExists");
    }

    _metapools[metapoolid] = Metapool({
      metapoolid: metapoolid,
      pricefeed: pricefeed,
      erc20: erc20,
      version: version,
      schedule: schedule,
      positioning: positioning,
      minWager: minWager,
      blocked: false
    });

    emit MetapoolAdded(
      metapoolid,
      pricefeed,
      erc20,
      version,
      schedule,
      positioning,
      minWager
    );
  }

  function _getMetapool(
    bytes32 _metapoolid
  )
    internal
    view
    returns (
      Metapool storage
    )
  {

    return _metapools[_metapoolid];

  }

  function getMetapool(
    bytes32 metapoolid
  )
    external
    view
    returns (
      Metapool memory
    )
  {

    return _getMetapool(metapoolid);

  }

  function unblockMetapool(
    bytes32 metapoolid
  )
    external
    onlyOwner
  {

    Metapool storage metapool = _metapools[metapoolid];
    if (metapool.metapoolid == 0x0) {
      revert("CannotUnblockMetapoolDoNotExists");
    }
    if (!metapool.blocked) {
      revert("CannotUnblockMetapoolIsNotBlocked");
    }

    metapool.blocked = false;

    emit MetapoolUnblocked(metapoolid);

  }

  function blockMetapool(
    bytes32 metapoolid
  )
    external
    onlyOwner
  {

    Metapool storage metapool = _metapools[metapoolid];
    if (metapool.metapoolid == 0x0) {
      revert("CannotBlockMetapoolDoNotExists");
    }
    if (metapool.blocked) {
      revert("CannotBlockMetapoolIsAlreadyBlocked");
    }

    metapool.blocked = true;

    emit MetapoolBlocked(metapoolid);
  }

  function isMetapoolBlocked(
    bytes32 metapoolid
  )
    external
    view
    returns (bool)
  {

    Metapool storage metapool = _metapools[metapoolid];

    return metapool.blocked;

  }

  event MetapoolAdded(
    bytes32 indexed metapoolid,
    address pricefeed,
    address erc20,
    uint16 version,
    uint schedule,
    uint positioning,
    uint minWager
  );
  event MetapoolBlocked(bytes32 indexed metapoolid);
  event MetapoolUnblocked(bytes32 indexed metapoolid);
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