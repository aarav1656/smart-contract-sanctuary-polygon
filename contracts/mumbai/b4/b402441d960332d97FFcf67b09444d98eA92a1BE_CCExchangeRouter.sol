// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.4;

import "./interfaces/ICCExchangeRouter.sol";
import "../connectors/interfaces/IExchangeConnector.sol";
import "./interfaces/IInstantRouter.sol";
import "../relay/interfaces/IBitcoinRelay.sol";
import "../erc20/interfaces/ITeleBTC.sol";
import "../lockers/interfaces/ILockers.sol";
import "../libraries/RequestHelper.sol";
import "../libraries/BitcoinHelper.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract CCExchangeRouter is ICCExchangeRouter, Ownable, ReentrancyGuard {

    modifier nonZeroAddress(address _address) {
        require(_address != address(0), "CCExchangeRouter: address is zero");
        _;
    }

    // Constants
    uint constant MAX_PROTOCOL_FEE = 10000;

    // Public variables
    uint public override startingBlockNumber;
    uint public override chainId;
    uint public override protocolPercentageFee; // A number between 0 to 10000
    address public override relay;
    address public override instantRouter;
    address public override lockers;
    address public override teleBTC;
    address public override treasury;
    mapping(uint => address) public override exchangeConnector; // mapping from app id to exchange connector address 

    // Private variables
    mapping(bytes32 => ccExchangeRequest) private ccExchangeRequests;

    /// @notice                             Gives default params to initiate cc exchange router
    /// @param _startingBlockNumber         Requests that are included in a block older than _startingBlockNumber cannot be executed
    /// @param _protocolPercentageFee       Percentage amount of protocol fee (min: %0.01)
    /// @param _chainId                     Id of the underlying chain
    /// @param _relay                       The Relay address to validate data from source chain
    /// @param _lockers                     Lockers' contract address
    /// @param _teleBTC                     TeleportDAO BTC ERC20 token address
    /// @param _treasury                    Address of treasury that collects protocol fees
    constructor(
        uint _startingBlockNumber,
        uint _protocolPercentageFee,
        uint _chainId,
        address _lockers,
        address _relay,
        address _teleBTC,
        address _treasury
    ) {
        startingBlockNumber = _startingBlockNumber;
        chainId = _chainId;
        _setProtocolPercentageFee(_protocolPercentageFee);
        _setRelay(_relay);
        _setLockers(_lockers);
        _setTeleBTC(_teleBTC);
        _setTreasury(_treasury);
    }

    function renounceOwnership() public virtual override onlyOwner {}

    /// @notice         Changes relay contract address
    /// @dev            Only owner can call this
    /// @param _relay   The new relay contract address
    function setRelay(address _relay) external override onlyOwner {
        _setRelay(_relay);
    }

    /// @notice                 Changes instantRouter contract address
    /// @dev                    Only owner can call this
    /// @param _instantRouter   The new instantRouter contract address
    function setInstantRouter(address _instantRouter) external override onlyOwner {
        _setInstantRouter(_instantRouter);
    }

    /// @notice                 Changes lockers contract address
    /// @dev                    Only owner can call this
    /// @param _lockers         The new lockers contract address
    function setLockers(address _lockers) external override onlyOwner {
        _setLockers(_lockers);
    }

    /// @notice                     Sets appId for an exchange connector
    /// @dev                        Only owner can call this. _exchangeConnector can be set to zero to inactive an app
    /// @param _appId               AppId of exchange connector
    /// @param _exchangeConnector   Address of exchange connector
    function setExchangeConnector(
        uint _appId, 
        address _exchangeConnector
    ) external override onlyOwner {
        exchangeConnector[_appId] = _exchangeConnector;
        emit SetExchangeConnector(_appId, _exchangeConnector);
    }

    /// @notice                 Changes teleBTC contract address
    /// @dev                    Only owner can call this
    /// @param _teleBTC         The new teleBTC contract address
    function setTeleBTC(address _teleBTC) external override onlyOwner {
        _setTeleBTC(_teleBTC);
    }

    /// @notice                             Setter for protocol percentage fee
    /// @dev                    Only owner can call this
    /// @param _protocolPercentageFee       Percentage amount of protocol fee
    function setProtocolPercentageFee(uint _protocolPercentageFee) external override onlyOwner {
        _setProtocolPercentageFee(_protocolPercentageFee);
    }

    /// @notice                    Setter for treasury
    /// @dev                       Only owner can call this
    /// @param _treasury           Treasury address
    function setTreasury(address _treasury) external override onlyOwner {
        _setTreasury(_treasury);
    }

    /// @notice         Internal setter for relay contract address
    /// @param _relay   The new relay contract address
    function _setRelay(address _relay) private nonZeroAddress(_relay) {
        emit NewRelay(relay, _relay);
        relay = _relay;
    }

    /// @notice                 Internal setter for instantRouter contract address
    /// @param _instantRouter   The new instantRouter contract address
    function _setInstantRouter(address _instantRouter) private nonZeroAddress(_instantRouter) {
        emit NewInstantRouter(instantRouter, _instantRouter);
        instantRouter = _instantRouter;
    }

    /// @notice                 Internal setter for lockers contract address
    /// @param _lockers         The new lockers contract address
    function _setLockers(address _lockers) private nonZeroAddress(_lockers) {
        emit NewLockers(lockers, _lockers);
        lockers = _lockers;
    }

    /// @notice                 Internal setter for teleBTC contract address
    /// @param _teleBTC         The new teleBTC contract address
    function _setTeleBTC(address _teleBTC) private nonZeroAddress(_teleBTC) {
        emit NewTeleBTC(teleBTC, _teleBTC);
        teleBTC = _teleBTC;
    }

    /// @notice                             Internal setter for protocol percentage fee
    /// @param _protocolPercentageFee       Percentage amount of protocol fee
    function _setProtocolPercentageFee(uint _protocolPercentageFee) private {
        require(
            MAX_PROTOCOL_FEE >= _protocolPercentageFee,
            "CCExchangeRouter: fee is out of range"
        );
        emit NewProtocolPercentageFee(protocolPercentageFee, _protocolPercentageFee);
        protocolPercentageFee = _protocolPercentageFee;
    }

    /// @notice                    Internal setter for treasury
    /// @param _treasury           Treasury address
    function _setTreasury(address _treasury) private nonZeroAddress(_treasury) {
        emit NewTreasury(treasury, _treasury);
        treasury = _treasury;
    }

    /// @notice                             Check if the cc exchange request has been executed before
    /// @dev                                It prevents re-submitting an executed request
    /// @param _txId                        The transaction ID of request on source chain 
    /// @return                             True if the cc exchange request has been already executed
    function isRequestUsed(bytes32 _txId) external view override returns (bool) {
        return ccExchangeRequests[_txId].isUsed ? true : false;
    }

    /// @notice                     Executes a cross-chain exchange request after checking its merkle inclusion proof
    /// @dev                        Mints teleBTC for user if exchanging is not successful
    /// @param _version             Version of the transaction containing the user request
    /// @param _vin                 Inputs of the transaction containing the user request
    /// @param _vout                Outputs of the transaction containing the user request
    /// @param _locktime            Lock time of the transaction containing the user request
    /// @param _blockNumber         Height of the block containing the user request
    /// @param _intermediateNodes   Merkle inclusion proof for transaction containing the user request
    /// @param _index               Index of transaction containing the user request in the block
    /// @param _lockerLockingScript    Script hash of locker that user has sent BTC to it
    /// @return
    function ccExchange(
        bytes4 _version,
        bytes memory _vin,
        bytes calldata _vout,
        bytes4 _locktime,
        uint256 _blockNumber,
        bytes calldata _intermediateNodes,
        uint _index,
        bytes calldata _lockerLockingScript
    ) external payable nonReentrant override returns (bool) {
        require(_blockNumber >= startingBlockNumber, "CCExchangeRouter: request is too old");

        // Calculates transaction id
        bytes32 txId = BitcoinHelper.calculateTxId(_version, _vin, _vout, _locktime);

        // Checks that the request has not been processed before
        require(
            !ccExchangeRequests[txId].isUsed,
            "CCExchangeRouter: the request has been used before"
        );

        require(_locktime == bytes4(0), "CCExchangeRouter: lock time is non-zero");

        // Extracts information from the request
        _saveCCExchangeRequest(_lockerLockingScript, _vout, txId);

        // Check if transaction has been confirmed on source chain
        require(
            _isConfirmed(
                txId,
                _blockNumber,
                _intermediateNodes,
                _index
            ),
            "CCExchangeRouter: transaction has not been finalized yet"
        );

        if (ccExchangeRequests[txId].speed == 0) {
            // Normal cc exchange request
            _normalCCExchange(_lockerLockingScript, txId);
        } else {
            // Pay back instant loan (ccExchangeRequests[txId].speed == 1)
            _payBackInstantLoan(_lockerLockingScript, txId);
        }

        return true;
    }

    /// @notice                          Executes a normal cross-chain exchange request
    /// @dev                             Mints teleBTC for user if exchanging is not successful
    /// @param _lockerLockingScript      Locker's locking script    
    /// @param _txId                     Id of the transaction containing the user request
    function _normalCCExchange(bytes memory _lockerLockingScript, bytes32 _txId) private {
        // Gets remained amount after reducing fees
        uint remainedInputAmount = _mintAndReduceFees(_lockerLockingScript, _txId);

        bool result;
        uint[] memory amounts;

        // Gets exchange connector address
        address _exchangeConnector = exchangeConnector[ccExchangeRequests[_txId].appId];
        require(_exchangeConnector != address(0), "CCExchangeRouter: app id doesn't exist");

        // Gives allowance to exchange connector to transfer from cc exchange router
        ITeleBTC(teleBTC).approve(
            _exchangeConnector,
            remainedInputAmount
        );
        
        ccExchangeRequest memory theCCExchangeReq = ccExchangeRequests[_txId];

        if (IExchangeConnector(_exchangeConnector).isPathValid(theCCExchangeReq.path)) {
            // Exchanges minted teleBTC for output token
            (result, amounts) = IExchangeConnector(_exchangeConnector).swap(
                remainedInputAmount,
                theCCExchangeReq.outputAmount,
                theCCExchangeReq.path,
                theCCExchangeReq.recipientAddress,
                theCCExchangeReq.deadline,
                theCCExchangeReq.isFixedToken
            );
        } else {
            // Exchanges minted teleBTC for output token via wrappedNativeToken
            // note: path is [teleBTC, wrappedNativeToken, outputToken]
            address[] memory _path = new address[](3);
            _path[0] = theCCExchangeReq.path[0];
            _path[1] = IExchangeConnector(_exchangeConnector).wrappedNativeToken();
            _path[2] = theCCExchangeReq.path[1];

            (result, amounts) = IExchangeConnector(_exchangeConnector).swap(
                remainedInputAmount,
                theCCExchangeReq.outputAmount,
                _path,
                theCCExchangeReq.recipientAddress,
                theCCExchangeReq.deadline,
                theCCExchangeReq.isFixedToken
            );
        }

        if (result) {
            // Emits CCExchange if exchange was successful
            emit CCExchange(
                _lockerLockingScript,
                0,
                ILockers(lockers).getLockerTargetAddress(_lockerLockingScript),
                theCCExchangeReq.recipientAddress,
                [theCCExchangeReq.path[0], theCCExchangeReq.path[1]], // input token // output token
                [amounts[0], amounts[amounts.length-1]], // input amount // output amount
                theCCExchangeReq.speed,
                _msgSender(), // Teleporter address
                theCCExchangeReq.fee,
                _txId,
                theCCExchangeReq.appId
            );

            // Transfers rest of teleBTC to recipientAddress (if input amount is not fixed)
            if (theCCExchangeReq.isFixedToken == false) {
                ITeleBTC(teleBTC).transfer(
                    theCCExchangeReq.recipientAddress,
                    remainedInputAmount - amounts[0]
                );
            }
        } else {
            // Handles situation when exchange was not successful

            // Revokes allowance
            ITeleBTC(teleBTC).approve(
                _exchangeConnector,
                0
            );

            // Sends teleBTC to recipient if exchange wasn't successful
            ITeleBTC(teleBTC).transfer(
                theCCExchangeReq.recipientAddress,
                remainedInputAmount
            );

            emit FailedCCExchange(
                _lockerLockingScript,
                0,
                ILockers(lockers).getLockerTargetAddress(_lockerLockingScript),
                theCCExchangeReq.recipientAddress,
                [theCCExchangeReq.path[0], theCCExchangeReq.path[1]], // input token // output token
                [remainedInputAmount, 0],// input amount //  output amount
                theCCExchangeReq.speed,
                _msgSender(), // Teleporter address
                theCCExchangeReq.fee,
                _txId,
                theCCExchangeReq.appId
            );
        }
    }

    /// @notice                        Executes an instant cross-chain exchange request
    /// @dev                           Mints teleBTC for instant router to pay back loan
    /// @param _lockerLockingScript    Locker's locking script
    /// @param _txId                   Id of the transaction containing the user request
    function _payBackInstantLoan(bytes memory _lockerLockingScript, bytes32 _txId) private {
        // Gets remained amount after reducing fees
        uint remainedAmount = _mintAndReduceFees(_lockerLockingScript, _txId);

        // Gives allowance to instant router to transfer minted teleBTC
        ITeleBTC(teleBTC).approve(
            instantRouter,
            remainedAmount
        );

        // Pays back instant loan
        IInstantRouter(instantRouter).payBackLoan(
            ccExchangeRequests[_txId].recipientAddress,
            remainedAmount
        );

        ccExchangeRequest memory theCCExchangeReq = ccExchangeRequests[_txId];

        emit CCExchange(
            _lockerLockingScript,
            0,
            ILockers(lockers).getLockerTargetAddress(_lockerLockingScript),
            theCCExchangeReq.recipientAddress,
            [theCCExchangeReq.path[0], theCCExchangeReq.path[1]], // input token // output token
            [remainedAmount, theCCExchangeReq.outputAmount], // input amount // output amount
            theCCExchangeReq.speed,
            _msgSender(), // Teleporter address
            theCCExchangeReq.fee,
            _txId,
            theCCExchangeReq.appId
        );
    }

    /// @notice                             Parses and saves the request
    /// @dev                                Checks that user has sent BTC to a valid locker
    /// @param _lockerLockingScript         Locker's locking script
    /// @param _vout                        The outputs of the tx
    /// @param _txId                        The txID of the request
    function _saveCCExchangeRequest(
        bytes memory _lockerLockingScript,
        bytes memory _vout,
        bytes32 _txId
    ) private {

        // Checks that given script hash is locker
        require(
            ILockers(lockers).isLocker(_lockerLockingScript),
            "CCExchangeRouter: no locker with give script hash exists"
        );

        // Extracts value and opreturn data from request
        ccExchangeRequest memory request; // Defines it to save gas
        bytes memory arbitraryData;
        (request.inputAmount, arbitraryData) = BitcoinHelper.parseValueAndDataHavingLockingScriptBigPayload(
            _vout, 
            _lockerLockingScript
        );

        // Checks that input amount is not zero
        require(request.inputAmount > 0, "CCExchangeRouter: input amount is zero");

        // Checks that the request belongs to this chain
        require(chainId == RequestHelper.parseChainId(arbitraryData), "CCExchangeRouter: chain id is not correct");
        request.appId = RequestHelper.parseAppId(arbitraryData);
        
        address exchangeToken = RequestHelper.parseExchangeToken(arbitraryData);
        request.outputAmount = RequestHelper.parseExchangeOutputAmount(arbitraryData);

        if (RequestHelper.parseIsFixedToken(arbitraryData) == 0) {
            request.isFixedToken = false ;
        } else {
            request.isFixedToken = true ;
        }

        request.recipientAddress = RequestHelper.parseRecipientAddress(arbitraryData);

        // note: we assume that the path length is two
        address[] memory thePath = new address[](2);
        thePath[0] = teleBTC;
        thePath[1] = exchangeToken;
        request.path = thePath;

        request.deadline = RequestHelper.parseDeadline(arbitraryData);

        // Calculates fee
        uint percentageFee = RequestHelper.parsePercentageFee(arbitraryData);
        require(percentageFee <= MAX_PROTOCOL_FEE, "CCExchangeRouter: percentage fee is not correct");
        request.fee = percentageFee*request.inputAmount/MAX_PROTOCOL_FEE;

        request.speed = RequestHelper.parseSpeed(arbitraryData);
        require(request.speed == 0 || request.speed == 1, "CCExchangeRouter: speed is not correct");

        request.isUsed = true;

        // Saves request
        ccExchangeRequests[_txId] = request;
    }

    /// @notice                             Checks if tx has been finalized on source chain
    /// @dev                                Pays relay fee using included ETH in the transaction
    /// @param _txId                        The request tx
    /// @param _blockNumber                 The block number of the tx
    /// @param _intermediateNodes           Merkle proof for tx
    /// @param _index                       Index of tx in the block
    /// @return                             True if the tx is finalized on the source chain
    function _isConfirmed(
        bytes32 _txId,
        uint256 _blockNumber,
        bytes memory _intermediateNodes,
        uint _index
    ) private returns (bool) {
        // Finds fee amount
        uint feeAmount = IBitcoinRelay(relay).getBlockHeaderFee(_blockNumber, 0);
        require(msg.value >= feeAmount, "CCExchangeRouter: paid fee is not sufficient");

        // Calls relay contract
        bytes memory data = Address.functionCallWithValue(
            relay,
            abi.encodeWithSignature(
                "checkTxProof(bytes32,uint256,bytes,uint256)",
                _txId,
                _blockNumber,
                _intermediateNodes,
                _index
            ),
            feeAmount
        );

        // Sends extra ETH back to _msgSender()
        Address.sendValue(payable(_msgSender()), msg.value - feeAmount);

        return abi.decode(data, (bool));
    }

    /// @notice                       Mints teleBTC by calling lockers contract
    /// @param _lockerLockingScript   Locker's locking script
    /// @param _txId                  The transaction ID of the request
    /// @return _remainedAmount       Amount of teleBTC that user receives after reducing all fees (protocol, locker, teleporter)
    function _mintAndReduceFees(
        bytes memory _lockerLockingScript,
        bytes32 _txId
    ) private returns (uint _remainedAmount) {

        // Mints teleBTC for cc exchange router
        uint mintedAmount = ILockers(lockers).mint(
            _lockerLockingScript,
            address(this),
            ccExchangeRequests[_txId].inputAmount
        );

        // Calculates fees
        uint protocolFee = ccExchangeRequests[_txId].inputAmount*protocolPercentageFee/MAX_PROTOCOL_FEE;
        uint teleporterFee = ccExchangeRequests[_txId].fee;

        // Pays Teleporter fee
        if (teleporterFee > 0) {
            ITeleBTC(teleBTC).transfer(_msgSender(), teleporterFee);
        }

        // Pays protocol fee
        if (protocolFee > 0) {
            ITeleBTC(teleBTC).transfer(treasury, protocolFee);
        }

        _remainedAmount = mintedAmount - protocolFee - teleporterFee;
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.4;

interface ICCExchangeRouter {
    // Structures

    /// @notice                    Structure for recording cross-chain exchange requests
    /// @param appId               Application id that user wants to use (defines the exchange that user wants to use)
    /// @param inputAmount         Amount of locked BTC on source chain
    /// @param outputAmount        Amount of output token
    /// @param isFixedToken        True if amount of input token is fixed
    /// @param recipientAddress    Address of exchange recipient
    /// @param fee                 Amount of fee that is paid to Teleporter (tx, relayer and teleporter fees)
    /// @param isUsed              Whether the tx is used or not
    /// @param path                Path from input token to output token
    /// @param deadline            Deadline of exchanging tokens
    /// @param speed               Speed of the request (normal or instant)
    struct ccExchangeRequest {
        uint appId;
        uint inputAmount;
        uint outputAmount;
        bool isFixedToken;
        address recipientAddress;
        uint fee;
        bool isUsed;
        address[] path;
        uint deadline;
        uint speed;
    }

    // Events

    /// @notice                     Emits when a cc exchange request gets done
    /// @param user                 Exchange recipient address
    /// @param speed                Speed of the request (normal or instant)
    /// @param teleporter          Address of teleporter who submitted the request
    /// @param teleporterFee        Amount of fee that is paid to Teleporter (tx, relayer and teleporter fees)
    event CCExchange(
        bytes lockerLockingScript,
        uint lockerScriptType,
        address lockerTargetAddress,
        address indexed user,
        address[2] inputAndOutputToken,
        uint[2] inputAndOutputAmount,
        uint indexed speed,
        address indexed teleporter,
        uint teleporterFee,
        bytes32 bitcoinTxId,
        uint appId
    );

    /// @notice                     Emits when a cc exchange request fails
    /// @dev                        In this case, instead of excahnging tokens,
    ///                             we mint teleBTC and send it to the user
    /// @param recipientAddress     Exchange recipient address
    /// @param speed                Speed of the request (normal or instant)
    /// @param teleporter          Address of teleporter who submitted the request
    /// @param teleporterFee        Amount of fee that is paid to Teleporter (tx, relayer and teleporter fees)
    event FailedCCExchange(
        bytes lockerLockingScript,
        uint lockerScriptType,
        address lockerTargetAddress,
        address indexed recipientAddress,
        address[2] inputAndOutputToken,
        uint[2] inputAndOutputAmount,
        uint indexed speed,
        address indexed teleporter,
        uint teleporterFee,
        bytes32 bitcoinTxId,
        uint appId
    );

    /// @notice                      Emits when appId for an exchange connector is set
    /// @param appId                 Assigned application id to exchange
    /// @param exchangeConnector     Address of exchange connector contract
    event SetExchangeConnector(
        uint appId,
        address exchangeConnector
    );

    /// @notice                     Emits when changes made to relay address
    event NewRelay (
        address oldRelay, 
        address newRelay
    );

    /// @notice                     Emits when changes made to InstantRouter address
    event NewInstantRouter (
        address oldInstantRouter, 
        address newInstantRouter
    );

    /// @notice                     Emits when changes made to Lockers address
    event NewLockers (
        address oldLockers, 
        address newLockers
    );

    /// @notice                     Emits when changes made to TeleBTC address
    event NewTeleBTC (
        address oldTeleBTC, 
        address newTeleBTC
    );

    /// @notice                     Emits when changes made to protocol percentage fee
    event NewProtocolPercentageFee (
        uint oldProtocolPercentageFee, 
        uint newProtocolPercentageFee
    );

    /// @notice                     Emits when changes made to Treasury address
    event NewTreasury (
        address oldTreasury, 
        address newTreasury
    );

    // Read-only functions
    
    function startingBlockNumber() external view returns (uint);

    function protocolPercentageFee() external view returns (uint);
    
    function chainId() external view returns (uint);

    function relay() external view returns (address);

    function instantRouter() external view returns (address);

    function lockers() external view returns (address);

    function teleBTC() external view returns (address);

    function isRequestUsed(bytes32 _txId) external view returns (bool);

    function exchangeConnector(uint appId) external view returns (address);

    function treasury() external view returns (address);

    // State-changing functions

    function setRelay(address _relay) external;

    function setInstantRouter(address _instantRouter) external;

    function setLockers(address _lockers) external;

    function setTeleBTC(address _teleBTC) external;

    function setExchangeConnector(uint _appId, address _exchangeConnector) external;

	function setTreasury(address _treasury) external;

	function setProtocolPercentageFee(uint _protocolPercentageFee) external;

    function ccExchange(
        // Bitcoin tx
        bytes4 _version,
        bytes memory _vin,
        bytes calldata _vout,
        bytes4 _locktime,
        // Bitcoin block number
        uint256 _blockNumber,
        // Merkle proof
        bytes calldata _intermediateNodes,
        uint _index,
        bytes calldata _lockerLockingScript
    ) external payable returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.4;

interface IExchangeConnector {

    // Events
    
    event Swap(address[] path, uint[] amounts, address receiver);

    // Read-only functions

    function name() external view returns (string memory);

    function exchangeRouter() external view returns (address);

    function liquidityPoolFactory() external view returns (address);

    function wrappedNativeToken() external view returns (address);

    function getInputAmount(
        uint _outputAmount,
        address _inputToken,
        address _outputToken
    ) external view returns (bool, uint);

    function getOutputAmount(
        uint _inputAmount,
        address _inputToken,
        address _outputToken
    ) external view returns (bool, uint);

    // State-changing functions

    function setExchangeRouter(address _exchangeRouter) external;

    function setLiquidityPoolFactory() external;

    function setWrappedNativeToken() external;

    function swap(
        uint256 _inputAmount,
        uint256 _outputAmount,
        address[] memory _path,
        address _to,
        uint256 _deadline,
        bool _isFixedToken
    ) external returns (bool, uint[] memory);

    function isPathValid(address[] memory _path) external view returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.4;

interface IInstantRouter {
    // Structures

    /// @notice                                 Structure for recording instant requests
    /// @param user                             Address of user who recieves loan
    /// @param collateralPool                   Address of collateral pool
    /// @param collateralToken                  Address of underlying collateral token
    /// @param paybackAmount                    Amount of (loan + instant fee)
    /// @param lockedCollateralPoolTokenAmount  Amount of locked collateral pool token for getting loan
    /// @param deadline                         Deadline for paying back the loan
    /// @param requestCounterOfUser             The index of the request for a specific user
    struct instantRequest {
        address user;
        address collateralPool;
		address collateralToken;
        uint paybackAmount;
        uint lockedCollateralPoolTokenAmount;
        uint deadline;
        uint requestCounterOfUser;
    }

    // Events

    /// @notice                             Emits when a user gets loan for transfer
    /// @param user                         Address of the user who made the request
    /// @param receiver                     Address of the loan receiver
    /// @param loanAmount                   Amount of the loan
    /// @param instantFee                   Amount of the instant loan fee
    /// @param deadline                     Deadline of paying back the loan
    /// @param collateralToken              Address of the collateral token
    /// @param lockedCollateralPoolToken    Amount of collateral pool token that got locked
    event InstantTransfer(
        address indexed user, 
        address receiver, 
        uint loanAmount, 
        uint instantFee, 
        uint indexed deadline, 
        address indexed collateralToken,
        uint lockedCollateralPoolToken,
        uint requestCounterOfUser
    );

    /// @notice                             Emits when a user gets loan for exchange
    /// @param user                         Address of the user who made the request
    /// @param receiver                     Address of the loan receiver
    /// @param loanAmount                   Amount of the loan
    /// @param instantFee                   Amount of the instant loan fee
    /// @param amountOut                    Amount of the output token
    /// @param path                         Path of exchanging tokens
    /// @param isFixed                      Shows whether input or output is fixed in exchange
    /// @param deadline                     Deadline of getting the loan
    /// @param collateralToken              Address of the collateral token
    /// @param lockedCollateralPoolToken    Amount of collateral pool token that got locked
    event InstantExchange(
        address indexed user, 
        address receiver, 
        uint loanAmount, 
        uint instantFee,
        uint amountOut,
        address[] path,
        bool isFixed,
        uint indexed deadline, 
        address indexed collateralToken,
        uint lockedCollateralPoolToken,
        uint requestCounterOfUser
    );

    /// @notice                            Emits when a loan gets paid back
    /// @param user                        Address of user who recieves loan
    /// @param paybackAmount               Amount of (loan + fee) that should be paid back
    /// @param collateralToken             Address of underlying collateral token
    /// @param lockedCollateralPoolToken   Amount of locked collateral pool token for getting loan
    event PaybackLoan(
		address indexed user, 
		uint paybackAmount, 
		address indexed collateralToken, 
		uint lockedCollateralPoolToken,
        uint requestCounterOfUser
	);

    /// @notice                         Emits when a user gets slashed
    /// @param user                     Address of user who recieves loan
    /// @param collateralToken          Address of collateral underlying token
	/// @param slashedAmount            How much user got slashed
	/// @param paybackAmount            Amount of teleBTC paid back to the protocol
	/// @param slasher                  Address of slasher
	/// @param slasherReward            Slasher reward (in collateral token)
    event SlashUser(
		address indexed user, 
		address indexed collateralToken, 
		uint slashedAmount, 
		uint paybackAmount,
        address indexed slasher,
        uint slasherReward,
        uint requestCounterOfUser
	);

    /// @notice                     	Emits when changes made to payback deadline
    event NewPaybackDeadline(
        uint oldPaybackDeadline, 
        uint newPaybackDeadline
    );

    /// @notice                     	Emits when changes made to slasher percentage reward
    event NewSlasherPercentageReward(
        uint oldSlasherPercentageReward, 
        uint newSlasherPercentageReward
    );

    /// @notice                     	Emits when changes made to treasuray overhead percnet
    event NewTreasuaryAddress(
        address oldTreasuaryAddress, 
        address newTreasuaryAddress
    );

    /// @notice                     	Emits when changes made to max price difference percent
    event NewMaxPriceDifferencePercent(
        uint oldMaxPriceDifferencePercent, 
        uint newMaxPriceDifferencePercent
    );

    /// @notice                     	Emits when changes made to TeleBTC address
    event NewTeleBTC(
        address oldTeleBTC, 
        address newTeleBTC
    );

    /// @notice                     	Emits when changes made to relay address
    event NewRelay(
        address oldRelay, 
        address newRelay
    );

    /// @notice                     	Emits when changes made to collateral pool factory address
    event NewCollateralPoolFactory(
        address oldCollateralPoolFactory, 
        address newCollateralPoolFactory
    );

    /// @notice                     	Emits when changes made to price oracle address
    event NewPriceOracle(
        address oldPriceOracle, 
        address newPriceOracle
    );

    /// @notice                     	Emits when changes made to TeleBTC instant pool address
    event NewTeleBTCInstantPool(
        address oldTeleBTCInstantPool, 
        address newTeleBTCInstantPool
    );

    /// @notice                     	Emits when changes made to default exchange connector address
    event NewDefaultExchangeConnector(
        address oldDefaultExchangeConnector, 
        address newDefaultExchangeConnector
    );


    // Read-only functions

    function pause() external;

    function unpause() external;

    function teleBTCInstantPool() external view returns (address);

    function teleBTC() external view returns (address);

    function relay() external view returns (address);

	function collateralPoolFactory() external view returns (address);

	function priceOracle() external view returns (address);

    function slasherPercentageReward() external view returns (uint);

    function paybackDeadline() external view returns (uint);

    function defaultExchangeConnector() external view returns (address);
    
    function getLockedCollateralPoolTokenAmount(address _user, uint _index) external view returns (uint);

    function getUserRequestsLength(address _user) external view returns (uint);

    function getUserRequestDeadline(address _user, uint _index) external view returns (uint);

    function maxPriceDifferencePercent() external view returns (uint);

    function treasuaryAddress() external view returns (address);

    // State-changing functions

    function setPaybackDeadline(uint _paybackDeadline) external;

    function setSlasherPercentageReward(uint _slasherPercentageReward) external;

    function setPriceOracle(address _priceOracle) external;

    function setCollateralPoolFactory(address _collateralPoolFactory) external;

    function setRelay(address _relay) external;

    function setTeleBTC(address _teleBTC) external;

    function setTeleBTCInstantPool(address _teleBTCInstantPool) external;

    function setDefaultExchangeConnector(address _defaultExchangeConnector) external;

    function setTreasuaryAddress(address _treasuaryAddres) external;
    
    function setMaxPriceDifferencePercent(uint _maxPriceDifferencePercent) external;

    function instantCCTransfer(
        address _receiver,
        uint _loanAmount,
        uint _deadline,
        address _collateralPool
    ) external returns (bool);

    function instantCCExchange(
		address _exchangeConnector,
        address _receiver,
        uint _loanAmount, 
        uint _amountOut, 
        address[] memory _path, 
        uint _deadline,
        address _collateralToken,
        bool _isFixedToken
    ) external returns (uint[] memory);

    function payBackLoan(address _user, uint _teleBTCAmount) external returns (bool);

    function slashUser(
		address _user, 
		uint _requestIndex
	) external returns (bool);

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.4;

interface IBitcoinRelay {
    // Structures

    /// @notice                 	Structure for recording block header
    /// @param selfHash             Hash of block header
    /// @param parentHash          	Hash of parent block header
    /// @param merkleRoot       	Merkle root of transactions in the block
    /// @param relayer              Address of relayer who submitted the block header
    /// @param gasPrice             Gas price of tx that relayer submitted the block header
    struct blockHeader {
        bytes32 selfHash;
        bytes32 parentHash;
        bytes32 merkleRoot;
        address relayer;
        uint gasPrice;
    }

    // Events

    /// @notice                     Emits when a block header is added
    /// @param height               Height of submitted header
    /// @param selfHash             Hash of submitted header
    /// @param parentHash           Parent hash of submitted header
    /// @param relayer              Address of relayer who submitted the block header
    event BlockAdded(
        uint indexed height,
        bytes32 selfHash,
        bytes32 indexed parentHash,
        address indexed relayer
    );

    /// @notice                     Emits when a block header gets finalized
    /// @param height               Height of the header
    /// @param selfHash             Hash of the header
    /// @param parentHash           Parent hash of the header
    /// @param relayer              Address of relayer who submitted the block header
    /// @param rewardAmountTNT      Amount of reward that the relayer receives in target native token
    /// @param rewardAmountTDT      Amount of reward that the relayer receives in TDT
    event BlockFinalized(
        uint indexed height,
        bytes32 selfHash,
        bytes32 parentHash,
        address indexed relayer,
        uint rewardAmountTNT,
        uint rewardAmountTDT
    );
         

    /// @notice                     Emits when changes made to reward amount in TDT
    event NewRewardAmountInTDT (
        uint oldRewardAmountInTDT, 
        uint newRewardAmountInTDT
    );

    /// @notice                     Emits when changes made to finalization parameter
    event NewFinalizationParameter (
        uint oldFinalizationParameter, 
        uint newFinalizationParameter
    );

    /// @notice                     Emits when changes made to relayer percentage fee
    event NewRelayerPercentageFee (
        uint oldRelayerPercentageFee, 
        uint newRelayerPercentageFee
    );

    /// @notice                     Emits when changes made to teleportDAO token
    event NewTeleportDAOToken (
        address oldTeleportDAOToken, 
        address newTeleportDAOToken
    );

    /// @notice                     Emits when changes made to epoch length
    event NewEpochLength(
        uint oldEpochLength, 
        uint newEpochLength
    );

    /// @notice                     Emits when changes made to base queries
    event NewBaseQueries(
        uint oldBaseQueries, 
        uint newBaseQueries
    );

    /// @notice                     Emits when changes made to submission gas used
    event NewSubmissionGasUsed(
        uint oldSubmissionGasUsed, 
        uint newSubmissionGasUsed
    );

    // Read-only functions

    function relayGenesisHash() external view returns (bytes32);

    function initialHeight() external view returns(uint);

    function lastSubmittedHeight() external view returns(uint);

    function finalizationParameter() external view returns(uint);

    function TeleportDAOToken() external view returns(address);

    function relayerPercentageFee() external view returns(uint);

    function epochLength() external view returns(uint);

    function lastEpochQueries() external view returns(uint);

    function currentEpochQueries() external view returns(uint);

    function baseQueries() external view returns(uint);

    function submissionGasUsed() external view returns(uint);

    function getBlockHeaderHash(uint height, uint index) external view returns(bytes32);

    function getBlockHeaderFee(uint _height, uint _index) external view returns(uint);

    function getNumberOfSubmittedHeaders(uint height) external view returns (uint);

    function availableTDT() external view returns(uint);

    function availableTNT() external view returns(uint);

    function findHeight(bytes32 _hash) external view returns (uint256);

    function findAncestor(bytes32 _hash, uint256 _offset) external view returns (bytes32); 

    function isAncestor(bytes32 _ancestor, bytes32 _descendant, uint256 _limit) external view returns (bool); 

    function rewardAmountInTDT() external view returns (uint);

    // State-changing functions

    function pauseRelay() external;

    function unpauseRelay() external;

    function setRewardAmountInTDT(uint _rewardAmountInTDT) external;

    function setFinalizationParameter(uint _finalizationParameter) external;

    function setRelayerPercentageFee(uint _relayerPercentageFee) external;

    function setTeleportDAOToken(address _TeleportDAOToken) external;

    function setEpochLength(uint _epochLength) external;

    function setBaseQueries(uint _baseQueries) external;

    function setSubmissionGasUsed(uint _submissionGasUsed) external;

    function checkTxProof(
        bytes32 txid,
        uint blockHeight,
        bytes calldata intermediateNodes,
        uint index
    ) external payable returns (bool);

    function addHeaders(bytes calldata _anchor, bytes calldata _headers) external returns (bool);

    function addHeadersWithRetarget(
        bytes calldata _oldPeriodStartHeader,
        bytes calldata _oldPeriodEndHeader,
        bytes calldata _headers
    ) external returns (bool);

    function ownerAddHeaders(bytes calldata _anchor, bytes calldata _headers) external returns (bool);

    function ownerAddHeadersWithRetarget(
        bytes calldata _oldPeriodStartHeader,
        bytes calldata _oldPeriodEndHeader,
        bytes calldata _headers
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITeleBTC is IERC20 {

    // Events
    event Mint(address indexed doer, address indexed receiver, uint value);

    event Burn(address indexed doer, address indexed burner, uint value);

    event MinterAdded(address indexed newMinter);

    event MinterRemoved(address indexed minter);

    event BurnerAdded(address indexed newBurner);

    event BurnerRemoved(address indexed burner);

    event NewMintLimit(uint oldMintLimit, uint newMintLimit);

    event NewEpochLength(uint oldEpochLength, uint newEpochLength);

    // read functions

    function decimals() external view returns (uint8);

    // state-changing functions

    function addMinter(address account) external;

    function removeMinter(address account) external;

    function addBurner(address account) external;

    function removeBurner(address account) external;

    function mint(address receiver, uint amount) external returns(bool);

    function burn(uint256 amount) external returns(bool);

    function setMaxMintLimit(uint _mintLimit) external;

    function setEpochLength(uint _length) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.4;

import "./ILockersStorage.sol";

interface ILockers is ILockersStorage {

     // Events

    event RequestAddLocker(
        address indexed lockerTargetAddress,
        bytes lockerLockingScript,
        uint TDTLockedAmount,
        uint nativeTokenLockedAmount
    );

    event RevokeAddLockerRequest(
        address indexed lockerTargetAddress,
        bytes lockerLockingScript,
        uint TDTLockedAmount,
        uint nativeTokenLockedAmount
    );

    event RequestInactivateLocker(
        address indexed lockerTargetAddress,
        uint indexed inactivationTimestamp,
        bytes lockerLockingScript,
        uint TDTLockedAmount,
        uint nativeTokenLockedAmount,
        uint netMinted
    );

    event ActivateLocker(
        address indexed lockerTargetAddress,
        bytes lockerLockingScript,
        uint TDTLockedAmount,
        uint nativeTokenLockedAmount,
        uint netMinted
    );

    event LockerAdded(
        address indexed lockerTargetAddress,
        bytes lockerLockingScript,
        uint TDTLockedAmount,
        uint nativeTokenLockedAmount,
        uint addingTime
    );

    event LockerRemoved(
        address indexed lockerTargetAddress,
        bytes lockerLockingScript,
        uint TDTUnlockedAmount,
        uint nativeTokenUnlockedAmount
    );

    event LockerSlashed(
        address indexed lockerTargetAddress,
        uint rewardAmount,
        address indexed rewardRecipient,
        uint amount,
        address indexed recipient,
        uint slashedCollateralAmount,
        uint slashTime,
        bool isForCCBurn
    );

    event LockerLiquidated(
        address indexed lockerTargetAddress,
        address indexed liquidatorAddress,
        uint collateralAmount,
        uint teleBTCAmount,
        uint liquidateTime
    );

    event LockerSlashedCollateralSold(
        address indexed lockerTargetAddress,
        address indexed buyerAddress,
        uint slashingAmount,
        uint teleBTCAmount,
        uint slashingTime
    );

    event CollateralAdded(
        address indexed lockerTargetAddress,
        uint addedCollateral,
        uint totalCollateral,
        uint addingTime
    );

    event CollateralRemoved(
        address indexed lockerTargetAddress,
        uint removedCollateral,
        uint totalCollateral,
        uint removingTime
    );

    event MintByLocker(
        address indexed lockerTargetAddress,
        address indexed receiver,
        uint mintedAmount,
        uint lockerFee,
        uint mintingTime
    );

    event BurnByLocker(
        address indexed lockerTargetAddress,
        uint burntAmount,
        uint lockerFee,
        uint burningTime
    );

    event MinterAdded(
        address indexed account
    );

    event MinterRemoved(
        address indexed account
    );

    event BurnerAdded(
        address indexed account
    );
    
    event BurnerRemoved(
        address indexed account
    );

    event NewLockerPercentageFee(
        uint oldLockerPercentageFee,
        uint newLockerPercentageFee
    );

    event NewPriceWithDiscountRatio(
        uint oldPriceWithDiscountRatio,
        uint newPriceWithDiscountRatio
    );

    event NewMinRequiredTDTLockedAmount(
        uint oldMinRequiredTDTLockedAmount,
        uint newMinRequiredTDTLockedAmount
    );

    event NewMinRequiredTNTLockedAmount(
        uint oldMinRequiredTNTLockedAmount,
        uint newMinRequiredTNTLockedAmount
    );

    event NewPriceOracle(
        address oldPriceOracle,
        address newPriceOracle
    );

    event NewCCBurnRouter(
        address oldCCBurnRouter,
        address newCCBurnRouter
    );

    event NewExchangeConnector(
        address oldExchangeConnector,
        address newExchangeConnector
    );

    event NewTeleportDAOToken(
        address oldTDTToken,
        address newTDTToken
    ); 

    event NewTeleBTC(
        address oldTeleBTC,
        address newTeleBTC
    );   

    event NewCollateralRatio(
        uint oldCollateralRatio,
        uint newCollateralRatio
    );  

    event NewLiquidationRatio(
        uint oldLiquidationRatio,
        uint newLiquidationRatio
    );   

    // Read-only functions

    function getLockerTargetAddress(bytes calldata _lockerLockingScript) external view returns (address);

    function isLocker(bytes calldata _lockerLockingScript) external view returns (bool);

    function getNumberOfLockers() external view returns (uint);

    function getLockerLockingScript(address _lockerTargetAddress) external view returns (bytes memory);

    function isLockerActive(address _lockerTargetAddress) external view returns (bool);

    function getLockerCapacity(address _lockerTargetAddress) external view returns (uint);

    function priceOfOneUnitOfCollateralInBTC() external view returns (uint);

    function isMinter(address account) external view returns(bool);

    function isBurner(address account) external view returns(bool);

    // State-changing functions

    function pauseLocker() external;

    function unPauseLocker() external;

    function addMinter(address _account) external;

    function removeMinter(address _account) external;

    function addBurner(address _account) external;

    function removeBurner(address _account) external;

    function mint(bytes calldata _lockerLockingScript, address _receiver, uint _amount) external returns(uint);

    function burn(bytes calldata _lockerLockingScript, uint256 _amount) external returns(uint);

    function setTeleportDAOToken(address _tdtTokenAddress) external;

    function setLockerPercentageFee(uint _lockerPercentageFee) external;

    function setPriceWithDiscountRatio(uint _priceWithDiscountRatio) external;

    function setMinRequiredTDTLockedAmount(uint _minRequiredTDTLockedAmount) external;

    function setMinRequiredTNTLockedAmount(uint _minRequiredTNTLockedAmount) external;

    function setPriceOracle(address _priceOracle) external;

    function setCCBurnRouter(address _ccBurnRouter) external;

    function setExchangeConnector(address _exchangeConnector) external;

    function setTeleBTC(address _teleBTC) external;

    function setCollateralRatio(uint _collateralRatio) external;

    function setLiquidationRatio(uint _liquidationRatio) external;

    function liquidateLocker(
        address _lockerTargetAddress,
        uint _btcAmount
    ) external returns (bool);

    function addCollateral(
        address _lockerTargetAddress,
        uint _addingNativeTokenAmount
    ) external payable returns (bool);

    function removeCollateral(
        uint _removingNativeTokenAmount
    ) external payable returns (bool);

    function requestToBecomeLocker(
        bytes calldata _lockerLockingScript,
        uint _lockedTDTAmount,
        uint _lockedNativeTokenAmount,
        ScriptTypes _lockerRescueType,
        bytes calldata _lockerRescueScript
    ) external payable returns (bool);

    function revokeRequest() external returns (bool);

    function addLocker(address _lockerTargetAddress) external returns (bool);

    function requestInactivation() external returns (bool);

    function requestActivation() external returns (bool);

    function selfRemoveLocker() external returns (bool);

    function slashIdleLocker(
        address _lockerTargetAddress,
        uint _rewardAmount,
        address _rewardRecipient,
        uint _amount,
        address _recipient
    ) external returns(bool);

    function slashThiefLocker(
        address _lockerTargetAddress,
        uint _rewardAmount,
        address _rewardRecipient,
        uint _amount
    ) external returns(bool);

    function buySlashedCollateralOfLocker(
        address _lockerTargetAddress,
        uint _collateralAmount
    ) external returns (bool);

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.4;

// A library for parsing cc transfer and cc exchange requests
library RequestHelper {

    /// @notice                     Returns chain id of the request
    /// @dev                        Determines the chain that request belongs to
    /// @param _arbitraryData       Data written in Bitcoin tx
    /// @return parsedValue         The parsed value of chain id
    function parseChainId(bytes memory _arbitraryData) internal pure returns (uint8 parsedValue) {
        bytes memory slicedBytes = sliceBytes(_arbitraryData, 0, 0);
        assembly {
            parsedValue := mload(add(slicedBytes, 1))
        }
    }

    /// @notice                     Returns app id of the request
    /// @dev                        Determines the app that request belongs to (e.g. cross-chain transfer app id is 0)
    /// @param _arbitraryData       Data written in Bitcoin tx
    /// @return parsedValue         The parsed value of app id
    function parseAppId(bytes memory _arbitraryData) internal pure returns (uint16 parsedValue) {
        bytes memory slicedBytes = sliceBytes(_arbitraryData, 1, 2);
        assembly {
            parsedValue := mload(add(slicedBytes, 2))
        }
    }

    /// @notice                     Returns recipient address
    /// @dev                        Minted TeleBTC or exchanged tokens will be sent to this address
    /// @param _arbitraryData       Data written in Bitcoin tx
    /// @return parsedValue         The parsed value of recipient address
    function parseRecipientAddress(bytes memory _arbitraryData) internal pure returns (address parsedValue) {
        bytes memory slicedBytes = sliceBytes(_arbitraryData, 3, 22);
        assembly {
            parsedValue := mload(add(slicedBytes, 20))
        }
    }

    /// @notice                     Returns percentage fee (from total minted TeleBTC)
    /// @dev                        This fee goes to Teleporter who submitted the request
    /// @param _arbitraryData       Data written in Bitcoin tx
    /// @return parsedValue         The parsed value of percentage fee
    function parsePercentageFee(bytes memory _arbitraryData) internal pure returns (uint16 parsedValue) {
        bytes memory slicedBytes = sliceBytes(_arbitraryData, 23, 24);
        assembly {
            parsedValue := mload(add(slicedBytes, 2))
        }
    }

    /// @notice                     Returns speed of request
    /// @dev                        0 for normal requests, 1 for instant requests
    ///                             Instant requests are used to pay back an instant loan
    /// @param _arbitraryData       Data written in Bitcoin tx
    /// @return parsedValue         The parsed value of speed parameter
    function parseSpeed(bytes memory _arbitraryData) internal pure returns (uint8 parsedValue) {
        bytes memory slicedBytes = sliceBytes(_arbitraryData, 25, 25);
        assembly {
            parsedValue := mload(add(slicedBytes, 1))
        }
    }

    /// @notice                     Returns address of exchange token
    /// @dev                        Minted TeleBTC will be exchanged to this token
    /// @param _arbitraryData       Data written in Bitcoin tx
    /// @return parsedValue         The parsed value of exchange token
    function parseExchangeToken(bytes memory _arbitraryData) internal pure returns (address parsedValue){
        bytes memory slicedBytes = sliceBytes(_arbitraryData, 26, 45);
        assembly {
            parsedValue := mload(add(slicedBytes, 20))
        }
    }

    /// @notice                     Returns amount of output (exchange) token
    /// @dev                        If input token is fixed, outputAmount means the min expected output amount
    ///                             If output token is fixed, outputAmount is desired output amount
    /// @param _arbitraryData       Data written in Bitcoin tx
    /// @return parsedValue         The parsed value of exchange output amount
    function parseExchangeOutputAmount(bytes memory _arbitraryData) internal pure returns (uint224 parsedValue){
        bytes memory slicedBytes = sliceBytes(_arbitraryData, 46, 73);
        assembly {
            parsedValue := mload(add(slicedBytes, 28))
        }
    }

    /// @notice                     Returns deadline of executing exchange request
    /// @dev                        This value is compared to block.timestamp
    /// @param _arbitraryData       Data written in Bitcoin tx
    /// @return parsedValue         The parsed value of deadline
    function parseDeadline(bytes memory _arbitraryData) internal pure returns (uint32 parsedValue){
        bytes memory slicedBytes = sliceBytes(_arbitraryData, 74, 77);
        assembly {
            parsedValue := mload(add(slicedBytes, 4))
        }
    }

    /// @notice                     Returns true if input token is fixed
    /// @param _arbitraryData       Data written in Bitcoin tx
    /// @return parsedValue         The parsed value of is-fixed-token
    function parseIsFixedToken(bytes memory _arbitraryData) internal pure returns (uint8 parsedValue){
        bytes memory slicedBytes = sliceBytes(_arbitraryData, 78, 78);
        assembly {
            parsedValue := mload(add(slicedBytes, 1))
        }
    }

    /// @notice                 Returns a sliced bytes
    /// @param _data            Data that is sliced
    /// @param _start           Start index of slicing
    /// @param _end             End index of slicing
    /// @return _result         The result of slicing
    function sliceBytes(
        bytes memory _data,
        uint _start,
        uint _end
    ) internal pure returns (bytes memory _result) {
        bytes1 temp;
        for (uint i = _start; i < _end + 1; i++) {
            temp = _data[i];
            _result = abi.encodePacked(_result, temp);
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.4;

import "./TypedMemView.sol";
import "../types/ScriptTypesEnum.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

library BitcoinHelper {

    using SafeCast for uint96;
    using SafeCast for uint256;

    using TypedMemView for bytes;
    using TypedMemView for bytes29;

    // The target at minimum Difficulty. Also the target of the genesis block
    uint256 internal constant DIFF1_TARGET = 0xffff0000000000000000000000000000000000000000000000000000;

    uint256 internal constant RETARGET_PERIOD = 2 * 7 * 24 * 60 * 60;  // 2 weeks in seconds
    uint256 internal constant RETARGET_PERIOD_BLOCKS = 2016;  // 2 weeks in blocks

    enum BTCTypes {
        Unknown,            // 0x0
        CompactInt,         // 0x1
        ScriptSig,          // 0x2 - with length prefix
        Outpoint,           // 0x3
        TxIn,               // 0x4
        IntermediateTxIns,  // 0x5 - used in vin parsing
        Vin,                // 0x6
        ScriptPubkey,       // 0x7 - with length prefix
        PKH,                // 0x8 - the 20-byte payload digest
        WPKH,               // 0x9 - the 20-byte payload digest
        WSH,                // 0xa - the 32-byte payload digest
        SH,                 // 0xb - the 20-byte payload digest
        OpReturnPayload,    // 0xc
        TxOut,              // 0xd
        IntermediateTxOuts, // 0xe - used in vout parsing
        Vout,               // 0xf
        Header,             // 0x10
        HeaderArray,        // 0x11
        MerkleNode,         // 0x12
        MerkleStep,         // 0x13
        MerkleArray         // 0x14
    }

    /// @notice             requires `memView` to be of a specified type
    /// @dev                passes if it is the correct type, errors if not
    /// @param memView      a 29-byte view with a 5-byte type
    /// @param t            the expected type (e.g. BTCTypes.Outpoint, BTCTypes.TxIn, etc)
    modifier typeAssert(bytes29 memView, BTCTypes t) {
        memView.assertType(uint40(t));
        _;
    }

    // Revert with an error message re: non-minimal VarInts
    function revertNonMinimal(bytes29 ref) private pure returns (string memory) {
        (, uint256 g) = TypedMemView.encodeHex(ref.indexUint(0, ref.len().toUint8()));
        string memory err = string(
            abi.encodePacked(
                "Non-minimal var int. Got 0x",
                uint144(g)
            )
        );
        revert(err);
    }

    /// @notice             reads a compact int from the view at the specified index
    /// @param memView      a 29-byte view with a 5-byte type
    /// @param _index       the index
    /// @return number      returns the compact int at the specified index
    function indexCompactInt(bytes29 memView, uint256 _index) internal pure returns (uint64 number) {
        uint256 flag = memView.indexUint(_index, 1);
        if (flag <= 0xfc) {
            return flag.toUint64();
        } else if (flag == 0xfd) {
            number = memView.indexLEUint(_index + 1, 2).toUint64();
            if (compactIntLength(number) != 3) {revertNonMinimal(memView.slice(_index, 3, 0));}
        } else if (flag == 0xfe) {
            number = memView.indexLEUint(_index + 1, 4).toUint64();
            if (compactIntLength(number) != 5) {revertNonMinimal(memView.slice(_index, 5, 0));}
        } else if (flag == 0xff) {
            number = memView.indexLEUint(_index + 1, 8).toUint64();
            if (compactIntLength(number) != 9) {revertNonMinimal(memView.slice(_index, 9, 0));}
        }
    }

    /// @notice         gives the total length (in bytes) of a CompactInt-encoded number
    /// @param number   the number as uint64
    /// @return         the compact integer length as uint8
    function compactIntLength(uint64 number) private pure returns (uint8) {
        if (number <= 0xfc) {
            return 1;
        } else if (number <= 0xffff) {
            return 3;
        } else if (number <= 0xffffffff) {
            return 5;
        } else {
            return 9;
        }
    }

    /// @notice             extracts the LE txid from an outpoint
    /// @param _outpoint    the outpoint
    /// @return             the LE txid
    function txidLE(bytes29 _outpoint) internal pure typeAssert(_outpoint, BTCTypes.Outpoint) returns (bytes32) {
        return _outpoint.index(0, 32);
    }

    /// @notice                      Calculates the required transaction Id from the transaction details
    /// @dev                         Calculates the hash of transaction details two consecutive times
    /// @param _version              Version of the transaction
    /// @param _vin                  Inputs of the transaction
    /// @param _vout                 Outputs of the transaction
    /// @param _locktime             Lock time of the transaction
    /// @return                      Transaction Id of the transaction (in LE form)
    function calculateTxId(
        bytes4 _version,
        bytes memory _vin,
        bytes memory _vout,
        bytes4 _locktime
    ) internal pure returns (bytes32) {
        bytes32 inputHash1 = sha256(abi.encodePacked(_version, _vin, _vout, _locktime));
        bytes32 inputHash2 = sha256(abi.encodePacked(inputHash1));
        return inputHash2;
    }

    /// @notice                      Reverts a Bytes32 input
    /// @param _input                Bytes32 input that we want to revert
    /// @return                      Reverted bytes32
    function reverseBytes32(bytes32 _input) private pure returns (bytes32) {
        bytes memory temp;
        bytes32 result;
        for (uint i = 0; i < 32; i++) {
            temp = abi.encodePacked(temp, _input[31-i]);
        }
        assembly {
            result := mload(add(temp, 32))
        }
        return result;
    }

    /// @notice                           Parses outpoint info from an input
    /// @dev                              Reverts if vin is null
    /// @param _vin                       The vin of a Bitcoin transaction
    /// @param _index                     Index of the input that we are looking at
    /// @return _txId                     Output tx id
    /// @return _outputIndex              Output tx index
    function extractOutpoint(
        bytes memory _vin, 
        uint _index
    ) internal pure returns (bytes32 _txId, uint _outputIndex) {
        bytes29 vin = tryAsVin(_vin.ref(uint40(BTCTypes.Unknown)));
        require(!vin.isNull(), "BitcoinHelper: vin is null");
        bytes29 input = indexVin(vin, _index);
        bytes29 _outpoint = outpoint(input);
        _txId = txidLE(_outpoint);
        _outputIndex = outpointIdx(_outpoint);
    }

    /// @notice             extracts the index as an integer from the outpoint
    /// @param _outpoint    the outpoint
    /// @return             the index
    function outpointIdx(bytes29 _outpoint) internal pure typeAssert(_outpoint, BTCTypes.Outpoint) returns (uint32) {
        return _outpoint.indexLEUint(32, 4).toUint32();
    }

    /// @notice          extracts the outpoint from an input
    /// @param _input    the input
    /// @return          the outpoint as a typed memory
    function outpoint(bytes29 _input) internal pure typeAssert(_input, BTCTypes.TxIn) returns (bytes29) {
        return _input.slice(0, 36, uint40(BTCTypes.Outpoint));
    }

    /// @notice           extracts the script sig from an input
    /// @param _input     the input
    /// @return           the script sig as a typed memory
    function scriptSig(bytes29 _input) internal pure typeAssert(_input, BTCTypes.TxIn) returns (bytes29) {
        uint64 scriptLength = indexCompactInt(_input, 36);
        return _input.slice(36, compactIntLength(scriptLength) + scriptLength, uint40(BTCTypes.ScriptSig));
    }

    /// @notice         determines the length of the first input in an array of inputs
    /// @param _inputs  the vin without its length prefix
    /// @return         the input length
    function inputLength(bytes29 _inputs) private pure typeAssert(_inputs, BTCTypes.IntermediateTxIns) returns (uint256) {
        uint64 scriptLength = indexCompactInt(_inputs, 36);
        return uint256(compactIntLength(scriptLength)) + uint256(scriptLength) + 36 + 4;
    }

    /// @notice         extracts the input at a specified index
    /// @param _vin     the vin
    /// @param _index   the index of the desired input
    /// @return         the desired input
    function indexVin(bytes29 _vin, uint256 _index) internal pure typeAssert(_vin, BTCTypes.Vin) returns (bytes29) {
        uint256 _nIns = uint256(indexCompactInt(_vin, 0));
        uint256 _viewLen = _vin.len();
        require(_index < _nIns, "Vin read overrun");

        uint256 _offset = uint256(compactIntLength(uint64(_nIns)));
        bytes29 _remaining;
        for (uint256 _i = 0; _i < _index; _i += 1) {
            _remaining = _vin.postfix(_viewLen - _offset, uint40(BTCTypes.IntermediateTxIns));
            _offset += inputLength(_remaining);
        }

        _remaining = _vin.postfix(_viewLen - _offset, uint40(BTCTypes.IntermediateTxIns));
        uint256 _len = inputLength(_remaining);
        return _vin.slice(_offset, _len, uint40(BTCTypes.TxIn));
    }

    /// @notice         extracts the value from an output
    /// @param _output  the output
    /// @return         the value
    function value(bytes29 _output) internal pure typeAssert(_output, BTCTypes.TxOut) returns (uint64) {
        return _output.indexLEUint(0, 8).toUint64();
    }

    /// @notice                   Finds total outputs value
    /// @dev                      Reverts if vout is null
    /// @param _vout              The vout of a Bitcoin transaction
    /// @return _totalValue       Total vout value
    function parseOutputsTotalValue(bytes memory _vout) internal pure returns (uint64 _totalValue) {
        bytes29 voutView = tryAsVout(_vout.ref(uint40(BTCTypes.Unknown)));
        require(!voutView.isNull(), "BitcoinHelper: vout is null");
        bytes29 output;

        // Finds total number of outputs
        uint _numberOfOutputs = uint256(indexCompactInt(voutView, 0));

        for (uint index = 0; index < _numberOfOutputs; index++) {
            output = indexVout(voutView, index);
            _totalValue = _totalValue + value(output);
        }
    }

    /// @notice                           Parses the BTC amount that has been sent to 
    ///                                   a specific script in a specific output
    /// @param _vout                      The vout of a Bitcoin transaction
    /// @param _voutIndex                 Index of the output that we are looking at
    /// @param _script                    Desired recipient script
    /// @param _scriptType                Type of the script (e.g. P2PK)
    /// @return bitcoinAmount             Amount of BTC have been sent to the _script
    function parseValueFromSpecificOutputHavingScript(
        bytes memory _vout,
        uint _voutIndex,
        bytes memory _script,
        ScriptTypes _scriptType
    ) internal pure returns (uint64 bitcoinAmount) {

        bytes29 voutView = tryAsVout(_vout.ref(uint40(BTCTypes.Unknown)));
        require(!voutView.isNull(), "BitcoinHelper: vout is null");
        bytes29 output = indexVout(voutView, _voutIndex);
        bytes29 _scriptPubkey = scriptPubkey(output);

        if (_scriptType == ScriptTypes.P2PK) {
            // note: first byte is Pushdata Bytelength. 
            // note: public key length is 32.           
            bitcoinAmount = keccak256(_script) == keccak256(abi.encodePacked(_scriptPubkey.index(1, 32))) ? value(output) : 0;
        } else if (_scriptType == ScriptTypes.P2PKH) { 
            // note: first three bytes are OP_DUP, OP_HASH160, Pushdata Bytelength. 
            // note: public key hash length is 20.         
            bitcoinAmount = keccak256(_script) == keccak256(abi.encodePacked(_scriptPubkey.indexAddress(3))) ? value(output) : 0;
        } else if (_scriptType == ScriptTypes.P2SH) {
            // note: first two bytes are OP_HASH160, Pushdata Bytelength
            // note: script hash length is 20.                      
            bitcoinAmount = keccak256(_script) == keccak256(abi.encodePacked(_scriptPubkey.indexAddress(2))) ? value(output) : 0;
        } else if (_scriptType == ScriptTypes.P2WPKH) {               
            // note: first two bytes are OP_0, Pushdata Bytelength
            // note: segwit public key hash length is 20. 
            bitcoinAmount = keccak256(_script) == keccak256(abi.encodePacked(_scriptPubkey.indexAddress(2))) ? value(output) : 0;
        } else if (_scriptType == ScriptTypes.P2WSH) {
            // note: first two bytes are OP_0, Pushdata Bytelength 
            // note: segwit script hash length is 32.           
            bitcoinAmount = keccak256(_script) == keccak256(abi.encodePacked(_scriptPubkey.index(2, 32))) ? value(output) : 0;
        }
        
    }

    /// @notice                           Parses the BTC amount of a transaction
    /// @dev                              Finds the BTC amount that has been sent to the locking script
    ///                                   Returns zero if no matching locking scrip is found
    /// @param _vout                      The vout of a Bitcoin transaction
    /// @param _lockingScript             Desired locking script
    /// @return bitcoinAmount             Amount of BTC have been sent to the _lockingScript
    function parseValueHavingLockingScript(
        bytes memory _vout,
        bytes memory _lockingScript
    ) internal view returns (uint64 bitcoinAmount) {
        // Checks that vout is not null
        bytes29 voutView = tryAsVout(_vout.ref(uint40(BTCTypes.Unknown)));
        require(!voutView.isNull(), "BitcoinHelper: vout is null");

        bytes29 output;
        bytes29 _scriptPubkey;
        
        // Finds total number of outputs
        uint _numberOfOutputs = uint256(indexCompactInt(voutView, 0));

        for (uint index = 0; index < _numberOfOutputs; index++) {
            output = indexVout(voutView, index);
            _scriptPubkey = scriptPubkey(output);

            if (
                keccak256(abi.encodePacked(_scriptPubkey.clone())) == keccak256(abi.encodePacked(_lockingScript))
            ) {
                bitcoinAmount = value(output);
                // Stops searching after finding the desired locking script
                break;
            }
        }
    }

    /// @notice                           Parses the BTC amount and the op_return of a transaction
    /// @dev                              Finds the BTC amount that has been sent to the locking script
    ///                                   Assumes that payload size is less than 76 bytes
    /// @param _vout                      The vout of a Bitcoin transaction
    /// @param _lockingScript             Desired locking script
    /// @return bitcoinAmount             Amount of BTC have been sent to the _lockingScript
    /// @return arbitraryData             Opreturn  data of the transaction
    function parseValueAndDataHavingLockingScriptSmallPayload(
        bytes memory _vout,
        bytes memory _lockingScript
    ) internal view returns (uint64 bitcoinAmount, bytes memory arbitraryData) {
        // Checks that vout is not null
        bytes29 voutView = tryAsVout(_vout.ref(uint40(BTCTypes.Unknown)));
        require(!voutView.isNull(), "BitcoinHelper: vout is null");

        bytes29 output;
        bytes29 _scriptPubkey;
        bytes29 _scriptPubkeyWithLength;
        bytes29 _arbitraryData;

        // Finds total number of outputs
        uint _numberOfOutputs = uint256(indexCompactInt(voutView, 0));

        for (uint index = 0; index < _numberOfOutputs; index++) {
            output = indexVout(voutView, index);
            _scriptPubkey = scriptPubkey(output);
            _scriptPubkeyWithLength = scriptPubkeyWithLength(output);
            _arbitraryData = opReturnPayloadSmall(_scriptPubkeyWithLength);

            // Checks whether the output is an arbitarary data or not
            if(_arbitraryData == TypedMemView.NULL) {
                // Output is not an arbitrary data
                if (
                    keccak256(abi.encodePacked(_scriptPubkey.clone())) == keccak256(abi.encodePacked(_lockingScript))
                ) {
                    bitcoinAmount = value(output);
                }
            } else {
                // Returns the whole bytes array
                arbitraryData = _arbitraryData.clone();
            }
        }
    }

    /// @notice                           Parses the BTC amount and the op_return of a transaction
    /// @dev                              Finds the BTC amount that has been sent to the locking script
    ///                                   Assumes that payload size is greater than 75 bytes
    /// @param _vout                      The vout of a Bitcoin transaction
    /// @param _lockingScript             Desired locking script
    /// @return bitcoinAmount             Amount of BTC have been sent to the _lockingScript
    /// @return arbitraryData             Opreturn  data of the transaction
    function parseValueAndDataHavingLockingScriptBigPayload(
        bytes memory _vout,
        bytes memory _lockingScript
    ) internal view returns (uint64 bitcoinAmount, bytes memory arbitraryData) {
        // Checks that vout is not null
        bytes29 voutView = tryAsVout(_vout.ref(uint40(BTCTypes.Unknown)));
        require(!voutView.isNull(), "BitcoinHelper: vout is null");

        bytes29 output;
        bytes29 _scriptPubkey;
        bytes29 _scriptPubkeyWithLength;
        bytes29 _arbitraryData;

        // Finds total number of outputs
        uint _numberOfOutputs = uint256(indexCompactInt(voutView, 0));

        for (uint index = 0; index < _numberOfOutputs; index++) {
            output = indexVout(voutView, index);
            _scriptPubkey = scriptPubkey(output);
            _scriptPubkeyWithLength = scriptPubkeyWithLength(output);
            _arbitraryData = opReturnPayloadBig(_scriptPubkeyWithLength);

            // Checks whether the output is an arbitarary data or not
            if(_arbitraryData == 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) {
                // Output is not an arbitrary data
                if (
                    keccak256(abi.encodePacked(_scriptPubkey.clone())) == keccak256(abi.encodePacked(_lockingScript))
                ) {
                    bitcoinAmount = value(output);
                }
            } else {
                // Returns the whole bytes array
                arbitraryData = _arbitraryData.clone();
            }
        }
    }

    /// @notice             extracts the scriptPubkey from an output
    /// @param _output      the output
    /// @return             the scriptPubkey
    function scriptPubkey(bytes29 _output) internal pure typeAssert(_output, BTCTypes.TxOut) returns (bytes29) {
        uint64 scriptLength = indexCompactInt(_output, 8);
        return _output.slice(8 + compactIntLength(scriptLength), scriptLength, uint40(BTCTypes.ScriptPubkey));
    }

    /// @notice             extracts the scriptPubkey from an output
    /// @param _output      the output
    /// @return             the scriptPubkey
    function scriptPubkeyWithLength(bytes29 _output) internal pure typeAssert(_output, BTCTypes.TxOut) returns (bytes29) {
        uint64 scriptLength = indexCompactInt(_output, 8);
        return _output.slice(8, compactIntLength(scriptLength) + scriptLength, uint40(BTCTypes.ScriptPubkey));
    }

    /// @notice                           Parses locking script from an output
    /// @dev                              Reverts if vout is null
    /// @param _vout                      The vout of a Bitcoin transaction
    /// @param _index                     Index of the output that we are looking at
    /// @return _lockingScript            Parsed locking script
    function getLockingScript(
        bytes memory _vout, 
        uint _index
    ) internal view returns (bytes memory _lockingScript) {
        bytes29 vout = tryAsVout(_vout.ref(uint40(BTCTypes.Unknown)));
        require(!vout.isNull(), "BitcoinHelper: vout is null");
        bytes29 output = indexVout(vout, _index);
        bytes29 _lockingScriptBytes29 = scriptPubkey(output);
        _lockingScript = _lockingScriptBytes29.clone();
    }

    /// @notice                   Returns number of outputs in a vout
    /// @param _vout              The vout of a Bitcoin transaction           
    function numberOfOutputs(bytes memory _vout) internal pure returns (uint _numberOfOutputs) {
        bytes29 voutView = tryAsVout(_vout.ref(uint40(BTCTypes.Unknown)));
        _numberOfOutputs = uint256(indexCompactInt(voutView, 0));
    }

    /// @notice             determines the length of the first output in an array of outputs
    /// @param _outputs     the vout without its length prefix
    /// @return             the output length
    function outputLength(bytes29 _outputs) private pure typeAssert(_outputs, BTCTypes.IntermediateTxOuts) returns (uint256) {
        uint64 scriptLength = indexCompactInt(_outputs, 8);
        return uint256(compactIntLength(scriptLength)) + uint256(scriptLength) + 8;
    }

    /// @notice         extracts the output at a specified index
    /// @param _vout    the vout
    /// @param _index   the index of the desired output
    /// @return         the desired output
    function indexVout(bytes29 _vout, uint256 _index) internal pure typeAssert(_vout, BTCTypes.Vout) returns (bytes29) {
        uint256 _nOuts = uint256(indexCompactInt(_vout, 0));
        uint256 _viewLen = _vout.len();
        require(_index < _nOuts, "Vout read overrun");

        uint256 _offset = uint256(compactIntLength(uint64(_nOuts)));
        bytes29 _remaining;
        for (uint256 _i = 0; _i < _index; _i += 1) {
            _remaining = _vout.postfix(_viewLen - _offset, uint40(BTCTypes.IntermediateTxOuts));
            _offset += outputLength(_remaining);
        }

        _remaining = _vout.postfix(_viewLen - _offset, uint40(BTCTypes.IntermediateTxOuts));
        uint256 _len = outputLength(_remaining);
        return _vout.slice(_offset, _len, uint40(BTCTypes.TxOut));
    }

    /// @notice         extracts the Op Return Payload
    /// @dev            structure of the input is: 1 byte op return + 2 bytes indicating the length of payload + max length for op return payload is 80 bytes
    /// @param _spk     the scriptPubkey
    /// @return         the Op Return Payload (or null if not a valid Op Return output)
    function opReturnPayloadBig(bytes29 _spk) internal pure typeAssert(_spk, BTCTypes.ScriptPubkey) returns (bytes29) {
        uint64 _bodyLength = indexCompactInt(_spk, 0);
        uint64 _payloadLen = _spk.indexUint(3, 1).toUint64();
        if (_bodyLength > 83 || _bodyLength < 4 || _spk.indexUint(1, 1) != 0x6a || _spk.indexUint(3, 1) != _bodyLength - 3) {
            return TypedMemView.nullView();
        }
        return _spk.slice(4, _payloadLen, uint40(BTCTypes.OpReturnPayload));
    }

    /// @notice         extracts the Op Return Payload
    /// @dev            structure of the input is: 1 byte op return + 1 bytes indicating the length of payload + max length for op return payload is 75 bytes
    /// @param _spk     the scriptPubkey
    /// @return         the Op Return Payload (or null if not a valid Op Return output)
    function opReturnPayloadSmall(bytes29 _spk) internal pure typeAssert(_spk, BTCTypes.ScriptPubkey) returns (bytes29) {
        uint64 _bodyLength = indexCompactInt(_spk, 0);
        uint64 _payloadLen = _spk.indexUint(2, 1).toUint64();
        if (_bodyLength > 77 || _bodyLength < 4 || _spk.indexUint(1, 1) != 0x6a || _spk.indexUint(2, 1) != _bodyLength - 2) {
            return TypedMemView.nullView();
        }
        return _spk.slice(3, _payloadLen, uint40(BTCTypes.OpReturnPayload));
    }

    /// @notice     verifies the vin and converts to a typed memory
    /// @dev        will return null in error cases
    /// @param _vin the vin
    /// @return     the typed vin (or null if error)
    function tryAsVin(bytes29 _vin) internal pure typeAssert(_vin, BTCTypes.Unknown) returns (bytes29) {
        if (_vin.len() == 0) {
            return TypedMemView.nullView();
        }
        uint64 _nIns = indexCompactInt(_vin, 0);
        uint256 _viewLen = _vin.len();
        if (_nIns == 0) {
            return TypedMemView.nullView();
        }

        uint256 _offset = uint256(compactIntLength(_nIns));
        for (uint256 i = 0; i < _nIns; i++) {
            if (_offset >= _viewLen) {
                // We've reached the end, but are still trying to read more
                return TypedMemView.nullView();
            }
            bytes29 _remaining = _vin.postfix(_viewLen - _offset, uint40(BTCTypes.IntermediateTxIns));
            _offset += inputLength(_remaining);
        }
        if (_offset != _viewLen) {
            return TypedMemView.nullView();
        }
        return _vin.castTo(uint40(BTCTypes.Vin));
    }

    /// @notice         verifies the vout and converts to a typed memory
    /// @dev            will return null in error cases
    /// @param _vout    the vout
    /// @return         the typed vout (or null if error)
    function tryAsVout(bytes29 _vout) internal pure typeAssert(_vout, BTCTypes.Unknown) returns (bytes29) {
        if (_vout.len() == 0) {
            return TypedMemView.nullView();
        }
        uint64 _nOuts = indexCompactInt(_vout, 0);

        uint256 _viewLen = _vout.len();
        if (_nOuts == 0) {
            return TypedMemView.nullView();
        }

        uint256 _offset = uint256(compactIntLength(_nOuts));
        for (uint256 i = 0; i < _nOuts; i++) {
            if (_offset >= _viewLen) {
                // We've reached the end, but are still trying to read more
                return TypedMemView.nullView();
            }
            bytes29 _remaining = _vout.postfix(_viewLen - _offset, uint40(BTCTypes.IntermediateTxOuts));
            _offset += outputLength(_remaining);
        }
        if (_offset != _viewLen) {
            return TypedMemView.nullView();
        }
        return _vout.castTo(uint40(BTCTypes.Vout));
    }

    /// @notice         verifies the header and converts to a typed memory
    /// @dev            will return null in error cases
    /// @param _header  the header
    /// @return         the typed header (or null if error)
    function tryAsHeader(bytes29 _header) internal pure typeAssert(_header, BTCTypes.Unknown) returns (bytes29) {
        if (_header.len() != 80) {
            return TypedMemView.nullView();
        }
        return _header.castTo(uint40(BTCTypes.Header));
    }


    /// @notice         Index a header array.
    /// @dev            Errors on overruns
    /// @param _arr     The header array
    /// @param index    The 0-indexed location of the header to get
    /// @return         the typed header at `index`
    function indexHeaderArray(bytes29 _arr, uint256 index) internal pure typeAssert(_arr, BTCTypes.HeaderArray) returns (bytes29) {
        uint256 _start = index * 80;
        return _arr.slice(_start, 80, uint40(BTCTypes.Header));
    }


    /// @notice     verifies the header array and converts to a typed memory
    /// @dev        will return null in error cases
    /// @param _arr the header array
    /// @return     the typed header array (or null if error)
    function tryAsHeaderArray(bytes29 _arr) internal pure typeAssert(_arr, BTCTypes.Unknown) returns (bytes29) {
        if (_arr.len() % 80 != 0) {
            return TypedMemView.nullView();
        }
        return _arr.castTo(uint40(BTCTypes.HeaderArray));
    }

    /// @notice     verifies the merkle array and converts to a typed memory
    /// @dev        will return null in error cases
    /// @param _arr the merkle array
    /// @return     the typed merkle array (or null if error)
    function tryAsMerkleArray(bytes29 _arr) internal pure typeAssert(_arr, BTCTypes.Unknown) returns (bytes29) {
        if (_arr.len() % 32 != 0) {
            return TypedMemView.nullView();
        }
        return _arr.castTo(uint40(BTCTypes.MerkleArray));
    }

    /// @notice         extracts the merkle root from the header
    /// @param _header  the header
    /// @return         the merkle root
    function merkleRoot(bytes29 _header) internal pure typeAssert(_header, BTCTypes.Header) returns (bytes32) {
        return _header.index(36, 32);
    }

    /// @notice         extracts the target from the header
    /// @param _header  the header
    /// @return         the target
    function target(bytes29  _header) internal pure typeAssert(_header, BTCTypes.Header) returns (uint256) {
        uint256 _mantissa = _header.indexLEUint(72, 3);
        require(_header.indexUint(75, 1) > 2, "ViewBTC: invalid target difficulty");
        uint256 _exponent = _header.indexUint(75, 1) - 3;
        return _mantissa * (256 ** _exponent);
    }

    /// @notice         calculates the difficulty from a target
    /// @param _target  the target
    /// @return         the difficulty
    function toDiff(uint256  _target) private pure returns (uint256) {
        return DIFF1_TARGET / (_target);
    }

    /// @notice         extracts the difficulty from the header
    /// @param _header  the header
    /// @return         the difficulty
    function diff(bytes29  _header) internal pure typeAssert(_header, BTCTypes.Header) returns (uint256) {
        return toDiff(target(_header));
    }

    /// @notice         extracts the timestamp from the header
    /// @param _header  the header
    /// @return         the timestamp
    function time(bytes29  _header) internal pure typeAssert(_header, BTCTypes.Header) returns (uint32) {
        return uint32(_header.indexLEUint(68, 4));
    }

    /// @notice         extracts the parent hash from the header
    /// @param _header  the header
    /// @return         the parent hash
    function parent(bytes29 _header) internal pure typeAssert(_header, BTCTypes.Header) returns (bytes32) {
        return _header.index(4, 32);
    }

    /// @notice                     Checks validity of header chain
    /// @dev                        Compares current header parent to previous header's digest
    /// @param _header              The raw bytes header
    /// @param _prevHeaderDigest    The previous header's digest
    /// @return                     true if the connect is valid, false otherwise
    function checkParent(bytes29 _header, bytes32 _prevHeaderDigest) internal pure typeAssert(_header, BTCTypes.Header) returns (bool) {
        return parent(_header) == _prevHeaderDigest;
    }

    /// @notice                     Validates a tx inclusion in the block
    /// @dev                        `index` is not a reliable indicator of location within a block
    /// @param _txid                The txid (LE)
    /// @param _merkleRoot          The merkle root
    /// @param _intermediateNodes   The proof's intermediate nodes (digests between leaf and root)
    /// @param _index               The leaf's index in the tree (0-indexed)
    /// @return                     true if fully valid, false otherwise
    function prove( 
        bytes32 _txid,
        bytes32 _merkleRoot,
        bytes29 _intermediateNodes,
        uint _index
    ) internal view typeAssert(_intermediateNodes, BTCTypes.MerkleArray) returns (bool) {
        // Shortcut the empty-block case
        if (
            _txid == _merkleRoot &&
                _index == 0 &&
                    _intermediateNodes.len() == 0
        ) {
            return true;
        }

        return checkMerkle(_txid, _intermediateNodes, _merkleRoot, _index);
    }

    /// @notice         verifies a merkle proof
    /// @dev            leaf, proof, and root are in LE format
    /// @param _leaf    the leaf
    /// @param _proof   the proof nodes
    /// @param _root    the merkle root
    /// @param _index   the index
    /// @return         true if valid, false if otherwise
    function checkMerkle(
        bytes32 _leaf,
        bytes29 _proof,
        bytes32 _root,
        uint256 _index
    ) private view typeAssert(_proof, BTCTypes.MerkleArray) returns (bool) {
        uint256 nodes = _proof.len() / 32;
        if (nodes == 0) {
            return _leaf == _root;
        }

        uint256 _idx = _index;
        bytes32 _current = _leaf;

        for (uint i = 0; i < nodes; i++) {
            bytes32 _next = _proof.index(i * 32, 32);
            if (_idx % 2 == 1) {
                _current = merkleStep(_next, _current);
            } else {
                _current = merkleStep(_current, _next);
            }
            _idx >>= 1;
        }

        return _current == _root;
    }

    /// @notice          Concatenates and hashes two inputs for merkle proving
    /// @dev             Not recommended to call directly.
    /// @param _a        The first hash
    /// @param _b        The second hash
    /// @return digest   The double-sha256 of the concatenated hashes
    function merkleStep(bytes32 _a, bytes32 _b) private view returns (bytes32 digest) {
        assembly {
        // solium-disable-previous-line security/no-inline-assembly
            let ptr := mload(0x40)
            mstore(ptr, _a)
            mstore(add(ptr, 0x20), _b)
            pop(staticcall(gas(), 2, ptr, 0x40, ptr, 0x20)) // sha256 #1
            pop(staticcall(gas(), 2, ptr, 0x20, ptr, 0x20)) // sha256 #2
            digest := mload(ptr)
        }
    }

    /// @notice                 performs the bitcoin difficulty retarget
    /// @dev                    implements the Bitcoin algorithm precisely
    /// @param _previousTarget  the target of the previous period
    /// @param _firstTimestamp  the timestamp of the first block in the difficulty period
    /// @param _secondTimestamp the timestamp of the last block in the difficulty period
    /// @return                 the new period's target threshold
    function retargetAlgorithm(
        uint256 _previousTarget,
        uint256 _firstTimestamp,
        uint256 _secondTimestamp
    ) internal pure returns (uint256) {
        uint256 _elapsedTime = _secondTimestamp - _firstTimestamp;

        // Normalize ratio to factor of 4 if very long or very short
        if (_elapsedTime < RETARGET_PERIOD / 4) {
            _elapsedTime = RETARGET_PERIOD / 4;
        }
        if (_elapsedTime > RETARGET_PERIOD * 4) {
            _elapsedTime = RETARGET_PERIOD * 4;
        }

        /*
            NB: high targets e.g. ffff0020 can cause overflows here
                so we divide it by 256**2, then multiply by 256**2 later
                we know the target is evenly divisible by 256**2, so this isn't an issue
        */
        uint256 _adjusted = _previousTarget / 65536 * _elapsedTime;
        return _adjusted / RETARGET_PERIOD * 65536;
    }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
     * by making the `nonReentrant` function external, and make it call a
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.4;

import "../../types/DataTypes.sol";

interface ILockersStorage {
    // Read-only functions

    function TeleportDAOToken() external view returns(address);

    function teleBTC() external view returns(address);

    function ccBurnRouter() external view returns(address);

    function exchangeConnector() external view returns(address);

    function priceOracle() external view returns(address);

    function minRequiredTDTLockedAmount() external view returns(uint);

    function minRequiredTNTLockedAmount() external view returns(uint);

    function lockerPercentageFee() external view returns(uint);

    function collateralRatio() external view returns(uint);

    function liquidationRatio() external view returns(uint);

    function priceWithDiscountRatio() external view returns(uint);

    function totalNumberOfCandidates() external view returns(uint);

    function totalNumberOfLockers() external view returns(uint);
  
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.4;

import "./ScriptTypesEnum.sol";

library DataTypes {

    /// @notice                             Structure for registering lockers
    /// @dev
    /// @param lockerLockingScript          Locker redeem script
    /// @param lockerRescueType             Locker script type in case of getting BTCs back
    /// @param lockerRescueScript           Locker script in case of getting BTCs back
    /// @param TDTLockedAmount              Bond amount of locker in TDT
    /// @param nativeTokenLockedAmount      Bond amount of locker in native token of the target chain
    /// @param netMinted                    Total minted - total burnt
    /// @param slashingTeleBTCAmount        Total amount of teleBTC a locker must be slashed
    /// @param reservedNativeTokenForSlash  Total native token reserved to support slashing teleBTC
    /// @param isLocker                     Indicates that is already a locker or not
    /// @param isCandidate                  Indicates that is a candidate or not
    /// @param isScriptHash                 Shows if it's script hash
    ///                                     has enough collateral to accept more minting requests)
    struct locker {
        bytes lockerLockingScript;
        ScriptTypes lockerRescueType;
        bytes lockerRescueScript;
        uint TDTLockedAmount;
        uint nativeTokenLockedAmount;
        uint netMinted;
        uint slashingTeleBTCAmount;
        uint reservedNativeTokenForSlash;
        bool isLocker;
        bool isCandidate;
        bool isScriptHash;
    }

    struct lockersLibConstants {
        uint OneHundredPercent;
        uint HealthFactor;
        uint UpperHealthFactor;
        uint MaxLockerFee;
        uint NativeTokenDecimal;
        address NativeToken;
    }

    struct lockersLibParam {
        address teleportDAOToken;
        address teleBTC;
        address ccBurnRouter;
        address exchangeConnector;
        address priceOracle;

        uint minRequiredTDTLockedAmount;
        uint minRequiredTNTLockedAmount;
        uint lockerPercentageFee;
        uint collateralRatio;
        uint liquidationRatio;
        uint priceWithDiscountRatio;
        uint inactivationDelay;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.4;

    enum ScriptTypes {
        P2PK, // 32 bytes
        P2PKH, // 20 bytes        
        P2SH, // 20 bytes          
        P2WPKH, // 20 bytes          
        P2WSH // 32 bytes               
    }

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.4;

/** @author Summa (https://summa.one) */

/*
    Original version: https://github.com/summa-tx/memview-sol/blob/main/contracts/TypedMemView.sol
    We made few changes to the original version:
    1. Use solidity version 8 compiler
    2. Remove SafeMath library
    3. Add unchecked in line 522
*/

library TypedMemView {

    // Why does this exist?
    // the solidity `bytes memory` type has a few weaknesses.
    // 1. You can't index ranges effectively
    // 2. You can't slice without copying
    // 3. The underlying data may represent any type
    // 4. Solidity never deallocates memory, and memory costs grow
    //    superlinearly

    // By using a memory view instead of a `bytes memory` we get the following
    // advantages:
    // 1. Slices are done on the stack, by manipulating the pointer
    // 2. We can index arbitrary ranges and quickly convert them to stack types
    // 3. We can insert type info into the pointer, and typecheck at runtime

    // This makes `TypedMemView` a useful tool for efficient zero-copy
    // algorithms.

    // Why bytes29?
    // We want to avoid confusion between views, digests, and other common
    // types so we chose a large and uncommonly used odd number of bytes
    //
    // Note that while bytes are left-aligned in a word, integers and addresses
    // are right-aligned. This means when working in assembly we have to
    // account for the 3 unused bytes on the righthand side
    //
    // First 5 bytes are a type flag.
    // - ff_ffff_fffe is reserved for unknown type.
    // - ff_ffff_ffff is reserved for invalid types/errors.
    // next 12 are memory address
    // next 12 are len
    // bottom 3 bytes are empty

    // Assumptions:
    // - non-modification of memory.
    // - No Solidity updates
    // - - wrt free mem point
    // - - wrt bytes representation in memory
    // - - wrt memory addressing in general

    // Usage:
    // - create type constants
    // - use `assertType` for runtime type assertions
    // - - unfortunately we can't do this at compile time yet :(
    // - recommended: implement modifiers that perform type checking
    // - - e.g.
    // - - `uint40 constant MY_TYPE = 3;`
    // - - ` modifer onlyMyType(bytes29 myView) { myView.assertType(MY_TYPE); }`
    // - instantiate a typed view from a bytearray using `ref`
    // - use `index` to inspect the contents of the view
    // - use `slice` to create smaller views into the same memory
    // - - `slice` can increase the offset
    // - - `slice can decrease the length`
    // - - must specify the output type of `slice`
    // - - `slice` will return a null view if you try to overrun
    // - - make sure to explicitly check for this with `notNull` or `assertType`
    // - use `equal` for typed comparisons.


    // The null view
    bytes29 internal constant NULL = hex"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";
    uint256 constant LOW_12_MASK = 0xffffffffffffffffffffffff;
    uint8 constant TWELVE_BYTES = 96;

    /**
     * @notice      Returns the encoded hex character that represents the lower 4 bits of the argument.
     * @param _b    The byte
     * @return      char - The encoded hex character
     */
    function nibbleHex(uint8 _b) internal pure returns (uint8 char) {
        // This can probably be done more efficiently, but it's only in error
        // paths, so we don't really care :)
        uint8 _nibble = _b | 0xf0; // set top 4, keep bottom 4
        if (_nibble == 0xf0) {return 0x30;} // 0
        if (_nibble == 0xf1) {return 0x31;} // 1
        if (_nibble == 0xf2) {return 0x32;} // 2
        if (_nibble == 0xf3) {return 0x33;} // 3
        if (_nibble == 0xf4) {return 0x34;} // 4
        if (_nibble == 0xf5) {return 0x35;} // 5
        if (_nibble == 0xf6) {return 0x36;} // 6
        if (_nibble == 0xf7) {return 0x37;} // 7
        if (_nibble == 0xf8) {return 0x38;} // 8
        if (_nibble == 0xf9) {return 0x39;} // 9
        if (_nibble == 0xfa) {return 0x61;} // a
        if (_nibble == 0xfb) {return 0x62;} // b
        if (_nibble == 0xfc) {return 0x63;} // c
        if (_nibble == 0xfd) {return 0x64;} // d
        if (_nibble == 0xfe) {return 0x65;} // e
        if (_nibble == 0xff) {return 0x66;} // f
    }

    /**
     * @notice      Returns a uint16 containing the hex-encoded byte.
     *              `the first 8 bits of encoded is the nibbleHex of top 4 bits of _b`
     *              `the second 8 bits of encoded is the nibbleHex of lower 4 bits of _b`
     * @param _b    The byte
     * @return      encoded - The hex-encoded byte
     */
    function byteHex(uint8 _b) internal pure returns (uint16 encoded) {
        encoded |= nibbleHex(_b >> 4); // top 4 bits
        encoded <<= 8;
        encoded |= nibbleHex(_b); // lower 4 bits
    }

    /**
     * @notice      Encodes the uint256 to hex. `first` contains the encoded top 16 bytes.
     *              `second` contains the encoded lower 16 bytes.
     *
     * @param _b    The 32 bytes as uint256
     * @return      first - The top 16 bytes
     * @return      second - The bottom 16 bytes
     */
    function encodeHex(uint256 _b) internal pure returns (uint256 first, uint256 second) {
        for (uint8 i = 31; i > 15; i -= 1) {
            uint8 _byte = uint8(_b >> (i * 8));
            first |= byteHex(_byte);
            if (i != 16) {
                first <<= 16;
            }
        }

        unchecked {
            // abusing underflow here =_=
            for (uint8 i = 15; i < 255 ; i -= 1) {
                uint8 _byte = uint8(_b >> (i * 8));
                second |= byteHex(_byte);
                if (i != 0) {
                    second <<= 16;
                }
            }
        }
        
    }

    /**
     * @notice          Changes the endianness of a uint256.
     * @dev             https://graphics.stanford.edu/~seander/bithacks.html#ReverseParallel
     * @param _b        The unsigned integer to reverse
     * @return          v - The reversed value
     */
    function reverseUint256(uint256 _b) internal pure returns (uint256 v) {
        v = _b;

        // swap bytes
        v = ((v >> 8) & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) |
        ((v & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) << 8);
        // swap 2-byte long pairs
        v = ((v >> 16) & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) |
        ((v & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) << 16);
        // swap 4-byte long pairs
        v = ((v >> 32) & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) |
        ((v & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) << 32);
        // swap 8-byte long pairs
        v = ((v >> 64) & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) |
        ((v & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) << 64);
        // swap 16-byte long pairs
        v = (v >> 128) | (v << 128);
    }

    /**
     * @notice      Create a mask with the highest `_len` bits set.
     * @param _len  The length
     * @return      mask - The mask
     */
    function leftMask(uint8 _len) private pure returns (uint256 mask) {
        assembly {
        // solium-disable-previous-line security/no-inline-assembly
            mask := sar(
            sub(_len, 1),
            0x8000000000000000000000000000000000000000000000000000000000000000
            )
        }
    }

    /**
     * @notice      Return the null view.
     * @return      bytes29 - The null view
     */
    function nullView() internal pure returns (bytes29) {
        return NULL;
    }

    /**
     * @notice      Check if the view is null.
     * @return      bool - True if the view is null
     */
    function isNull(bytes29 memView) internal pure returns (bool) {
        return memView == NULL;
    }

    /**
     * @notice      Check if the view is not null.
     * @return      bool - True if the view is not null
     */
    function notNull(bytes29 memView) internal pure returns (bool) {
        return !isNull(memView);
    }

    /**
     * @notice          Check if the view is of a valid type and points to a valid location
     *                  in memory.
     * @dev             We perform this check by examining solidity's unallocated memory
     *                  pointer and ensuring that the view's upper bound is less than that.
     * @param memView   The view
     * @return          ret - True if the view is valid
     */
    function isValid(bytes29 memView) internal pure returns (bool ret) {
        if (typeOf(memView) == 0xffffffffff) {return false;}
        uint256 _end = end(memView);
        assembly {
        // solium-disable-previous-line security/no-inline-assembly
            ret := not(gt(_end, mload(0x40)))
        }
    }

    /**
     * @notice          Require that a typed memory view be valid.
     * @dev             Returns the view for easy chaining.
     * @param memView   The view
     * @return          bytes29 - The validated view
     */
    function assertValid(bytes29 memView) internal pure returns (bytes29) {
        require(isValid(memView), "Validity assertion failed");
        return memView;
    }

    /**
     * @notice          Return true if the memview is of the expected type. Otherwise false.
     * @param memView   The view
     * @param _expected The expected type
     * @return          bool - True if the memview is of the expected type
     */
    function isType(bytes29 memView, uint40 _expected) internal pure returns (bool) {
        return typeOf(memView) == _expected;
    }

    /**
     * @notice          Require that a typed memory view has a specific type.
     * @dev             Returns the view for easy chaining.
     * @param memView   The view
     * @param _expected The expected type
     * @return          bytes29 - The view with validated type
     */
    function assertType(bytes29 memView, uint40 _expected) internal pure returns (bytes29) {
        if (!isType(memView, _expected)) {
            (, uint256 g) = encodeHex(uint256(typeOf(memView)));
            (, uint256 e) = encodeHex(uint256(_expected));
            string memory err = string(
                abi.encodePacked(
                    "Type assertion failed. Got 0x",
                    uint80(g),
                    ". Expected 0x",
                    uint80(e)
                )
            );
            revert(err);
        }
        return memView;
    }

    /**
     * @notice          Return an identical view with a different type.
     * @param memView   The view
     * @param _newType  The new type
     * @return          newView - The new view with the specified type
     */
    function castTo(bytes29 memView, uint40 _newType) internal pure returns (bytes29 newView) {
        // then | in the new type
        assembly {
        // solium-disable-previous-line security/no-inline-assembly
        // shift off the top 5 bytes
            newView := or(newView, shr(40, shl(40, memView)))
            newView := or(newView, shl(216, _newType))
        }
    }

    /**
     * @notice          Unsafe raw pointer construction. This should generally not be called
     *                  directly. Prefer `ref` wherever possible.
     * @dev             Unsafe raw pointer construction. This should generally not be called
     *                  directly. Prefer `ref` wherever possible.
     * @param _type     The type
     * @param _loc      The memory address
     * @param _len      The length
     * @return          newView - The new view with the specified type, location and length
     */
    function unsafeBuildUnchecked(uint256 _type, uint256 _loc, uint256 _len) private pure returns (bytes29 newView) {
        assembly {
        // solium-disable-previous-line security/no-inline-assembly
            newView := shl(96, or(newView, _type)) // insert type
            newView := shl(96, or(newView, _loc))  // insert loc
            newView := shl(24, or(newView, _len))  // empty bottom 3 bytes
        }
    }

    /**
     * @notice          Instantiate a new memory view. This should generally not be called
     *                  directly. Prefer `ref` wherever possible.
     * @dev             Instantiate a new memory view. This should generally not be called
     *                  directly. Prefer `ref` wherever possible.
     * @param _type     The type
     * @param _loc      The memory address
     * @param _len      The length
     * @return          newView - The new view with the specified type, location and length
     */
    function build(uint256 _type, uint256 _loc, uint256 _len) internal pure returns (bytes29 newView) {
        uint256 _end = _loc + _len;
        assembly {
        // solium-disable-previous-line security/no-inline-assembly
            if gt(_end, mload(0x40)) {
                _end := 0
            }
        }
        if (_end == 0) {
            return NULL;
        }
        newView = unsafeBuildUnchecked(_type, _loc, _len);
    }

    /**
     * @notice          Instantiate a memory view from a byte array.
     * @dev             Note that due to Solidity memory representation, it is not possible to
     *                  implement a deref, as the `bytes` type stores its len in memory.
     * @param arr       The byte array
     * @param newType   The type
     * @return          bytes29 - The memory view
     */
    function ref(bytes memory arr, uint40 newType) internal pure returns (bytes29) {
        uint256 _len = arr.length;

        uint256 _loc;
        assembly {
        // solium-disable-previous-line security/no-inline-assembly
            _loc := add(arr, 0x20)  // our view is of the data, not the struct
        }

        return build(newType, _loc, _len);
    }

    /**
     * @notice          Return the associated type information.
     * @param memView   The memory view
     * @return          _type - The type associated with the view
     */
    function typeOf(bytes29 memView) internal pure returns (uint40 _type) {
        assembly {
        // solium-disable-previous-line security/no-inline-assembly
        // 216 == 256 - 40
            _type := shr(216, memView) // shift out lower (12 + 12 + 3) bytes
        }
    }

    /**
     * @notice          Optimized type comparison. Checks that the 5-byte type flag is equal.
     * @param left      The first view
     * @param right     The second view
     * @return          bool - True if the 5-byte type flag is equal
     */
    function sameType(bytes29 left, bytes29 right) internal pure returns (bool) {
        // XOR the inputs to check their difference
        return (left ^ right) >> (2 * TWELVE_BYTES) == 0;
    }

    /**
     * @notice          Return the memory address of the underlying bytes.
     * @param memView   The view
     * @return          _loc - The memory address
     */
    function loc(bytes29 memView) internal pure returns (uint96 _loc) {
        uint256 _mask = LOW_12_MASK;  // assembly can't use globals
        assembly {
        // solium-disable-previous-line security/no-inline-assembly
        // 120 bits = 12 bytes (the encoded loc) + 3 bytes (empty low space)
            _loc := and(shr(120, memView), _mask)
        }
    }

    /**
     * @notice          The number of memory words this memory view occupies, rounded up.
     * @param memView   The view
     * @return          uint256 - The number of memory words
     */
    function words(bytes29 memView) internal pure returns (uint256) {
        return (uint256(len(memView)) + 32) / 32;
    }

    /**
     * @notice          The in-memory footprint of a fresh copy of the view.
     * @param memView   The view
     * @return          uint256 - The in-memory footprint of a fresh copy of the view.
     */
    function footprint(bytes29 memView) internal pure returns (uint256) {
        return words(memView) * 32;
    }

    /**
     * @notice          The number of bytes of the view.
     * @param memView   The view
     * @return          _len - The length of the view
     */
    function len(bytes29 memView) internal pure returns (uint96 _len) {
        uint256 _mask = LOW_12_MASK;  // assembly can't use globals
        assembly {
        // solium-disable-previous-line security/no-inline-assembly
            _len := and(shr(24, memView), _mask)
        }
    }

    /**
     * @notice          Returns the endpoint of `memView`.
     * @param memView   The view
     * @return          uint256 - The endpoint of `memView`
     */
    function end(bytes29 memView) internal pure returns (uint256) {
        return loc(memView) + len(memView);
    }

    /**
     * @notice          Safe slicing without memory modification.
     * @param memView   The view
     * @param _index    The start index
     * @param _len      The length
     * @param newType   The new type
     * @return          bytes29 - The new view
     */
    function slice(bytes29 memView, uint256 _index, uint256 _len, uint40 newType) internal pure returns (bytes29) {
        uint256 _loc = loc(memView);

        // Ensure it doesn't overrun the view
        if (_loc + _index + _len > end(memView)) {
            return NULL;
        }

        _loc = _loc + _index;
        return build(newType, _loc, _len);
    }

    /**
     * @notice          Shortcut to `slice`. Gets a view representing the first `_len` bytes.
     * @param memView   The view
     * @param _len      The length
     * @param newType   The new type
     * @return          bytes29 - The new view
     */
    function prefix(bytes29 memView, uint256 _len, uint40 newType) internal pure returns (bytes29) {
        return slice(memView, 0, _len, newType);
    }

    /**
     * @notice          Shortcut to `slice`. Gets a view representing the last `_len` bytes.
     * @param memView   The view
     * @param _len      The length
     * @param newType   The new type
     * @return          bytes29 - The new view
     */
    function postfix(bytes29 memView, uint256 _len, uint40 newType) internal pure returns (bytes29) {
        return slice(memView, uint256(len(memView)) - _len, _len, newType);
    }

    /**
     * @notice          Construct an error message for an indexing overrun.
     * @param _loc      The memory address
     * @param _len      The length
     * @param _index    The index
     * @param _slice    The slice where the overrun occurred
     * @return          err - The err
     */
    function indexErrOverrun(
        uint256 _loc,
        uint256 _len,
        uint256 _index,
        uint256 _slice
    ) internal pure returns (string memory err) {
        (, uint256 a) = encodeHex(_loc);
        (, uint256 b) = encodeHex(_len);
        (, uint256 c) = encodeHex(_index);
        (, uint256 d) = encodeHex(_slice);
        err = string(
            abi.encodePacked(
                "TypedMemView/index - Overran the view. Slice is at 0x",
                uint48(a),
                " with length 0x",
                uint48(b),
                ". Attempted to index at offset 0x",
                uint48(c),
                " with length 0x",
                uint48(d),
                "."
            )
        );
    }

    /**
     * @notice          Load up to 32 bytes from the view onto the stack.
     * @dev             Returns a bytes32 with only the `_bytes` highest bytes set.
     *                  This can be immediately cast to a smaller fixed-length byte array.
     *                  To automatically cast to an integer, use `indexUint`.
     * @param memView   The view
     * @param _index    The index
     * @param _bytes    The bytes length
     * @return          result - The 32 byte result
     */
    function index(bytes29 memView, uint256 _index, uint8 _bytes) internal pure returns (bytes32 result) {
        if (_bytes == 0) {return bytes32(0);}
        if (_index + _bytes > len(memView)) {
            revert(indexErrOverrun(loc(memView), len(memView), _index, uint256(_bytes)));
        }
        require(_bytes <= 32, "TypedMemView/index - Attempted to index more than 32 bytes");

        unchecked {
            uint8 bitLength = _bytes * 8;
            uint256 _loc = loc(memView);
            uint256 _mask = leftMask(bitLength);
            assembly {
                // solium-disable-previous-line security/no-inline-assembly
                result := and(mload(add(_loc, _index)), _mask)
            }   
        }

    }

    /**
     * @notice          Parse an unsigned integer from the view at `_index`.
     * @dev             Requires that the view has >= `_bytes` bytes following that index.
     * @param memView   The view
     * @param _index    The index
     * @param _bytes    The bytes length
     * @return          result - The unsigned integer
     */
    function indexUint(bytes29 memView, uint256 _index, uint8 _bytes) internal pure returns (uint256 result) {
        return uint256(index(memView, _index, _bytes)) >> ((32 - _bytes) * 8);
    }

    /**
     * @notice          Parse an unsigned integer from LE bytes.
     * @param memView   The view
     * @param _index    The index
     * @param _bytes    The bytes length
     * @return          result - The unsigned integer
     */
    function indexLEUint(bytes29 memView, uint256 _index, uint8 _bytes) internal pure returns (uint256 result) {
        return reverseUint256(uint256(index(memView, _index, _bytes)));
    }

    /**
     * @notice          Parse an address from the view at `_index`. Requires that the view have >= 20 bytes
     *                  following that index.
     * @param memView   The view
     * @param _index    The index
     * @return          address - The address
     */
    function indexAddress(bytes29 memView, uint256 _index) internal pure returns (address) {
        return address(uint160(indexUint(memView, _index, 20)));
    }

    /**
     * @notice          Return the keccak256 hash of the underlying memory
     * @param memView   The view
     * @return          digest - The keccak256 hash of the underlying memory
     */
    function keccak(bytes29 memView) internal pure returns (bytes32 digest) {
        uint256 _loc = loc(memView);
        uint256 _len = len(memView);
        assembly {
        // solium-disable-previous-line security/no-inline-assembly
            digest := keccak256(_loc, _len)
        }
    }

    /**
     * @notice          Return the sha2 digest of the underlying memory.
     * @dev             We explicitly deallocate memory afterwards.
     * @param memView   The view
     * @return          digest - The sha2 hash of the underlying memory
     */
    function sha2(bytes29 memView) internal view returns (bytes32 digest) {
        uint256 _loc = loc(memView);
        uint256 _len = len(memView);
        assembly {
        // solium-disable-previous-line security/no-inline-assembly
            let ptr := mload(0x40)
            pop(staticcall(gas(), 2, _loc, _len, ptr, 0x20)) // sha2 #1
            digest := mload(ptr)
        }
    }

    /**
     * @notice          Implements bitcoin's hash160 (rmd160(sha2()))
     * @param memView   The pre-image
     * @return          digest - the Digest
     */
    function hash160(bytes29 memView) internal view returns (bytes20 digest) {
        uint256 _loc = loc(memView);
        uint256 _len = len(memView);
        assembly {
        // solium-disable-previous-line security/no-inline-assembly
            let ptr := mload(0x40)
            pop(staticcall(gas(), 2, _loc, _len, ptr, 0x20)) // sha2
            pop(staticcall(gas(), 3, ptr, 0x20, ptr, 0x20)) // rmd160
            digest := mload(add(ptr, 0xc)) // return value is 0-prefixed.
        }
    }

    /**
     * @notice          Implements bitcoin's hash256 (double sha2)
     * @param memView   A view of the preimage
     * @return          digest - the Digest
     */
    function hash256(bytes29 memView) internal view returns (bytes32 digest) {
        uint256 _loc = loc(memView);
        uint256 _len = len(memView);
        assembly {
        // solium-disable-previous-line security/no-inline-assembly
            let ptr := mload(0x40)
            pop(staticcall(gas(), 2, _loc, _len, ptr, 0x20)) // sha2 #1
            pop(staticcall(gas(), 2, ptr, 0x20, ptr, 0x20)) // sha2 #2
            digest := mload(ptr)
        }
    }

    /**
     * @notice          Return true if the underlying memory is equal. Else false.
     * @param left      The first view
     * @param right     The second view
     * @return          bool - True if the underlying memory is equal
     */
    function untypedEqual(bytes29 left, bytes29 right) internal pure returns (bool) {
        return (loc(left) == loc(right) && len(left) == len(right)) || keccak(left) == keccak(right);
    }

    /**
     * @notice          Return false if the underlying memory is equal. Else true.
     * @param left      The first view
     * @param right     The second view
     * @return          bool - False if the underlying memory is equal
     */
    function untypedNotEqual(bytes29 left, bytes29 right) internal pure returns (bool) {
        return !untypedEqual(left, right);
    }

    /**
     * @notice          Compares type equality.
     * @dev             Shortcuts if the pointers are identical, otherwise compares type and digest.
     * @param left      The first view
     * @param right     The second view
     * @return          bool - True if the types are the same
     */
    function equal(bytes29 left, bytes29 right) internal pure returns (bool) {
        return left == right || (typeOf(left) == typeOf(right) && keccak(left) == keccak(right));
    }

    /**
     * @notice          Compares type inequality.
     * @dev             Shortcuts if the pointers are identical, otherwise compares type and digest.
     * @param left      The first view
     * @param right     The second view
     * @return          bool - True if the types are not the same
     */
    function notEqual(bytes29 left, bytes29 right) internal pure returns (bool) {
        return !equal(left, right);
    }

    /**
     * @notice          Copy the view to a location, return an unsafe memory reference
     * @dev             Super Dangerous direct memory access.
     *
     *                  This reference can be overwritten if anything else modifies memory (!!!).
     *                  As such it MUST be consumed IMMEDIATELY.
     *                  This function is private to prevent unsafe usage by callers.
     * @param memView   The view
     * @param _newLoc   The new location
     * @return          written - the unsafe memory reference
     */
    function unsafeCopyTo(bytes29 memView, uint256 _newLoc) private view returns (bytes29 written) {
        require(notNull(memView), "TypedMemView/copyTo - Null pointer deref");
        require(isValid(memView), "TypedMemView/copyTo - Invalid pointer deref");
        uint256 _len = len(memView);
        uint256 _oldLoc = loc(memView);

        uint256 ptr;
        assembly {
        // solium-disable-previous-line security/no-inline-assembly
            ptr := mload(0x40)
        // revert if we're writing in occupied memory
            if gt(ptr, _newLoc) {
                revert(0x60, 0x20) // empty revert message
            }

        // use the identity precompile to copy
        // guaranteed not to fail, so pop the success
            pop(staticcall(gas(), 4, _oldLoc, _len, _newLoc, _len))
        }

        written = unsafeBuildUnchecked(typeOf(memView), _newLoc, _len);
    }

    /**
     * @notice          Copies the referenced memory to a new loc in memory, returning a `bytes` pointing to
     *                  the new memory
     * @dev             Shortcuts if the pointers are identical, otherwise compares type and digest.
     * @param memView   The view
     * @return          ret - The view pointing to the new memory
     */
    function clone(bytes29 memView) internal view returns (bytes memory ret) {
        uint256 ptr;
        uint256 _len = len(memView);
        assembly {
        // solium-disable-previous-line security/no-inline-assembly
            ptr := mload(0x40) // load unused memory pointer
            ret := ptr
        }
        unsafeCopyTo(memView, ptr + 0x20);
        assembly {
        // solium-disable-previous-line security/no-inline-assembly
            mstore(0x40, add(add(ptr, _len), 0x20)) // write new unused pointer
            mstore(ptr, _len) // write len of new array (in bytes)
        }
    }

    /**
     * @notice          Join the views in memory, return an unsafe reference to the memory.
     * @dev             Super Dangerous direct memory access.
     *
     *                  This reference can be overwritten if anything else modifies memory (!!!).
     *                  As such it MUST be consumed IMMEDIATELY.
     *                  This function is private to prevent unsafe usage by callers.
     * @param memViews  The views
     * @return          unsafeView - The conjoined view pointing to the new memory
     */
    function unsafeJoin(bytes29[] memory memViews, uint256 _location) private view returns (bytes29 unsafeView) {
        assembly {
        // solium-disable-previous-line security/no-inline-assembly
            let ptr := mload(0x40)
        // revert if we're writing in occupied memory
            if gt(ptr, _location) {
                revert(0x60, 0x20) // empty revert message
            }
        }

        uint256 _offset = 0;
        for (uint256 i = 0; i < memViews.length; i ++) {
            bytes29 memView = memViews[i];
            unsafeCopyTo(memView, _location + _offset);
            _offset += len(memView);
        }
        unsafeView = unsafeBuildUnchecked(0, _location, _offset);
    }

    /**
     * @notice          Produce the keccak256 digest of the concatenated contents of multiple views.
     * @param memViews  The views
     * @return          bytes32 - The keccak256 digest
     */
    function joinKeccak(bytes29[] memory memViews) internal view returns (bytes32) {
        uint256 ptr;
        assembly {
        // solium-disable-previous-line security/no-inline-assembly
            ptr := mload(0x40) // load unused memory pointer
        }
        return keccak(unsafeJoin(memViews, ptr));
    }

    /**
     * @notice          Produce the sha256 digest of the concatenated contents of multiple views.
     * @param memViews  The views
     * @return          bytes32 - The sha256 digest
     */
    function joinSha2(bytes29[] memory memViews) internal view returns (bytes32) {
        uint256 ptr;
        assembly {
        // solium-disable-previous-line security/no-inline-assembly
            ptr := mload(0x40) // load unused memory pointer
        }
        return sha2(unsafeJoin(memViews, ptr));
    }

    /**
     * @notice          copies all views, joins them into a new bytearray.
     * @param memViews  The views
     * @return          ret - The new byte array
     */
    function join(bytes29[] memory memViews) internal view returns (bytes memory ret) {
        uint256 ptr;
        assembly {
        // solium-disable-previous-line security/no-inline-assembly
            ptr := mload(0x40) // load unused memory pointer
        }

        bytes29 _newView = unsafeJoin(memViews, ptr + 0x20);
        uint256 _written = len(_newView);
        uint256 _footprint = footprint(_newView);

        assembly {
        // solium-disable-previous-line security/no-inline-assembly
        // store the legnth
            mstore(ptr, _written)
        // new pointer is old + 0x20 + the footprint of the body
            mstore(0x40, add(add(ptr, _footprint), 0x20))
            ret := ptr
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT

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