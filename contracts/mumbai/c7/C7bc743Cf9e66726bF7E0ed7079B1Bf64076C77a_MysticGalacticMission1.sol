// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./util/Util.sol";
import "./PriceHandler.sol";
import "./RefundHandler.sol";
import "./MissionEventsHandler.sol";
// import "truffle/console.sol";


/**
 *
 * @title Mystic Galactic Mission 1
 * @author Mystic Galactic, LLC
 * @notice This contract represents a limited edition collection of non-fungible tokens (NFTs) for the Mystic Galactic Mission 1.
 * Users can mint NFTs for pre-purchased bottles, subject to daily limits. The contract also allows for the administration of
 * refunds, event date management, and pricing. It inherits from OpenZeppelin's ERC721, Ownable, Pausable, AccessControl, and
 * ReentrancyGuard contracts.
 * The contract is divided into several parts:
 * Token minting: Allows users to mint NFTs by paying the required amount and adhering to daily limits.
 * Refunds: Allows for the preparation and distribution of refunds to minters based on their token balance.
 * Security functions: Provides role-based access control with pause and unpause functionality.
 * Launch and recovery event management: Allows admins to set launch and recovery event dates.
 * Pricing: Enables admins to set the NFT price in USD and provides functions to query the price in both USD and MATIC.
 */
contract MysticGalacticMission1 is ERC721, Ownable, Pausable, AccessControl, ReentrancyGuard {
    using Util for uint256;
    using Util for address;
    using SafeMath for uint256;
    using SafeMath for uint16;

    string  public constant DEVELOPER = "Mystic Galactic, LLC";
    bytes32 private constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    uint16  public supply;
    uint16  public immutable initialSupply;
    uint16  public immutable supplyPerDay;

    uint16  public   supplyUsed;
    uint256 private  lastMintedDay;
    uint16  public   supplyMintedToday;

    string private baseURI;

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not owner or admin");
        _;
    }

    // Token Mint Information
    struct TokenMintResult {
        uint256 tokenId;
        string  uri;
    }


    // Sub Contracts
    PriceHandler private priceHandler;
    RefundHandler private refundHandler;
//    MissionEventsHandler private missionEventsHandler;

    struct SupplyConfig {
        uint16 supply;
        uint16 supplyPerDay;
    }


    /**
     * @dev Initializes the contract by setting the initial base URI, price in Wei, maximum tokens,
     * and maximum tokens per day. Inherits from ERC721, Ownable, Pausable, and AccessControlEnumerable.
     * Sets up the DEFAULT_ADMIN_ROLE and ADMIN_ROLE for the contract creator and pauses the contract.
     * @param _baseURI The initial base URI for the token metadata.
     * @param _supplyConfig Specifies the supply and the supplyPerDay
     */
    constructor(
        string memory        _baseURI,
        SupplyConfig memory   _supplyConfig
    ) ERC721("Mystic Galactic Mission 1", "MYGM1") {
        require(bytes(_baseURI).length > 1, "Base URI cannot be empty");

        // Start at the begining
        supplyUsed = 0;
        baseURI = _baseURI;

        // Set initial supply
        initialSupply = _supplyConfig.supply;
        supply = _supplyConfig.supply;
        supplyPerDay = _supplyConfig.supplyPerDay;

        require(supply > 0, "Supply provided must be greater than 0: ");
        require((supply - supplyPerDay) > 0, "Supply Per Day must be less then the Supply");


        // Setup roles
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // Pause the contract initially
        _pause();
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721) returns (bool) {
        return AccessControl.supportsInterface(interfaceId) || ERC721.supportsInterface(interfaceId);
    }


    /**
     * @dev Set the additional logic handlers
     * @param _priceHandlerAddr The price handler
     * @param _refundHandlerAddr The refund handler
     */
//    function setHandlers (address _priceHandlerAddr, address _refundHandlerAddr, address _missionEventsHandlerAddr ) external onlyAdmin {
    function setHandlers (address _priceHandlerAddr, address _refundHandlerAddr ) external onlyAdmin {
        // Set the handler
        priceHandler   = PriceHandler(_priceHandlerAddr);
        refundHandler  = RefundHandler(_refundHandlerAddr);
//        missionEventsHandler = MissionEventsHandler(_missionEventsHandlerAddr);
    }

    /**
     * @dev Mints new tokens for pre-purchased bottles
     * @param bottles The number of tokens to mint.
     *
     * This function allows users to mint new tokens by sending the
     * required amount. It ensures that the daily minting limit
     * is not exceeded and refunds any excess funds sent by the user.
     */
    function mintNFT(uint16 bottles) public payable nonReentrant whenNotPaused {

        require(supply > 0, "Maximum number of pre-sales reached");

        uint256 today = block.timestamp / 1 days;
        if (today > lastMintedDay) {
            supplyMintedToday = 0;
            lastMintedDay = today;
        }
        require(supplyMintedToday < supplyPerDay, "Maximum number of daily pre-sales reached");
        require(bottles <= (supplyPerDay - supplyMintedToday), "Daily supply not enough for requested mint");

        uint256 currentPrice = priceHandler.price();
        uint256 totalPrice = currentPrice * bottles;

        require(msg.value >= totalPrice, "Funds sent is less than the price of token");

        // Refund any excess sent
        int256 refundAmount = int256(msg.value) - int256(totalPrice);
        if (refundAmount > 0) {
            payable(msg.sender).transfer(uint256(refundAmount));
        }

        for (uint256 i = 0; i < bottles; i++) {
            uint256 tokenId = uint256(supplyUsed); // uint256(supplyUsed);
            _safeMint(msg.sender, tokenId);

            emit TokenMinted(msg.sender, currentPrice, tokenId, tokenURI(tokenId));

            uint16 newSupplyUsed = uint16(supplyUsed.add(1));
            supplyUsed = newSupplyUsed > initialSupply ? initialSupply : newSupplyUsed;

            supply = supply -1;

            uint16 newTokensMintedToday = uint16(supplyMintedToday.add(1));
            supplyMintedToday = newTokensMintedToday > supplyPerDay ? supplyPerDay : newTokensMintedToday;

            refundHandler.addMinterForRefund(tokenId, msg.sender, owner());
        }

        payable(owner()).transfer(totalPrice);
    }

    event TokenMinted(address indexed to, uint256 paymentReceived, uint256 tokenId, string tokenURI);


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, "/nft/", tokenId.toString())) : "";
    }

    /**
     *  @dev Update Metadata -  DEVONLY should be replaced by ENS but we probably still need to emit the event
     *  @param _baseURI new base URI for metadata change
     */
    function updateMetaData( string memory _baseURI ) external onlyAdmin {
        baseURI = _baseURI;
        if ( supplyUsed != 0 ) {
            emit BatchMetadataUpdate(0, supplyUsed - 1);
        }
    }
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    // Refunding

    /**
     * @dev Prepares refunds for all token minters based on their token balance. Passing msg.value funds the contract.
     * This function calculates the refund amount per token and stores the total refund amount for each minter in a mapping.
     * It requires the contract to have sufficient balance to cover all refunds.
     */
    function prepareRefunds() public payable onlyAdmin {
        require(msg.value > 0, "Incorrect funding amount");
        refundHandler.prepareRefunds(address(this).balance, msg.sender);
    }

    /**
     * @dev Sends the specified number of refunds to the corresponding minters.
     * This function transfers the refund amount to each minter, burns their NFT, and emits a RefundProcessed event.
     * It should be called after prepareRefunds() to actually send the refunds.
     * @param numRefunds The number of refunds to send.
     */
    function sendRefund(uint16 numRefunds) external onlyAdmin {
        refundHandler.sendRefunds(numRefunds, msg.sender);
    }


    // Security Functions

    function ensureAdmin( address _caller ) external view {
        require(hasRole(ADMIN_ROLE, _caller), "Caller is not owner or admin");
    }

    /**
     * @dev Pause the contract
     */
    function pause() public onlyAdmin {
        _pause();
    }

    /**
     * @dev Unpause the contract
     */
    function unpause() public onlyAdmin {
        _unpause();
    }

    /**
     * @dev Transfers ownership of the contract to a new address. Can only be called by the current owner.
     * @param newOwner Address of the new owner.
     */
    function transferOwnership(address newOwner) public override onlyOwner {
        require(newOwner != address(0), "New owner cannot be the zero address");
        // Call the original transferOwnership function from Ownable
        super.transferOwnership(newOwner);
        // Transfer additional ADMIN_ROLE to the new owner
        grantRole(ADMIN_ROLE, newOwner);
        revokeRole(ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev override pause to emit paused event
     */
    function _pause() internal virtual override {
        super._pause();
        emit ContractPaused(msg.sender);
    }

    event ContractPaused(address by);


    /**
     * @dev override unpause to emit unpaused event
     */
    function _unpause() internal virtual override {
        super._unpause();
        emit ContractUnpaused(msg.sender);
    }

    event ContractUnpaused(address by);

    /**
     * @dev Grants the ADMIN_ROLE to the specified account. Can only be called by the contract owner.
     * Emits an AdminRoleGranted event upon successful assignment.
     * @param account The address of the account to be granted the ADMIN_ROLE.
     */
    function grantAdminRole(address account) external onlyOwner {
        grantRole(ADMIN_ROLE, account);
        emit AdminRoleGranted(account);
    }

    event AdminRoleGranted(address account);

    /**
     * @dev Revokes the ADMIN_ROLE from the specified account. Can only be called by the contract owner.
     * Emits an AdminRoleRevoked event upon successful removal.
     * @param account The address of the account to have the ADMIN_ROLE revoked.
     */
    function revokeAdminRole(address account) public onlyOwner {
        revokeRole(ADMIN_ROLE, account);
        emit AdminRoleRevoked(account);
    }

    event AdminRoleRevoked(address account);



    /**
     * @dev Prepares refunds for all token minters based on their token balance. Passing msg.value funds the contract.
     * This function calculates the refund amount per token and stores the total refund amount for each minter in a mapping.
     * It requires the contract to have sufficient balance to cover all refunds.
     */

    function renounceRole(bytes32 role, address account) public virtual override {
        super.renounceRole(role, account);
        emit AdminRoleRenounced(role, account);
    }

    event AdminRoleRenounced(bytes32 indexed role, address indexed account);


//    // Launch & Recovery Events management
//
//    /**
//     * @dev Sets a new launch event date as a Unix timestamp. Can only be called by the owner or an admin.
//     * The new launch event date must be greater than the current block timestamp and the recovery event date.
//     * @param _launchDate The new launch event date as a Unix timestamp.
//     */
//    function setLaunchDate(uint256 _launchDate) external onlyAdmin {
//        missionEventsHandler.setLaunchDate(_launchDate, msg.sender);
//        emit LaunchDateSet(_launchDate);
//    }
//    event LaunchDateSet(uint256 launchDate);
//
//    /**
//     * @dev Sets a new recovery event date as a Unix timestamp. Can only be called by the owner or an admin.
//     * The new recovery event date must be greater than the current block timestamp and the launch event date.
//     * @param _recoveryDate The new recovery event date as a Unix timestamp.
//     */
//    function setRecoveryDate(uint256 _recoveryDate) external onlyAdmin {
//        missionEventsHandler.setRecoveryDate(_recoveryDate, msg.sender);
//        emit RecoveryDateSet(_recoveryDate);
//    }
//    event RecoveryDateSet(uint256 recoveryDate);
//
//    /**
//     * @dev Returns the launch event date as a Unix timestamp.
//     * @return The launch date.
//     */
//    function launchDate() external view returns (uint256) {
//        return missionEventsHandler.launchDate();
//    }
//
//    /**
//     * @dev Returns the recovery event date as a Unix timestamp.
//     * @return The recovery date.
//     */
//    function recoveryDate() external view returns (uint256) {
//        return missionEventsHandler.recoveryDate();
//    }

    // Pricing

    /**
     * @dev Sets a new price for minting a token in USD. The USD price should be 8 decimal places
     * @param _usdPrice The new price in usdPrice.
     */
    function setPrice(uint256 _usdPrice) external onlyAdmin {
        priceHandler.setPrice(_usdPrice, msg.sender);
        emit PriceUpdated(_usdPrice);
    }
    event PriceUpdated(uint256 newPrice);

    /**
     * @dev Sets the feed for the price conversion in getPrice()
     * @param _priceFeedAddress The address of the price feed oracle
     */
    function setPriceFeed( address _priceFeedAddress ) external onlyAdmin {
        priceHandler.setPriceFeed(_priceFeedAddress, msg.sender);
    }

    /**
     * @dev Returns the current price for minting a token in MATIC.
     * @return The current price in Matic.
     */
    function price() external view returns (uint256) {
        return priceHandler.price();
    }


    /**
     * @dev Returns the current price for minting a token in USD.
     * @return The current price in USD.
     */
    function priceInUSD() external view returns (uint256) {
        return priceHandler.priceInUSD();
    }


}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
    address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

    function _sendLogPayload(bytes memory payload) private view {
        address consoleAddress = CONSOLE_ADDRESS;
        assembly {
            let argumentsLength := mload(payload)
            let argumentsOffset := add(payload, 32)
            pop(staticcall(gas(), consoleAddress, argumentsOffset, argumentsLength, 0, 0))
        }
    }

    function log() internal view {
        _sendLogPayload(abi.encodeWithSignature("log()"));
    }

    function logAddress(address value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address)", value));
    }

    function logBool(bool value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", value));
    }

    function logString(string memory value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string)", value));
    }

    function logUint256(uint256 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256)", value));
    }

    function logUint(uint256 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256)", value));
    }

    function logBytes(bytes memory value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes)", value));
    }

    function logInt256(int256 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(int256)", value));
    }

    function logInt(int256 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(int256)", value));
    }

    function logBytes1(bytes1 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes1)", value));
    }

    function logBytes2(bytes2 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes2)", value));
    }

    function logBytes3(bytes3 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes3)", value));
    }

    function logBytes4(bytes4 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes4)", value));
    }

    function logBytes5(bytes5 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes5)", value));
    }

    function logBytes6(bytes6 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes6)", value));
    }

    function logBytes7(bytes7 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes7)", value));
    }

    function logBytes8(bytes8 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes8)", value));
    }

    function logBytes9(bytes9 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes9)", value));
    }

    function logBytes10(bytes10 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes10)", value));
    }

    function logBytes11(bytes11 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes11)", value));
    }

    function logBytes12(bytes12 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes12)", value));
    }

    function logBytes13(bytes13 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes13)", value));
    }

    function logBytes14(bytes14 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes14)", value));
    }

    function logBytes15(bytes15 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes15)", value));
    }

    function logBytes16(bytes16 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes16)", value));
    }

    function logBytes17(bytes17 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes17)", value));
    }

    function logBytes18(bytes18 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes18)", value));
    }

    function logBytes19(bytes19 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes19)", value));
    }

    function logBytes20(bytes20 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes20)", value));
    }

    function logBytes21(bytes21 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes21)", value));
    }

    function logBytes22(bytes22 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes22)", value));
    }

    function logBytes23(bytes23 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes23)", value));
    }

    function logBytes24(bytes24 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes24)", value));
    }

    function logBytes25(bytes25 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes25)", value));
    }

    function logBytes26(bytes26 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes26)", value));
    }

    function logBytes27(bytes27 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes27)", value));
    }

    function logBytes28(bytes28 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes28)", value));
    }

    function logBytes29(bytes29 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes29)", value));
    }

    function logBytes30(bytes30 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes30)", value));
    }

    function logBytes31(bytes31 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes31)", value));
    }

    function logBytes32(bytes32 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes32)", value));
    }

    function log(address value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address)", value));
    }

    function log(bool value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", value));
    }

    function log(string memory value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string)", value));
    }

    function log(uint256 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256)", value));
    }

    function log(address value1, address value2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address)", value1, value2));
    }

    function log(address value1, bool value2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool)", value1, value2));
    }

    function log(address value1, string memory value2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string)", value1, value2));
    }

    function log(address value1, uint256 value2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256)", value1, value2));
    }

    function log(bool value1, address value2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address)", value1, value2));
    }

    function log(bool value1, bool value2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool)", value1, value2));
    }

    function log(bool value1, string memory value2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string)", value1, value2));
    }

    function log(bool value1, uint256 value2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", value1, value2));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, address value2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address)", value1, value2));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, bool value2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool)", value1, value2));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, string memory value2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string)", value1, value2));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, uint256 value2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256)", value1, value2));
    }

    function log(uint256 value1, address value2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address)", value1, value2));
    }

    function log(uint256 value1, bool value2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", value1, value2));
    }

    function log(uint256 value1, string memory value2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string)", value1, value2));
    }

    function log(uint256 value1, uint256 value2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", value1, value2));
    }

    function log(address value1, address value2, address value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address)", value1, value2, value3));
    }

    function log(address value1, address value2, bool value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", value1, value2, value3));
    }

    function log(address value1, address value2, string memory value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string)", value1, value2, value3));
    }

    function log(address value1, address value2, uint256 value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", value1, value2, value3));
    }

    function log(address value1, bool value2, address value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", value1, value2, value3));
    }

    function log(address value1, bool value2, bool value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", value1, value2, value3));
    }

    function log(address value1, bool value2, string memory value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", value1, value2, value3));
    }

    function log(address value1, bool value2, uint256 value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", value1, value2, value3));
    }

    function log(address value1, string memory value2, address value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address)", value1, value2, value3));
    }

    function log(address value1, string memory value2, bool value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", value1, value2, value3));
    }

    function log(address value1, string memory value2, string memory value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string)", value1, value2, value3));
    }

    function log(address value1, string memory value2, uint256 value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", value1, value2, value3));
    }

    function log(address value1, uint256 value2, address value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", value1, value2, value3));
    }

    function log(address value1, uint256 value2, bool value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", value1, value2, value3));
    }

    function log(address value1, uint256 value2, string memory value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", value1, value2, value3));
    }

    function log(address value1, uint256 value2, uint256 value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", value1, value2, value3));
    }

    function log(bool value1, address value2, address value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", value1, value2, value3));
    }

    function log(bool value1, address value2, bool value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", value1, value2, value3));
    }

    function log(bool value1, address value2, string memory value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", value1, value2, value3));
    }

    function log(bool value1, address value2, uint256 value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", value1, value2, value3));
    }

    function log(bool value1, bool value2, address value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", value1, value2, value3));
    }

    function log(bool value1, bool value2, bool value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", value1, value2, value3));
    }

    function log(bool value1, bool value2, string memory value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", value1, value2, value3));
    }

    function log(bool value1, bool value2, uint256 value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", value1, value2, value3));
    }

    function log(bool value1, string memory value2, address value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", value1, value2, value3));
    }

    function log(bool value1, string memory value2, bool value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", value1, value2, value3));
    }

    function log(bool value1, string memory value2, string memory value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", value1, value2, value3));
    }

    function log(bool value1, string memory value2, uint256 value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", value1, value2, value3));
    }

    function log(bool value1, uint256 value2, address value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", value1, value2, value3));
    }

    function log(bool value1, uint256 value2, bool value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", value1, value2, value3));
    }

    function log(bool value1, uint256 value2, string memory value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", value1, value2, value3));
    }

    function log(bool value1, uint256 value2, uint256 value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", value1, value2, value3));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, address value2, address value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address)", value1, value2, value3));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, address value2, bool value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", value1, value2, value3));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, address value2, string memory value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string)", value1, value2, value3));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, address value2, uint256 value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", value1, value2, value3));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, bool value2, address value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", value1, value2, value3));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, bool value2, bool value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", value1, value2, value3));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, bool value2, string memory value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", value1, value2, value3));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, bool value2, uint256 value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", value1, value2, value3));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, string memory value2, address value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address)", value1, value2, value3));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, string memory value2, bool value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", value1, value2, value3));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, string memory value2, string memory value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string)", value1, value2, value3));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, string memory value2, uint256 value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", value1, value2, value3));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, uint256 value2, address value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", value1, value2, value3));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, uint256 value2, bool value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", value1, value2, value3));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, uint256 value2, string memory value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", value1, value2, value3));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, uint256 value2, uint256 value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", value1, value2, value3));
    }

    function log(uint256 value1, address value2, address value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", value1, value2, value3));
    }

    function log(uint256 value1, address value2, bool value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", value1, value2, value3));
    }

    function log(uint256 value1, address value2, string memory value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", value1, value2, value3));
    }

    function log(uint256 value1, address value2, uint256 value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", value1, value2, value3));
    }

    function log(uint256 value1, bool value2, address value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", value1, value2, value3));
    }

    function log(uint256 value1, bool value2, bool value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", value1, value2, value3));
    }

    function log(uint256 value1, bool value2, string memory value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", value1, value2, value3));
    }

    function log(uint256 value1, bool value2, uint256 value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", value1, value2, value3));
    }

    function log(uint256 value1, string memory value2, address value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", value1, value2, value3));
    }

    function log(uint256 value1, string memory value2, bool value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", value1, value2, value3));
    }

    function log(uint256 value1, string memory value2, string memory value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", value1, value2, value3));
    }

    function log(uint256 value1, string memory value2, uint256 value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", value1, value2, value3));
    }

    function log(uint256 value1, uint256 value2, address value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", value1, value2, value3));
    }

    function log(uint256 value1, uint256 value2, bool value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", value1, value2, value3));
    }

    function log(uint256 value1, uint256 value2, string memory value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", value1, value2, value3));
    }

    function log(uint256 value1, uint256 value2, uint256 value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", value1, value2, value3));
    }

    function log(address value1, address value2, address value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", value1, value2, value3, value4));
    }

    function log(address value1, address value2, address value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", value1, value2, value3, value4));
    }

    function log(address value1, address value2, address value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", value1, value2, value3, value4));
    }

    function log(address value1, address value2, address value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", value1, value2, value3, value4));
    }

    function log(address value1, address value2, bool value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", value1, value2, value3, value4));
    }

    function log(address value1, address value2, bool value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", value1, value2, value3, value4));
    }

    function log(address value1, address value2, bool value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", value1, value2, value3, value4));
    }

    function log(address value1, address value2, bool value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", value1, value2, value3, value4));
    }

    function log(address value1, address value2, string memory value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", value1, value2, value3, value4));
    }

    function log(address value1, address value2, string memory value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", value1, value2, value3, value4));
    }

    function log(address value1, address value2, string memory value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", value1, value2, value3, value4));
    }

    function log(address value1, address value2, string memory value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", value1, value2, value3, value4));
    }

    function log(address value1, address value2, uint256 value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", value1, value2, value3, value4));
    }

    function log(address value1, address value2, uint256 value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", value1, value2, value3, value4));
    }

    function log(address value1, address value2, uint256 value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", value1, value2, value3, value4));
    }

    function log(address value1, address value2, uint256 value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", value1, value2, value3, value4));
    }

    function log(address value1, bool value2, address value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", value1, value2, value3, value4));
    }

    function log(address value1, bool value2, address value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", value1, value2, value3, value4));
    }

    function log(address value1, bool value2, address value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", value1, value2, value3, value4));
    }

    function log(address value1, bool value2, address value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", value1, value2, value3, value4));
    }

    function log(address value1, bool value2, bool value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", value1, value2, value3, value4));
    }

    function log(address value1, bool value2, bool value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", value1, value2, value3, value4));
    }

    function log(address value1, bool value2, bool value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", value1, value2, value3, value4));
    }

    function log(address value1, bool value2, bool value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", value1, value2, value3, value4));
    }

    function log(address value1, bool value2, string memory value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", value1, value2, value3, value4));
    }

    function log(address value1, bool value2, string memory value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", value1, value2, value3, value4));
    }

    function log(address value1, bool value2, string memory value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", value1, value2, value3, value4));
    }

    function log(address value1, bool value2, string memory value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", value1, value2, value3, value4));
    }

    function log(address value1, bool value2, uint256 value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", value1, value2, value3, value4));
    }

    function log(address value1, bool value2, uint256 value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", value1, value2, value3, value4));
    }

    function log(address value1, bool value2, uint256 value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", value1, value2, value3, value4));
    }

    function log(address value1, bool value2, uint256 value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", value1, value2, value3, value4));
    }

    function log(address value1, string memory value2, address value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", value1, value2, value3, value4));
    }

    function log(address value1, string memory value2, address value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", value1, value2, value3, value4));
    }

    function log(address value1, string memory value2, address value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", value1, value2, value3, value4));
    }

    function log(address value1, string memory value2, address value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", value1, value2, value3, value4));
    }

    function log(address value1, string memory value2, bool value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", value1, value2, value3, value4));
    }

    function log(address value1, string memory value2, bool value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", value1, value2, value3, value4));
    }

    function log(address value1, string memory value2, bool value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", value1, value2, value3, value4));
    }

    function log(address value1, string memory value2, bool value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", value1, value2, value3, value4));
    }

    function log(address value1, string memory value2, string memory value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", value1, value2, value3, value4));
    }

    function log(address value1, string memory value2, string memory value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", value1, value2, value3, value4));
    }

    function log(address value1, string memory value2, string memory value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", value1, value2, value3, value4));
    }

    function log(address value1, string memory value2, string memory value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", value1, value2, value3, value4));
    }

    function log(address value1, string memory value2, uint256 value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", value1, value2, value3, value4));
    }

    function log(address value1, string memory value2, uint256 value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", value1, value2, value3, value4));
    }

    function log(address value1, string memory value2, uint256 value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", value1, value2, value3, value4));
    }

    function log(address value1, string memory value2, uint256 value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", value1, value2, value3, value4));
    }

    function log(address value1, uint256 value2, address value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", value1, value2, value3, value4));
    }

    function log(address value1, uint256 value2, address value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", value1, value2, value3, value4));
    }

    function log(address value1, uint256 value2, address value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", value1, value2, value3, value4));
    }

    function log(address value1, uint256 value2, address value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", value1, value2, value3, value4));
    }

    function log(address value1, uint256 value2, bool value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", value1, value2, value3, value4));
    }

    function log(address value1, uint256 value2, bool value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", value1, value2, value3, value4));
    }

    function log(address value1, uint256 value2, bool value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", value1, value2, value3, value4));
    }

    function log(address value1, uint256 value2, bool value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", value1, value2, value3, value4));
    }

    function log(address value1, uint256 value2, string memory value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", value1, value2, value3, value4));
    }

    function log(address value1, uint256 value2, string memory value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", value1, value2, value3, value4));
    }

    function log(address value1, uint256 value2, string memory value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", value1, value2, value3, value4));
    }

    function log(address value1, uint256 value2, string memory value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", value1, value2, value3, value4));
    }

    function log(address value1, uint256 value2, uint256 value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", value1, value2, value3, value4));
    }

    function log(address value1, uint256 value2, uint256 value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", value1, value2, value3, value4));
    }

    function log(address value1, uint256 value2, uint256 value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", value1, value2, value3, value4));
    }

    function log(address value1, uint256 value2, uint256 value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", value1, value2, value3, value4));
    }

    function log(bool value1, address value2, address value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", value1, value2, value3, value4));
    }

    function log(bool value1, address value2, address value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", value1, value2, value3, value4));
    }

    function log(bool value1, address value2, address value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", value1, value2, value3, value4));
    }

    function log(bool value1, address value2, address value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", value1, value2, value3, value4));
    }

    function log(bool value1, address value2, bool value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", value1, value2, value3, value4));
    }

    function log(bool value1, address value2, bool value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", value1, value2, value3, value4));
    }

    function log(bool value1, address value2, bool value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", value1, value2, value3, value4));
    }

    function log(bool value1, address value2, bool value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", value1, value2, value3, value4));
    }

    function log(bool value1, address value2, string memory value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", value1, value2, value3, value4));
    }

    function log(bool value1, address value2, string memory value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", value1, value2, value3, value4));
    }

    function log(bool value1, address value2, string memory value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", value1, value2, value3, value4));
    }

    function log(bool value1, address value2, string memory value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", value1, value2, value3, value4));
    }

    function log(bool value1, address value2, uint256 value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", value1, value2, value3, value4));
    }

    function log(bool value1, address value2, uint256 value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", value1, value2, value3, value4));
    }

    function log(bool value1, address value2, uint256 value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", value1, value2, value3, value4));
    }

    function log(bool value1, address value2, uint256 value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", value1, value2, value3, value4));
    }

    function log(bool value1, bool value2, address value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", value1, value2, value3, value4));
    }

    function log(bool value1, bool value2, address value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", value1, value2, value3, value4));
    }

    function log(bool value1, bool value2, address value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", value1, value2, value3, value4));
    }

    function log(bool value1, bool value2, address value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", value1, value2, value3, value4));
    }

    function log(bool value1, bool value2, bool value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", value1, value2, value3, value4));
    }

    function log(bool value1, bool value2, bool value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", value1, value2, value3, value4));
    }

    function log(bool value1, bool value2, bool value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", value1, value2, value3, value4));
    }

    function log(bool value1, bool value2, bool value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", value1, value2, value3, value4));
    }

    function log(bool value1, bool value2, string memory value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", value1, value2, value3, value4));
    }

    function log(bool value1, bool value2, string memory value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", value1, value2, value3, value4));
    }

    function log(bool value1, bool value2, string memory value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", value1, value2, value3, value4));
    }

    function log(bool value1, bool value2, string memory value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", value1, value2, value3, value4));
    }

    function log(bool value1, bool value2, uint256 value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", value1, value2, value3, value4));
    }

    function log(bool value1, bool value2, uint256 value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", value1, value2, value3, value4));
    }

    function log(bool value1, bool value2, uint256 value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", value1, value2, value3, value4));
    }

    function log(bool value1, bool value2, uint256 value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", value1, value2, value3, value4));
    }

    function log(bool value1, string memory value2, address value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", value1, value2, value3, value4));
    }

    function log(bool value1, string memory value2, address value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", value1, value2, value3, value4));
    }

    function log(bool value1, string memory value2, address value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", value1, value2, value3, value4));
    }

    function log(bool value1, string memory value2, address value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", value1, value2, value3, value4));
    }

    function log(bool value1, string memory value2, bool value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", value1, value2, value3, value4));
    }

    function log(bool value1, string memory value2, bool value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", value1, value2, value3, value4));
    }

    function log(bool value1, string memory value2, bool value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", value1, value2, value3, value4));
    }

    function log(bool value1, string memory value2, bool value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", value1, value2, value3, value4));
    }

    function log(bool value1, string memory value2, string memory value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", value1, value2, value3, value4));
    }

    function log(bool value1, string memory value2, string memory value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", value1, value2, value3, value4));
    }

    function log(bool value1, string memory value2, string memory value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", value1, value2, value3, value4));
    }

    function log(bool value1, string memory value2, string memory value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", value1, value2, value3, value4));
    }

    function log(bool value1, string memory value2, uint256 value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", value1, value2, value3, value4));
    }

    function log(bool value1, string memory value2, uint256 value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", value1, value2, value3, value4));
    }

    function log(bool value1, string memory value2, uint256 value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", value1, value2, value3, value4));
    }

    function log(bool value1, string memory value2, uint256 value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", value1, value2, value3, value4));
    }

    function log(bool value1, uint256 value2, address value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", value1, value2, value3, value4));
    }

    function log(bool value1, uint256 value2, address value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", value1, value2, value3, value4));
    }

    function log(bool value1, uint256 value2, address value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", value1, value2, value3, value4));
    }

    function log(bool value1, uint256 value2, address value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", value1, value2, value3, value4));
    }

    function log(bool value1, uint256 value2, bool value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", value1, value2, value3, value4));
    }

    function log(bool value1, uint256 value2, bool value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", value1, value2, value3, value4));
    }

    function log(bool value1, uint256 value2, bool value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", value1, value2, value3, value4));
    }

    function log(bool value1, uint256 value2, bool value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", value1, value2, value3, value4));
    }

    function log(bool value1, uint256 value2, string memory value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", value1, value2, value3, value4));
    }

    function log(bool value1, uint256 value2, string memory value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", value1, value2, value3, value4));
    }

    function log(bool value1, uint256 value2, string memory value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", value1, value2, value3, value4));
    }

    function log(bool value1, uint256 value2, string memory value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", value1, value2, value3, value4));
    }

    function log(bool value1, uint256 value2, uint256 value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", value1, value2, value3, value4));
    }

    function log(bool value1, uint256 value2, uint256 value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", value1, value2, value3, value4));
    }

    function log(bool value1, uint256 value2, uint256 value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", value1, value2, value3, value4));
    }

    function log(bool value1, uint256 value2, uint256 value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, address value2, address value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, address value2, address value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, address value2, address value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, address value2, address value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, address value2, bool value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, address value2, bool value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, address value2, bool value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, address value2, bool value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, address value2, string memory value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, address value2, string memory value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, address value2, string memory value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, address value2, string memory value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, address value2, uint256 value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, address value2, uint256 value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, address value2, uint256 value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, address value2, uint256 value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, bool value2, address value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, bool value2, address value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, bool value2, address value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, bool value2, address value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, bool value2, bool value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, bool value2, bool value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, bool value2, bool value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, bool value2, bool value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, bool value2, string memory value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, bool value2, string memory value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, bool value2, string memory value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, bool value2, string memory value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, bool value2, uint256 value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, bool value2, uint256 value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, bool value2, uint256 value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, bool value2, uint256 value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, string memory value2, address value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, string memory value2, address value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, string memory value2, address value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, string memory value2, address value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, string memory value2, bool value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, string memory value2, bool value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, string memory value2, bool value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, string memory value2, bool value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, string memory value2, string memory value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, string memory value2, string memory value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, string memory value2, string memory value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, string memory value2, string memory value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, string memory value2, uint256 value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, string memory value2, uint256 value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, string memory value2, uint256 value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, string memory value2, uint256 value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, uint256 value2, address value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, uint256 value2, address value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, uint256 value2, address value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, uint256 value2, address value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, uint256 value2, bool value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, uint256 value2, bool value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, uint256 value2, bool value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, uint256 value2, bool value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, uint256 value2, string memory value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, uint256 value2, string memory value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, uint256 value2, string memory value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, uint256 value2, string memory value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, uint256 value2, uint256 value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, uint256 value2, uint256 value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, uint256 value2, uint256 value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, uint256 value2, uint256 value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", value1, value2, value3, value4));
    }

    function log(uint256 value1, address value2, address value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", value1, value2, value3, value4));
    }

    function log(uint256 value1, address value2, address value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", value1, value2, value3, value4));
    }

    function log(uint256 value1, address value2, address value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", value1, value2, value3, value4));
    }

    function log(uint256 value1, address value2, address value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", value1, value2, value3, value4));
    }

    function log(uint256 value1, address value2, bool value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", value1, value2, value3, value4));
    }

    function log(uint256 value1, address value2, bool value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", value1, value2, value3, value4));
    }

    function log(uint256 value1, address value2, bool value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", value1, value2, value3, value4));
    }

    function log(uint256 value1, address value2, bool value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", value1, value2, value3, value4));
    }

    function log(uint256 value1, address value2, string memory value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", value1, value2, value3, value4));
    }

    function log(uint256 value1, address value2, string memory value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", value1, value2, value3, value4));
    }

    function log(uint256 value1, address value2, string memory value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", value1, value2, value3, value4));
    }

    function log(uint256 value1, address value2, string memory value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", value1, value2, value3, value4));
    }

    function log(uint256 value1, address value2, uint256 value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", value1, value2, value3, value4));
    }

    function log(uint256 value1, address value2, uint256 value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", value1, value2, value3, value4));
    }

    function log(uint256 value1, address value2, uint256 value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", value1, value2, value3, value4));
    }

    function log(uint256 value1, address value2, uint256 value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", value1, value2, value3, value4));
    }

    function log(uint256 value1, bool value2, address value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", value1, value2, value3, value4));
    }

    function log(uint256 value1, bool value2, address value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", value1, value2, value3, value4));
    }

    function log(uint256 value1, bool value2, address value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", value1, value2, value3, value4));
    }

    function log(uint256 value1, bool value2, address value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", value1, value2, value3, value4));
    }

    function log(uint256 value1, bool value2, bool value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", value1, value2, value3, value4));
    }

    function log(uint256 value1, bool value2, bool value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", value1, value2, value3, value4));
    }

    function log(uint256 value1, bool value2, bool value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", value1, value2, value3, value4));
    }

    function log(uint256 value1, bool value2, bool value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", value1, value2, value3, value4));
    }

    function log(uint256 value1, bool value2, string memory value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", value1, value2, value3, value4));
    }

    function log(uint256 value1, bool value2, string memory value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", value1, value2, value3, value4));
    }

    function log(uint256 value1, bool value2, string memory value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", value1, value2, value3, value4));
    }

    function log(uint256 value1, bool value2, string memory value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", value1, value2, value3, value4));
    }

    function log(uint256 value1, bool value2, uint256 value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", value1, value2, value3, value4));
    }

    function log(uint256 value1, bool value2, uint256 value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", value1, value2, value3, value4));
    }

    function log(uint256 value1, bool value2, uint256 value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", value1, value2, value3, value4));
    }

    function log(uint256 value1, bool value2, uint256 value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", value1, value2, value3, value4));
    }

    function log(uint256 value1, string memory value2, address value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", value1, value2, value3, value4));
    }

    function log(uint256 value1, string memory value2, address value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", value1, value2, value3, value4));
    }

    function log(uint256 value1, string memory value2, address value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", value1, value2, value3, value4));
    }

    function log(uint256 value1, string memory value2, address value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", value1, value2, value3, value4));
    }

    function log(uint256 value1, string memory value2, bool value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", value1, value2, value3, value4));
    }

    function log(uint256 value1, string memory value2, bool value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", value1, value2, value3, value4));
    }

    function log(uint256 value1, string memory value2, bool value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", value1, value2, value3, value4));
    }

    function log(uint256 value1, string memory value2, bool value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", value1, value2, value3, value4));
    }

    function log(uint256 value1, string memory value2, string memory value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", value1, value2, value3, value4));
    }

    function log(uint256 value1, string memory value2, string memory value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", value1, value2, value3, value4));
    }

    function log(uint256 value1, string memory value2, string memory value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", value1, value2, value3, value4));
    }

    function log(uint256 value1, string memory value2, string memory value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", value1, value2, value3, value4));
    }

    function log(uint256 value1, string memory value2, uint256 value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", value1, value2, value3, value4));
    }

    function log(uint256 value1, string memory value2, uint256 value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", value1, value2, value3, value4));
    }

    function log(uint256 value1, string memory value2, uint256 value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", value1, value2, value3, value4));
    }

    function log(uint256 value1, string memory value2, uint256 value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", value1, value2, value3, value4));
    }

    function log(uint256 value1, uint256 value2, address value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", value1, value2, value3, value4));
    }

    function log(uint256 value1, uint256 value2, address value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", value1, value2, value3, value4));
    }

    function log(uint256 value1, uint256 value2, address value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", value1, value2, value3, value4));
    }

    function log(uint256 value1, uint256 value2, address value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", value1, value2, value3, value4));
    }

    function log(uint256 value1, uint256 value2, bool value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", value1, value2, value3, value4));
    }

    function log(uint256 value1, uint256 value2, bool value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", value1, value2, value3, value4));
    }

    function log(uint256 value1, uint256 value2, bool value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", value1, value2, value3, value4));
    }

    function log(uint256 value1, uint256 value2, bool value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", value1, value2, value3, value4));
    }

    function log(uint256 value1, uint256 value2, string memory value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", value1, value2, value3, value4));
    }

    function log(uint256 value1, uint256 value2, string memory value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", value1, value2, value3, value4));
    }

    function log(uint256 value1, uint256 value2, string memory value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", value1, value2, value3, value4));
    }

    function log(uint256 value1, uint256 value2, string memory value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", value1, value2, value3, value4));
    }

    function log(uint256 value1, uint256 value2, uint256 value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", value1, value2, value3, value4));
    }

    function log(uint256 value1, uint256 value2, uint256 value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", value1, value2, value3, value4));
    }

    function log(uint256 value1, uint256 value2, uint256 value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", value1, value2, value3, value4));
    }

    function log(uint256 value1, uint256 value2, uint256 value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", value1, value2, value3, value4));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


library Util {

    function uintToString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function toString(address account) internal pure returns(string memory) {
        return toString(abi.encodePacked(account));
    }

    function toString(uint256 value) internal pure returns(string memory) {
        return uintToString(value);
    }

    function toString(int256 value) internal pure returns(string memory) {
        return toString(abi.encodePacked(value));
    }

    function toString(bytes32 value) internal pure returns(string memory) {
        return toString(abi.encodePacked(value));
    }

    function toString(bytes memory data) internal pure returns(string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < data.length; i++) {
            str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IMainContract {
    function ownerOf(uint256 tokenId) external view returns (address);
    function balanceOf(address owner) external view returns (uint256);
    function burn(uint256 tokenId) external;
    function supplyUsed() external view returns (uint16);
    function ensureAdmin(address _caller) external view;
}

contract RefundHandler {
    using SafeMath for uint256;
    using SafeMath for uint16;

    uint16 private totalRefunds;

    IMainContract private mainContract;

    mapping(uint256 => address) private tokenMinters;
    mapping(address => uint256) private minterRefundAmounts;

    event RefundProcessed(address minter, uint256 amount);


    constructor(address _mainContractAddress) {
        mainContract = IMainContract(_mainContractAddress);
    }

    function onlyAdmin(address _caller) internal view {
        mainContract.ensureAdmin(_caller);
    }

    /**
     * @dev Prepares refunds for all token minters based on their token balance. Passing msg.value funds the contract.
     * This function calculates the refund amount per token and stores the total refund amount for each minter in a mapping.
     * It requires the contract to have sufficient balance to cover all refunds.
     */
    function prepareRefunds(uint256 balance, address _sender ) external {
        onlyAdmin(_sender);
        uint16 supplyUsed = mainContract.supplyUsed();
        uint256 refundAmountPerToken = balance / supplyUsed;

        for (uint256 i = 0; i < supplyUsed; i++) {
            address minter = mainContract.ownerOf(i);
            uint256 minterTokenCount = mainContract.balanceOf(minter);
            minterRefundAmounts[minter] = minterRefundAmounts[minter].add(refundAmountPerToken.mul(minterTokenCount));
        }
    }

    /**
     * @dev Sends the specified number of refunds to the corresponding minters.
     * This function transfers the refund amount to each minter, burns their NFT, and emits a RefundProcessed event.
     * It should be called after prepareRefunds() to actually send the refunds.
     * @param numRefunds The number of refunds to send.
     */
    function sendRefunds(uint16 numRefunds, address _sender) external {
        onlyAdmin(_sender);
        require(numRefunds > 0, "Incorrect refund amount must be greater than zero");

        uint16 supplyUsed = mainContract.supplyUsed();

        uint16 maxRefunds = uint16(supplyUsed.sub(totalRefunds));
        if (numRefunds > maxRefunds) {
            numRefunds = maxRefunds;
        }

        uint16 upTo = uint16(totalRefunds.add(numRefunds));
        for (uint256 i = totalRefunds; i < upTo; i++) {
            address minter = tokenMinters[i];
            uint256 refundAmount = minterRefundAmounts[minter];

            if (refundAmount > 0) {
                minterRefundAmounts[minter] = 0;
                payable(minter).transfer(refundAmount);

                // Burn the NFT
                mainContract.burn(i);

                emit RefundProcessed(minter, refundAmount);
            }
        }

        totalRefunds = uint16(totalRefunds.add(numRefunds));
    }


    /**
     * @dev Adds a minter for potential refund
     * @param tokenId The the minted token they would be reunder
     * @param minter The address of the minter
     */
    function addMinterForRefund(uint256 tokenId, address minter, address _sender) external {
        onlyAdmin(_sender);
        tokenMinters[tokenId] = minter;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "truffle/console.sol";
import "./util/Util.sol";

interface IAdminValidator {
    function ensureAdmin(address _caller) external view;
}

contract PriceHandler {
    using Util for address;

    AggregatorV3Interface private priceFeed;
    IAdminValidator private validator;

    uint256 private usdPrice;


    constructor(address _validatorAddr, address _priceFeedAddress, uint256 _usdPrice ) {
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
        usdPrice = _usdPrice;
        validator = IAdminValidator(_validatorAddr);
    }

    function onlyAdmin(address _caller) internal view {
        validator.ensureAdmin(_caller);
    }

//    modifier onlyAdmin() {
//        // Make sure the caller is from the contract
//        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not owner or admin");
//        _;
//    }
//
//    function onlyAdmin (address sender) {
//        require(hasRole(ADMIN_ROLE, sender), "Caller is not owner or admin");
//    }

    /**
     * @dev Sets a new price for minting a token in USD. The USD price should be 8 decimal places
     * @param _usdPrice The new price in usdPrice.
     */
    function setPrice(uint256 _usdPrice, address _sender ) external {
        onlyAdmin(_sender);
        usdPrice = _usdPrice;
    }

    /**
     * @dev Sets the feed for the price conversion in getPrice()
     * @param _priceFeedAddress The address of the price feed oracle
     */
    function setPriceFeed( address _priceFeedAddress, address _sender ) external {
        onlyAdmin(_sender);
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
    }

    /**
     * @dev Returns the current price for minting a token in MATIC.
     * @return The current price in Matic.
     */
    function price() external view returns (uint256) {
        uint256 priceInMATIC = convertUSDtoMATIC(usdPrice, 8);
        // console.log("current price is ", Util.toString(priceInMATIC));
        return priceInMATIC;
    }

    /**
     * @dev Returns the current price for minting a token in USD.
     * @return The current price in USD.
     */
    function priceInUSD() external view returns (uint256) {
        return usdPrice;
    }

    /**
     * Converts the given USD amount to MATIC using the current price from Chainlink
     * @param usdAmount amount of USD to convert
     * @param usdDecimals decimals of USD amount
     */
    function convertUSDtoMATIC(uint256 usdAmount, uint8 usdDecimals) internal view returns (uint256) {
        (, int rate, , ,) = priceFeed.latestRoundData();
        uint8 rateDecimals = priceFeed.decimals();

        require(rate > 0, "Price feed error");

        uint256 scaleFactor = 10 ** (rateDecimals + usdDecimals - 8);
        uint256 maticAmount = usdAmount * scaleFactor / uint256(rate);

        // Round up the last two decimals
        uint256 roundedMaticAmount = maticAmount + 99;
        roundedMaticAmount = roundedMaticAmount / 100 * 100;

        return roundedMaticAmount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IAdminValidator1 {
    function ensureAdmin(address _caller) external view;
}

contract MissionEventsHandler {
    IAdminValidator1 private validator;

    uint256 private _launchDate;
    uint256 private _recoveryDate;


    constructor(address _validatorAddr) {
        validator = IAdminValidator1(_validatorAddr);
    }


    function onlyAdmin(address _caller) internal view {
        validator.ensureAdmin(_caller);
    }

    /**
     * @dev Sets a new launch event date as a Unix timestamp. Can only be called by the owner or an admin.
     * The new launch event date must be greater than the current block timestamp and the recovery event date.
     * @param __launchDate The new launch event date as a Unix timestamp.
     */
    function setLaunchDate(uint256 __launchDate, address _sender) external {
        onlyAdmin(_sender);

        require(__launchDate > block.timestamp, "Launch event date must be in the future");
        if (_recoveryDate != 0) {
            require(__launchDate < _recoveryDate, "Launch event date must be less than the recovery event date");
        }
        _launchDate = __launchDate;
    }

    /**
     * @dev Sets a new recovery event date as a Unix timestamp. Can only be called by the owner or an admin.
     * The new recovery event date must be greater than the current block timestamp and the launch event date.
     * @param __recoveryDate The new recovery event date as a Unix timestamp.
     */
    function setRecoveryDate(uint256 __recoveryDate, address _sender) external {
        onlyAdmin(_sender);

        require(__recoveryDate > block.timestamp, "Recovery event date must be in the future");
        if (_launchDate != 0) {
            require(__recoveryDate > _launchDate, "Recovery event date must be greater than the launch event date");
        }
        _recoveryDate = __recoveryDate;
    }

    /**
     * @dev Returns the launch event date as a Unix timestamp.
     * @return The launch event date.
     */

    function launchDate() external view returns (uint256) {
        return _launchDate;
    }

    /**
     * @dev Returns the recovery event date as a Unix timestamp.
     * @return The recovery event date.
     */
    function recoveryDate() external view returns (uint256) {
        return _recoveryDate;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.2) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}

    /**
     * @dev Unsafe write access to the balances, used by extensions that "mint" tokens using an {ownerOf} override.
     *
     * WARNING: Anyone calling this MUST ensure that the balances remain consistent with the ownership. The invariant
     * being that for any address `a` the value returned by `balanceOf(a)` must be equal to the number of tokens such
     * that `ownerOf(tokenId)` is `a`.
     */
    // solhint-disable-next-line func-name-mixedcase
    function __unsafe_increaseBalance(address account, uint256 amount) internal {
        _balances[account] += amount;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

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