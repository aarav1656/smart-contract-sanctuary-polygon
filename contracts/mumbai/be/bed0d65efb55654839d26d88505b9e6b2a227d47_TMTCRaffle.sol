/**
 *Submitted for verification at polygonscan.com on 2023-02-05
*/

/**
 *Submitted for verification at polygonscan.com on 2022-05-25
*/

//SPDX-License-Identifier: MIT


// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// File: @chainlink/contracts/src/v0.8/VRFRequestIDBase.sol


pragma solidity ^0.8.0;

contract VRFRequestIDBase {

  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  )
    internal
    pure
    returns (
      uint256
    )
  {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(
    bytes32 _keyHash,
    uint256 _vRFInputSeed
  )
    internal
    pure
    returns (
      bytes32
    )
  {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}
// File: @chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol


pragma solidity ^0.8.0;

interface LinkTokenInterface {

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (
      uint256 remaining
    );

  function approve(
    address spender,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function balanceOf(
    address owner
  )
    external
    view
    returns (
      uint256 balance
    );

  function decimals()
    external
    view
    returns (
      uint8 decimalPlaces
    );

  function decreaseApproval(
    address spender,
    uint256 addedValue
  )
    external
    returns (
      bool success
    );

  function increaseApproval(
    address spender,
    uint256 subtractedValue
  ) external;

  function name()
    external
    view
    returns (
      string memory tokenName
    );

  function symbol()
    external
    view
    returns (
      string memory tokenSymbol
    );

  function totalSupply()
    external
    view
    returns (
      uint256 totalTokensIssued
    );

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

}

// File: @chainlink/contracts/src/v0.8/VRFConsumerBase.sol


pragma solidity ^0.8.0;



/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    internal
    virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 constant private USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(
    bytes32 _keyHash,
    uint256 _fee
  )
    internal
    returns (
      bytes32 requestId
    )
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface immutable internal LINK;
  address immutable private vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(
    address _vrfCoordinator,
    address _link
  ) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    external
  {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// File: contracts/Raffle.sol


pragma solidity ^0.8.7;



library SafeMath {
    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b);
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
        return c;
    }
}

interface TMTC {
    function tokenOfOwnerByIndex(address _owner, uint256 _index)
        external
        view
        returns (uint256);

    function balanceOf(address _owner) external view returns (uint256);
}


contract TMTCRaffle is VRFConsumerBase {
    using SafeMath for uint256;
    address private constant TokerAddy =
        0x8A5EDBF9743d3f0962B1e5AE2057d9F02D2b24DD;
    TMTC private TMTCAddy;
    address private raffleCollab;
    uint256[] private winningNumbers;
    uint256[] private tickets;
    address[] private addresses;
    mapping(uint256 => address) public ticketId;
    mapping(address => uint256[]) private playerTickets;
    mapping(address => uint256) public currentEntries;
    mapping(address => uint256) private maxEntries;

    bytes32 internal keyHash;
    uint256 internal fee;
    address payable internal deployer;
    address payable internal treasury;
    address payable internal developer;
    uint256 pId;
    uint256 private raffleFee = 1 ether;
    uint256 private entryFee;
    uint256 private devFee;
    uint256 private treasuryFee;
    uint256 private playerLength;
    uint256 private randomValue;
    uint256 private count = 1;
    uint256 private randomNumber;
    uint256 public numWinners = 1;
    uint256 private maxMultiplier = 2;
    uint256[] private randomNumbers;
    bool public raffleLive = false;
    uint256 public raffleStartTime;

    event RaffleLive(uint256 date);
    event DebugEvent(uint256 indexed number);
    event NewParticipant(
        uint256 date,
        uint256 playerPower,
        address indexed playerAddress
    );
    event DistributeFunds(
        uint256 date,
        uint256 balance,
        address indexed playerAddress
    );
    event Transfered(address _from, address _to, uint256 amount);

    modifier onlyDeployer() {
        require(msg.sender == deployer, "Only deployer.");
        _;
    }

    constructor(
        address _vrfCor,
        address _link,
        bytes32 _keyHash,
        address payable _deployer,
        address payable _developer,
        address payable _treasury
    ) VRFConsumerBase(_vrfCor, _link) {
        keyHash = _keyHash;
        fee = 0.0001 * 10**18; //0.0001 LINK
        deployer = _deployer;
        developer = _developer;
        treasury = _treasury;
    }

    function deposit() public payable {}

    function startRaffle() external onlyDeployer {
        raffleLive = true;
        count = 1;
        raffleStartTime = block.timestamp;
        deleteState();
        emit RaffleLive(raffleStartTime);
    }

    function stopRaffle() public onlyDeployer {
        raffleLive = false;
    }

    function raffleAddress(address _collabAddress) external onlyDeployer {
        raffleCollab = _collabAddress;
    }

    function setNumWinners(uint256 _num) external onlyDeployer {
        numWinners = _num;
    }

    function enterRaffle(uint256 xTokers) public payable {
        require(raffleLive, "Raffle not live");
        require(
            TMTC(TokerAddy).balanceOf(msg.sender) > 0,
            "You need at least 1 Toker to enter the raffle!"
        );

        if (xTokers >= 5) {
            raffleFee = 0.00000002 ether;
        } else {
            raffleFee = 0.00000002 ether;
        }

        entryFee = xTokers * raffleFee;
        currentEntries[msg.sender] += xTokers;
        maxEntries[msg.sender] = TMTC(TokerAddy).balanceOf(msg.sender) * maxMultiplier;
        require(msg.value == entryFee, "MATIC value sent is not correct");
        require(
            (currentEntries[msg.sender] <= maxEntries[msg.sender]),
            "Each Midnight Toker cannot buy more than two tickets"
        );
        for (uint256 i = 0; i < xTokers; i++) {
            pId = count++;
            playerTickets[msg.sender].push(pId);
            ticketId[pId] = msg.sender;
            tickets.push(pId);
            addresses.push(msg.sender);
        }

        devFee = ((entryFee * 10) / 100);
        developer.transfer(devFee);
        emit NewParticipant(block.timestamp, xTokers, msg.sender);
    }

    function enterCollabRaffle(uint256 xTokers) public payable {
        require(raffleLive, "Raffle not live");
        require(
            TMTC(raffleCollab).balanceOf(msg.sender) > 0,
            "You need at least 1 Toker to enter the raffle!"
        );

        if (xTokers >= 10) {
            raffleFee = 0.00000002 ether;
        } else {
            raffleFee = 0.00000002 ether;
        }

        entryFee = xTokers * raffleFee;
        currentEntries[msg.sender] += xTokers;
        maxEntries[msg.sender] = TMTC(raffleCollab).balanceOf(msg.sender) * maxMultiplier;
        require(msg.value == entryFee, "MATIC value sent is not correct");
        require(
            (currentEntries[msg.sender] <= maxEntries[msg.sender]),
            "Each collab project cannot buy more than two tickets per NFT owned"
        );
        for (uint256 i = 0; i < xTokers; i++) {
            pId = count++;
            playerTickets[msg.sender].push(pId);
            ticketId[pId] = msg.sender;
            tickets.push(pId);
            addresses.push(msg.sender);
        }

        devFee = ((entryFee * 10) / 100);
        developer.transfer(devFee);
        emit NewParticipant(block.timestamp, xTokers, msg.sender);
    }

    function getNumTickets() public view returns (uint256) {
        return tickets.length;
    }

    function getWinners() public view returns (uint256[] memory winningNs) {
        return winningNumbers;
    }

    function getMaxEntries(address _sender) public view returns (uint256) {
        return TMTC(TokerAddy).balanceOf(_sender) * maxMultiplier + TMTC(raffleCollab).balanceOf(_sender);
    }

    function getPot() public view returns (uint256) {
        return (address(this).balance * 75) / 100; //minus treasuryFee
    }
    
    
    function getPlayerTickets(address _address) public view returns (uint256[] memory) {
        return playerTickets[_address];   
    }

    function deleteState() public onlyDeployer {
        for (uint256 i = 0; i < tickets.length + 1; i++) {
            ticketId[i] = 0x0000000000000000000000000000000000000000;
        }
        for (uint256 i = 0; i < addresses.length; i++) {
            currentEntries[addresses[i]] = 0;
            maxEntries[addresses[i]] = 0;
            delete playerTickets[addresses[i]];
        }
        delete addresses;
        delete tickets;
        delete winningNumbers;
    }

    function tokenOfOwnerByIndex(address _owner, uint256 _index)
        internal
        view
        returns (uint256)
    {
        return TMTC(TokerAddy).tokenOfOwnerByIndex(_owner, _index);
    }

    function getRandomNumber() public onlyDeployer returns (bytes32 requestId) {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );
        require(
            tickets.length >= numWinners,
            "not enough players entered for number of winners!"
        );
        stopRaffle();
        return requestRandomness(keyHash, fee);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        randomValue = randomness;
        randomNumber = (randomValue % tickets.length) + 1;
        winningNumbers = expand(randomNumber, numWinners);
    }

    function expand(uint256 randomVal, uint256 numWin)
        internal
        returns (uint256[] memory)
    {
        uint256[] memory tempRandomNumbers = new uint256[](numWin);
        tempRandomNumbers[0] = randomVal;

        uint256 j = 1;
        while (j < numWin) {
            randomVal = uint256(keccak256(abi.encode(randomVal, numWinners)));
            randomVal = (randomVal % tickets.length) + 1;

            bool found = false;
            uint256 found_pos = 0;
            for (uint256 i = 0; i < tempRandomNumbers.length; i++) {
                if (tempRandomNumbers[i] == randomVal) {
                    found = true;
                    found_pos = i;
                    break;
                }
            }

            if (!found) {
                tempRandomNumbers[j] = randomVal;
            } else {
                while (tempRandomNumbers[found_pos] == randomVal) {
                    randomVal =
                        (uint256(
                            keccak256(
                                abi.encode(
                                    randomVal,
                                    found_pos,
                                    numWinners,
                                    block.timestamp
                                )
                            )
                        ) % tickets.length) +
                        1;
                }
                tempRandomNumbers[j] = randomVal;
            }
            j++;
        }
        return tempRandomNumbers;
    }

    function distributeFunds() external payable onlyDeployer {
        treasuryFee = (address(this).balance * 25) / 100;
        treasury.transfer(treasuryFee);
        uint256 balEach = address(this).balance.div(numWinners);
        require(address(this).balance > 0, "No MATIC to Distribute");
        for (uint256 i = 0; i < winningNumbers.length; i++) {
            address winner = ticketId[winningNumbers[i]];
            payable(winner).transfer(balEach);
            emit DistributeFunds(block.timestamp, balEach, winner);
        }
    }

    function withdraw(address payable destination)
        external
        onlyDeployer
    {
        destination.transfer(address(this).balance);
        emit Transfered(msg.sender, destination, address(this).balance);
    }

    function withdrawERC20(
        IERC20 token,
        address payable destination
    ) public onlyDeployer {
        uint256 erc20balance = token.balanceOf(address(this));
        require(token.balanceOf(address(this)) <= erc20balance, "Insufficient funds");
        token.transfer(destination, token.balanceOf(address(this)));
        emit Transfered(msg.sender, destination, token.balanceOf(address(this)));
    }
}