// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IERC721 {
    function mint(address to, uint256 tokenId) external;
}

contract PacificRimPaymentContract is Ownable, AccessControl/*, ReentrancyGuard*/ {
    using SafeMath for uint256;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    IERC721 private NFT; 

    uint256 private ethAmount; 
    uint256 private cappedSupply; 
    uint256 private mintedSupply; 
    uint256 private preSaleTime; 
    uint256 private preSaleDuration; 
    uint256 private preSaleMintLimit; 
    uint256 private whitelistSaleTime; 
    uint256 private whitelistSaleDuration; 
    uint256 private whitelistSaleMintLimit; 
    uint256 private publicSaleTime; 
    uint256 private publicSaleDuration; 
    uint256 private preSalePerTransactionMintLimit;
    uint256 private whitelistSalePerTransactionMintLimit;
    uint256 private publicSalePerTransactionMintLimit;

    address payable private withdrawAddress; // address who can withdraw eth
    address private signatureAddress;

    mapping(address => uint256) private mintBalancePreSale; // in case of presale mint and whitlist mint
    mapping(address => uint256) private mintBalanceWhitelistSale;
    mapping(bytes => bool) private signatures;

    event preSaleMint(address indexed to, uint256[] indexed tokenId, uint256 indexed price);
    event whitelistSaleMint(address indexed to, uint256[] indexed tokenId, uint256 indexed price);
    event publicSaleMint(address indexed to, uint256[] indexed tokenId, uint256 indexed price);
    event preSaleTimeUpdate(uint256 indexed time);
    event preSaleDurationUpdate(uint256 indexed duration);
    event whitelistSaleTimeUpdate(uint256 indexed time);
    event whitelistSaleDurationUpdate(uint256 indexed duration);
    event publicSaleTimeUpdate(uint256 indexed time);
    event publicSaleDurationUpdate(uint256 indexed duration);
    event ETHFundsWithdrawn(uint256 indexed amount, address indexed _address);
    event withdrawAddressUpdated(address indexed newAddress);
    event NFTAddressUpdated(address indexed newAddress);
    event updateETHAmount(address indexed owner, uint256 indexed amount);
    event signatureAddressUpdated(address indexed _address);
    event airdropNFT(address[] indexed to, uint256[] indexed tokenId);
    event cappedSupplyUpdate(address indexed owner, uint256 indexed supply);
    event preSaleMintingLimit(address indexed owner, uint256 indexed limit);
    event whitelistSaleMintingLimit(address indexed owner, uint256 indexed limit);
    event preSalePerTransactionMintLimitUpdated(uint256 indexed _perTransactionMintLimit);
    event whitelistSalePerTransactionMintLimitUpdated(uint256 indexed _perTransactionMintLimit);
    event publicSalePerTransactionMintLimitUpdated(uint256 indexed _perTransactionMintLimit);
    

    constructor(address _NFTaddress,address payable _withdrawAddress) {
        NFT = IERC721(_NFTaddress);

        ethAmount = 0 ether;
        cappedSupply = 5000;
        mintedSupply = 0;
        preSaleMintLimit = 2;
        whitelistSaleMintLimit = 1;
        preSalePerTransactionMintLimit = 2;
        whitelistSalePerTransactionMintLimit = 1;
        publicSalePerTransactionMintLimit = 1;

        preSaleTime = 1670853076; // presale 23-12-22 00:00:00
        preSaleDuration = 5 minutes;

        whitelistSaleTime = 1670893169; // whitelist mint 23-12-22 00:15:00
        whitelistSaleDuration = 5 minutes;

        publicSaleTime = 1679854169; // public sale 23-12-22 01:00:00
        publicSaleDuration = 7 minutes;

        withdrawAddress = _withdrawAddress;
        signatureAddress = 0x23Fb1484a426fe01F8883a8E27f61c1a7F35dA37;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
    }

    function presaleMint(uint256[] memory _tokenId, bytes32 _hash, bytes memory _signature) public payable{
        require(msg.value == ethAmount.mul(_tokenId.length),"Dapp: Invalid value!");
        require(block.timestamp >= preSaleTime,"Dapp: Presale not started!");
        require(block.timestamp <= preSaleTime.add(preSaleDuration),"Dapp: Presale ended!");
        require(mintBalancePreSale[msg.sender].add(_tokenId.length) <= preSaleMintLimit,"Dapp: Wallet's presale mint limit exceeded!");
        require(mintedSupply.add(_tokenId.length) <= cappedSupply,"Dapp: Max supply limit exceeded!");
        require(recover(_hash,_signature) == signatureAddress,"Dapp: Invalid signature!");
        require(!signatures[_signature],"Dapp: Signature already used!");
        require( _tokenId.length <= preSalePerTransactionMintLimit,"Dapp: Token id length greater than presale per transacton mint limit!");

        for(uint index=0; index<_tokenId.length; index++){

            NFT.mint(msg.sender, _tokenId[index]);
            mintedSupply++;
            mintBalancePreSale[msg.sender]++;

        }

        signatures[_signature] = true;

        emit preSaleMint(msg.sender, _tokenId, msg.value);
    }

    function whitelistMint(uint256[] memory _tokenId, bytes32 _hash, bytes memory _signature) public payable{
        require(msg.value == ethAmount.mul(_tokenId.length),"Dapp: Invalid value!");
        require(block.timestamp >= whitelistSaleTime,"Dapp: Whitelisted sale not started!");
        require(block.timestamp <= whitelistSaleTime.add(whitelistSaleDuration),"Dapp: Whitelisted sale ended!");
        require(mintBalanceWhitelistSale[msg.sender].add(_tokenId.length) <= whitelistSaleMintLimit,"Dapp: Wallet's whitelisted sale mint limit exceeded!");
        require(mintedSupply.add(_tokenId.length) <= cappedSupply,"Dapp: Max supply limit exceeded!");
        require(recover(_hash,_signature) == signatureAddress,"Dapp: Invalid signature!");
        require(!signatures[_signature],"Dapp: Signature already used!");
        require( _tokenId.length <= whitelistSalePerTransactionMintLimit,"Dapp: Token id length greater than whitelist sale per transacton mint limit!");

        for(uint index=0; index<_tokenId.length; index++){

            NFT.mint(msg.sender, _tokenId[index]);
            mintedSupply++;
            mintBalanceWhitelistSale[msg.sender]++;

        }
        signatures[_signature] = true;

        emit whitelistSaleMint(msg.sender, _tokenId, msg.value);
    }

    function publicMint(uint256[] memory _tokenId, bytes32 _hash, bytes memory _signature) public payable{
        require(msg.value == ethAmount.mul(_tokenId.length),"Dapp: Invalid value!");
        require(block.timestamp >= publicSaleTime,"Dapp: Public sale not started!");
        require(block.timestamp <= publicSaleTime.add(publicSaleDuration),"Dapp: Public sale ended!");
        require(mintedSupply.add(_tokenId.length) <= cappedSupply,"Dapp: Max supply limit exceeded!");
        require(recover(_hash,_signature) == signatureAddress,"Dapp: Invalid signature!");
        require(!signatures[_signature],"Dapp: Signature already used!");
        require(_tokenId.length <= publicSalePerTransactionMintLimit,"Dapp: Token id length greater than public per transacton mint limit!");

        for(uint index=0; index<_tokenId.length; index++){

            NFT.mint(msg.sender, _tokenId[index]);
            mintedSupply++;

        }
        
        signatures[_signature] = true;

        emit publicSaleMint(msg.sender, _tokenId, msg.value);
    }

    function updatePresaleTime(uint256 _presaleTime) public {
        require(hasRole(ADMIN_ROLE, _msgSender()),"Dapp: Must have admin role to update.");
        require(_presaleTime>block.timestamp,"Dapp: Start time should be greater than current time!");
        
        preSaleTime = _presaleTime;

        emit preSaleTimeUpdate(_presaleTime);
    }

    function updatePresaleDuration(uint256 _presaleDuration) public {
        require(hasRole(ADMIN_ROLE, _msgSender()),"Dapp: Must have admin role to update.");
        require(_presaleDuration>0,"Dapp: Invalid duration value!");

        preSaleDuration = _presaleDuration;

        emit preSaleDurationUpdate(_presaleDuration);
    }

    function updateWhitelistSaleTime(uint256 _whitelistSaleTime) public {
        require(hasRole(ADMIN_ROLE, _msgSender()),"Dapp: Must have admin role to update.");
        require(_whitelistSaleTime>preSaleTime.add(preSaleDuration),"Dapp: Whitelist sale start time should be greater than presale duration!");

        whitelistSaleTime = _whitelistSaleTime;

        emit whitelistSaleTimeUpdate(_whitelistSaleTime);
    }

    function updateWhitelistSaleDuration(uint256 _whitelistSaleDuration) public {
        require(_whitelistSaleDuration>0,"Dapp: Invalid duration value!");
        require(hasRole(ADMIN_ROLE, _msgSender()),"Dapp: Must have admin role to update.");

        whitelistSaleDuration = _whitelistSaleDuration;

        emit whitelistSaleDurationUpdate(_whitelistSaleDuration);
    }

    function updatePublicSaleTime(uint256 _publicSaleTime) public {
        require(_publicSaleTime>whitelistSaleTime.add(whitelistSaleDuration),"Dapp: Public sale start time should be greater than whitelist sale duration!");
        require(hasRole(ADMIN_ROLE, _msgSender()),"Dapp: Must have admin role to update.");

        publicSaleTime = _publicSaleTime;

        emit publicSaleTimeUpdate(_publicSaleTime);
    }

    function updatePublicSaleDuration(uint256 _publicSaleDuration) public {
        require(_publicSaleDuration>0,"Dapp: Invalid duration value!");
        require(hasRole(ADMIN_ROLE, _msgSender()),"Dapp: Must have admin role to update.");

        publicSaleDuration = _publicSaleDuration;

        emit publicSaleDurationUpdate(_publicSaleDuration);
    }

    function withdrawEthFunds(uint256 _amount) public onlyOwner /*nonReentrant*/{

        require(_amount > 0,"Dapp: invalid amount.");

        withdrawAddress.transfer(_amount);
        emit ETHFundsWithdrawn(_amount, msg.sender);

    }

    function updateWithdrawAddress(address payable _withdrawAddress) public onlyOwner{
        require(_withdrawAddress != withdrawAddress,"Dapp: Invalid address.");
        require(_withdrawAddress != address(0),"Dapp: Invalid address.");

        withdrawAddress = _withdrawAddress;
        emit withdrawAddressUpdated(_withdrawAddress);

    }

    function airdrop(address[] memory to, uint256[] memory tokenId) public {
        require(hasRole(MINTER_ROLE, _msgSender()),"Dapp: Must have minter role to mint.");
        require(to.length == tokenId.length,"Dapp: Length of token id and address are not equal!");
        require(mintedSupply.add(tokenId.length) <= cappedSupply,"Dapp: Capped value rached!");

        for (uint index = 0; index < to.length; index++) {
            NFT.mint(to[index], tokenId[index]);
            mintedSupply++;
        }

        emit airdropNFT(to, tokenId);
    }

    function updateCapValue(uint256 _value) public  {
        require(hasRole(ADMIN_ROLE, _msgSender()),"Dapp: Must have admin role to update.");
        require(_value > mintedSupply, "Dapp: Invalid capped value!");
        require(_value != 0, "Dapp: Capped value cannot be zero!");

        cappedSupply = _value;

        emit cappedSupplyUpdate(msg.sender, _value);
    }

    function updatePreSaleMintLimit(uint256 _limit) public  {
        require(hasRole(ADMIN_ROLE, _msgSender()),"Dapp: Must have admin role to update.");
        require(_limit != 0, "Dapp: Cannot set to zero!");

        preSaleMintLimit = _limit;

        emit preSaleMintingLimit(msg.sender, _limit);
    }

    function updateWhitelistSaleMintLimit(uint256 _limit) public  {
        require(hasRole(ADMIN_ROLE, _msgSender()),"Dapp: Must have admin role to update.");
        require(_limit != 0, "Dapp: Cannot set to zero!");

        whitelistSaleMintLimit = _limit;

        emit whitelistSaleMintingLimit(msg.sender, _limit);
    }

    function updateNFTAddress(address _address) public  {
        require(hasRole(ADMIN_ROLE, _msgSender()),"Dapp: Must have admin role to update.");
        require(_address != address(0),"Dapp: Invalid address!");
        require(IERC721(_address) != NFT, "Dapp: Address already exist.");

        NFT = IERC721(_address);

        emit NFTAddressUpdated(_address);
    }

    function updateEthAmount(uint256 _amount) public  {
        require(hasRole(ADMIN_ROLE, _msgSender()),"Dapp: Must have admin role to update.");
        require(_amount != ethAmount, "Dapp: Invalid amount!");

        ethAmount = _amount;

        emit updateETHAmount(msg.sender, _amount);
    }

    function updateSignatureAddress(address _signatureAddress) public {
        require(hasRole(ADMIN_ROLE, _msgSender()),"Dapp: Must have admin role to update.");
        require(_signatureAddress != address(0),"Dapp: Invalid address!");
        require(_signatureAddress != signatureAddress,"Dapp! Old address passed again!");
        

        signatureAddress = _signatureAddress;

        emit signatureAddressUpdated(_signatureAddress);
    }

    function updatePublicSalePerTransactionMintLimit(uint256 _publicSalePerTransactionMintLimit) public {
        require(hasRole(ADMIN_ROLE, _msgSender()),"Dapp: Must have admin role to update.");
        require(_publicSalePerTransactionMintLimit>0,"Dapp: Invalid value!");
        require(_publicSalePerTransactionMintLimit!=publicSalePerTransactionMintLimit,"Dapp: Limit value is same sa previous!");

        publicSalePerTransactionMintLimit = _publicSalePerTransactionMintLimit;

        emit publicSalePerTransactionMintLimitUpdated(_publicSalePerTransactionMintLimit);
    }

    function updatePreSalePerTransactionMintLimit(uint256 _preSalePerTransactionMintLimit) public {
        require(hasRole(ADMIN_ROLE, _msgSender()),"Dapp: Must have admin role to update.");
        require(_preSalePerTransactionMintLimit>0,"Dapp: Invalid value!");
        require(_preSalePerTransactionMintLimit!=publicSalePerTransactionMintLimit,"Dapp: Limit value is same sa previous!");
        require(_preSalePerTransactionMintLimit<=preSaleMintLimit,"Dapp: Per transaction mint limit cannot be greater than presale mint limit!");

        preSalePerTransactionMintLimit = _preSalePerTransactionMintLimit;

        emit preSalePerTransactionMintLimitUpdated(_preSalePerTransactionMintLimit);
    }

    function updateWhitelistSalePerTransactionMintLimit(uint256 _whitelistSalePerTransactionMintLimit) public {
        require(hasRole(ADMIN_ROLE, _msgSender()),"Dapp: Must have admin role to update.");
        require(_whitelistSalePerTransactionMintLimit>0,"Dapp: Invalid value!");
        require(_whitelistSalePerTransactionMintLimit!=publicSalePerTransactionMintLimit,"Dapp: Limit value is same sa previous!");
        require(_whitelistSalePerTransactionMintLimit<=whitelistSaleMintLimit,"Dapp: Per transaction mint limit cannot be greater than whitelist sale mint limit!");

        whitelistSalePerTransactionMintLimit = _whitelistSalePerTransactionMintLimit;

        emit whitelistSalePerTransactionMintLimitUpdated(_whitelistSalePerTransactionMintLimit);
    }

    function getEthAmount() public view returns(uint256){
        return ethAmount;
    }

    function getCappedSupply() public view returns(uint256){
        return cappedSupply;
    }

    function getmintedSupply() public view returns(uint256){
        return mintedSupply;
    }

    function getPreSaleTime() public view returns(uint256){
        return preSaleTime;
    }

    function getPreSaleDuration() public view returns(uint256){
        return preSaleDuration;
    }

    function getPreSaleMintLimit() public view returns(uint256){
        return preSaleMintLimit;
    }

    function getWhitelistSaleTime() public view returns(uint256){
        return whitelistSaleTime;
    }

    function getWhitelistSaleDuration() public view returns(uint256){
        return whitelistSaleDuration;
    }

    function getWhitelistSaleMintLimit() public view returns(uint256){
        return whitelistSaleMintLimit;
    }

    function getPublicSaleTime() public view returns(uint256){
        return publicSaleTime;
    }

    function getPublicSaleDuration() public view returns(uint256){
        return publicSaleDuration;
    }

    function getWithdrawAddress() public view returns(address){
        return withdrawAddress;
    }

    function getMintBalancePreSale(address _address) public view returns(uint256){
        return mintBalancePreSale[_address];
    }
    
    function getMintBalanceWhitelistedSale(address _address) public view returns(uint256){
        return mintBalanceWhitelistSale[_address];
    }

    function getSignatureAddress() public view returns(address _signatureAddress){
        _signatureAddress = signatureAddress;
    }

    function checkSignatureValidity(bytes memory _signature) public view returns(bool){
        return signatures[_signature];
    }

    function getPublicSalePerTransactionMintLimit() public view returns(uint256){
        return publicSalePerTransactionMintLimit;
    }

    function getWhitelistSalePerTransactionMintLimit() public view returns(uint256){
        return whitelistSalePerTransactionMintLimit;
    }

    function getPreSalePerTransactionMintLimit() public view returns(uint256){
        return preSalePerTransactionMintLimit;
    }

    function getNFTAdress() public view returns(IERC721){
        return NFT;
    }

    function recover(bytes32 _hash, bytes memory _signature) public pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        if (_signature.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            r := mload(add(_signature, 0x20))
            s := mload(add(_signature, 0x40))
            v := byte(0, mload(add(_signature, 0x60)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            // solium-disable-next-line arg-overflow
            return ecrecover(_hash, v, r, s);
        }
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