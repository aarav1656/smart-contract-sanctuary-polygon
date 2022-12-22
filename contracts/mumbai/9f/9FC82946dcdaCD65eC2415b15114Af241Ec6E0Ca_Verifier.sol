// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./USDTInterface.sol";
import "./InsurancePool.sol";

contract Verifier is Ownable {

    bool public verifierSignUpOpen;

    struct VerifierApplication {
        address user;
        string supportingDocsURI;
        uint256 contributionAmount;
        uint status;
        address creator;
    }

    uint public verifierCount;

    VerifierApplication[] public verifierApplications;

    mapping (address => bool) public verifiers;
    mapping (address => bool) public blackListedVerifiers;

    USDTInterface public usdtContract;
    address public poolAddress;

    event VerifierEnrol(address user, string docsURI, uint contributionAmount);
    event ConfirmVerifierEnrol(address verifier);
    event DeclineVerfierEnrol(address verifier);
    event BlacklistVerifier(address verifier);

    constructor(address usdtAddress) {
        usdtContract = USDTInterface(usdtAddress);
        verifierSignUpOpen= true;
    }

    function setPoolAddress(address _poolAddress) public onlyOwner {
        require(poolAddress == address(0), "Pool address already set");

        poolAddress = _poolAddress;
    }

    function registerAsVerifier(string memory profileDocURI, uint contributionAmount) public {
        require(verifierSignUpOpen, "Unauthorized at this time");
        require(enrolledAsVerifier(msg.sender) == -1, "Previously attempted enroll as verifier");

        usdtContract.transferFrom(msg.sender, poolAddress, contributionAmount);

        verifierApplications.push(VerifierApplication(msg.sender, profileDocURI, contributionAmount, 0, msg.sender));
    }

    function isVerifier(address addr_) public view returns (bool) {
        return verifiers[addr_];    
    }

    function enrolledAsVerifier(address addr_) public view returns (int) {
        if (isVerifier(addr_)) return 1;
        for (uint i = 0; i < verifierApplications.length; i++) {
            if (verifierApplications[i].user == addr_) return int(verifierApplications[i].status);
        }

        return -1;
    }

    function approveVerifierRegistration(address potentialVerifier) public onlyOwner {
        int applicationIndex = enrolledAsVerifier(potentialVerifier);
        require(applicationIndex >= 0 && !isVerifier(potentialVerifier), "User already approved or never registered");

        verifiers[potentialVerifier] = true;
        verifierApplications[uint256(applicationIndex)].status = 1;
        verifierCount += 1;
        emit ConfirmVerifierEnrol(potentialVerifier);
    }

    function declineVerifierRegistration(address potentialVerifier) public onlyOwner {
        int applicationIndex = enrolledAsVerifier(potentialVerifier);
        require(enrolledAsVerifier(potentialVerifier) >= 0 && !isVerifier(potentialVerifier), "User already approved or never registered");

        verifierApplications[uint256(applicationIndex)].status = 2;
        verifierCount += 1;
        emit DeclineVerfierEnrol(potentialVerifier);
    }


    function blacklistVerifier(address _verifier) public onlyOwner {
        require(isVerifier(_verifier), "Not a verifier");
        int applicationIndex = enrolledAsVerifier(_verifier);

        verifiers[_verifier] = false;
        verifierApplications[uint256(applicationIndex)].status = 3;
        verifierCount -= 1;
        blackListedVerifiers[_verifier] = true;
        emit BlacklistVerifier(_verifier);
    }

    function closeVerifierSignUpPeriod() public onlyOwner {
        require(verifierSignUpOpen, "Already closed");
        verifierSignUpOpen = false;
    }

    function openVerifierSignUpPeriod() public onlyOwner {
        require(!verifierSignUpOpen, "Already open");
        verifierSignUpOpen = true;
    }

    function whitelistVerifier(address verifier) public onlyOwner {
        verifierApplications.push(VerifierApplication(verifier, "", 0, 1, owner()));

        verifiers[verifier] = true;
    }
    

    function getVerifierReward(address _verifier) public view returns (uint256 reward) {

        uint currentVerifierActionCount = 0;
        uint currentVerifierContribution = 0;
        uint totalContribution = 0;
        uint totalActionCount = 0;

        for (uint i; i < verifierApplications.length; i++) {
            if (verifierApplications[i].status == 1) {

                uint actionCount = InsurancePool(poolAddress).verifierActionCount(verifierApplications[i].user);
                uint contribution = verifierApplications[i].contributionAmount;
                if (verifierApplications[i].user == _verifier) {

                    currentVerifierActionCount = actionCount;
                    currentVerifierContribution = contribution;
                }

                totalContribution += contribution;

                totalActionCount = actionCount;
            }
        }

        uint ratio = currentVerifierActionCount * currentVerifierContribution * 1e18 /(totalActionCount * totalContribution);

        reward = ratio * totalContribution / 1e18;
    }

    function getPendingVerifierAplications() public view returns (VerifierApplication[] memory pending) {

        VerifierApplication[] memory potentialVerifiers = verifierApplications;

        pending = new VerifierApplication[](verifierApplications.length - verifierCount);

        uint256 index = 0;

        for (uint256 i = 0; i < potentialVerifiers.length; i++) {
            if (potentialVerifiers[i].status == 0) {

                pending[index] = potentialVerifiers[i];
                index += 1;
            }
        }
    }

    function getVerifiers() public view returns (VerifierApplication[] memory) {

        return verifierApplications;
    }





}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface USDTInterface {


    function transfer(address _to, uint _value) external;

    function transferFrom(address _from, address _to, uint _value) external;

    function balanceOf(address who) external view returns (uint);

    function approve(address _spender, uint _value) external;

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function allowance(address _owner, address _spender) external view returns (uint remaining);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./Token.sol";
import "./Verifier.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./USDTInterface.sol";
import {
    ConfirmWithValuation,
    RegistrationVerifiers,
    ClaimVerifiers,
    Registration,
    Claim
} from "./ContractStructs.sol";

contract InsurancePool {

    DeInsureToken tokenContract;
    Verifier verifierContract;

    USDTInterface public immutable usdtContract;
    Registration[] public registrations;
    Claim[] public claims;

    mapping(uint256 => address[]) tokenTypeToEnrolledUsers; //Token Type represents the tokenId
    mapping(uint256 => mapping(address => uint256)) tokenTypeToUserToRegId;
    mapping(uint256 => RegistrationVerifiers) registrationVerifiers;
    mapping(uint256 => ClaimVerifiers) claimVerifiers; 
    mapping(address => uint256) public verifierActionCount;
    uint256 public contributionPoolAmounts;
    mapping(address => Registration[]) public userToRegistration;
    mapping(address => Claim[]) public userToClaim;

    event RegisterForInsurance(
        uint256 tokenType,
        address user,
        string docsURI,
        uint256 valuation
    );
    event VerifyRegistrationDocs(
        address verifier,
        uint _registrationId,
        uint256 valuation
    );
    event RejectRegistrationDocs(address verifier, uint _registrationId);
    event PayPremium(address user, uint256 amount);
    event MakeClaim(
        uint256 tokenType,
        address user,
        string docsURI,
        uint256 amount
    );
    event VerifyClaim(address verifier, uint256 claimId);

    modifier isVerifier() {
        require(
            verifierContract.isVerifier(msg.sender),
            "Not a valid verifier"
        );
        _;
    }

    constructor(address _usdtAddress, address verifierContractAddress, address _tokenContractAddress) {
        usdtContract = USDTInterface(_usdtAddress);
        verifierContract = Verifier(verifierContractAddress);
        tokenContract = DeInsureToken(_tokenContractAddress);
    }

    function registerForInsurance(
        string memory supportingDocsURI,
        uint256 tokenType,
        uint256 valuationAmount
    ) public {
        require(
            enrolmentStatus(msg.sender, tokenType) == -1 ||
                enrolmentStatus(msg.sender, tokenType) == 2,
            "User already has a pending or active registration"
        );

        Registration memory reg = Registration(
            tokenType,
            supportingDocsURI,
            msg.sender,
            0,
            block.timestamp,
            valuationAmount
        );

        registrations.push(reg);

        userToRegistration[msg.sender].push(reg);

        emit RegisterForInsurance(
            tokenType,
            msg.sender,
            supportingDocsURI,
            valuationAmount
        );
    }

    function getRegistrations() public view returns (Registration[] memory) {
        return registrations;
    }

    function getClaims() public view returns (Claim[] memory) {
        return claims;
    }

    function enrolmentStatus(address _user, uint256 _tokenType)
        public
        view
        returns (int256)
    {
        for (uint256 i = 0; i < registrations.length; i++) {
            if (
                registrations[i].user == _user &&
                registrations[i].tokenType == _tokenType
            ) {
                return int256(registrations[i].status);
            }
        }
        return -1;
    }

    function verifyRegistration(
        uint256 _registrationId,
        uint256 valuationAmount
    ) public isVerifier {
        require(
            _registrationId < registrations.length,
            "Not a valid registration id"
        );
        Registration memory reg = registrations[_registrationId];

        require(
            reg.status == 0 && !hasCheckedReg(msg.sender, _registrationId),
            "Already called this function on this registration."
        );

        registrationVerifiers[_registrationId].approvers.push(
            ConfirmWithValuation(valuationAmount, msg.sender)
        );

        // check if up to 70% of verifiers have approved registration, and confirm it.
        if (
            (verifierContract.verifierCount() * 7) <=
            (registrationVerifiers[_registrationId].approvers.length * 10)
        ) {
            registrations[_registrationId].status = 1;
            registrations[_registrationId].valuationAmount =
                computeSuggestedValuation(_registrationId) /
                1e18;

            tokenTypeToEnrolledUsers[reg.tokenType].push(reg.user);
            tokenTypeToUserToRegId[reg.tokenType][msg.sender] = _registrationId;
        }

        verifierActionCount[msg.sender] += 1;
        emit VerifyRegistrationDocs(
            msg.sender,
            _registrationId,
            computeSuggestedValuation(_registrationId) / 1e18
        );
    }

    function objectRegistration(uint256 _registrationId) public isVerifier {
        require(
            _registrationId < registrations.length,
            "Not a valid registration id"
        );
        Registration memory reg = registrations[_registrationId];

        require(
            reg.status == 0 && !hasCheckedReg(msg.sender, _registrationId),
            "Already called this function on this registration."
        );

        registrationVerifiers[_registrationId].decliners.push(msg.sender);

        // check if up to 50% of verifiers have declined registration, and completely decline it.
        if (
            (verifierContract.verifierCount() * 5) <=
            (registrationVerifiers[_registrationId].decliners.length * 10)
        ) {
            registrations[_registrationId].status = 2;
        }

        verifierActionCount[msg.sender] += 1;
        emit RejectRegistrationDocs(msg.sender, _registrationId);
    }

    function computeSuggestedValuation(uint256 _registrationId)
        internal
        view
        returns (uint256)
    {
        ConfirmWithValuation[] memory regs = registrationVerifiers[
            _registrationId
        ].approvers;

        uint256 sum = 0;
        uint256 count = 0;

        for (; count < regs.length; count++) {
            sum += regs[count].valuationAmount;
        }

        return (sum * 1e18) / count;
    }

    function payPremium(uint256 _usdtAmount, uint256 _tokenType) public {

        uint256 registrationId = tokenTypeToUserToRegId[_tokenType][msg.sender];
        Registration memory reg = registrations[registrationId];
        uint256 premiumPercentage = tokenContract
            .getPackageType(reg.tokenType)
            .premiumPercentage;

        require(
            (_usdtAmount * 10000) >= (reg.valuationAmount * premiumPercentage),
            "You did not send sufficient USDT"
        );
        usdtContract.transferFrom(msg.sender, address(this), _usdtAmount);
        tokenContract.mintToClient(msg.sender, reg.tokenType, _usdtAmount);
        emit PayPremium(msg.sender, _usdtAmount);
    }

    function makeClaim(
        string memory _docURI,
        uint256 _amount,
        uint256 tokenType
    ) external {
        
        uint balanceOfToken = tokenContract.balanceOf(msg.sender, tokenType);
        uint exceedings = tokenContract.exceedingAmounts(msg.sender, tokenType);
        //Check the balance for the tokenType specified
        require (balanceOfToken * 5 > (_amount - balanceOfToken)*10 && (exceedings * 5) > (_amount - balanceOfToken)*10, "Not sufficient contribution made to make this claim");
        claims.push(Claim(
            _docURI,
            _amount,
            msg.sender,
            tokenType,
            0,
            block.timestamp
        ));

        emit MakeClaim(tokenType, msg.sender, _docURI, _amount);
    }

    function verifyClaim(uint256 claimId) external {
        Claim memory claim = claims[claimId];
        require(
            claim.status == 0 && !hasCheckedClaim(msg.sender, claimId),
            "Already called this function on this registration."
        );

        if (
            (verifierContract.verifierCount() * 7) <=
            (claimVerifiers[claimId].approvers.length * 10)
        ) {
            claims[claimId].status = 1;
            tokenContract.burnFromClient(claim.user, claim.tokenType, claim.amount);
            usdtContract.transfer(claim.user, claim.amount);
        }
        emit VerifyClaim(msg.sender, claimId);
    }



    function payoutVerifier(address verifier, uint256 amount) external {

        require(msg.sender == address(verifierContract), "Unauthorized");

        usdtContract.transfer(verifier, amount);
    }

    function hasCheckedReg(address verifier, uint256 _registrationId)
        public
        view
        returns (bool)
    {
        RegistrationVerifiers memory verifiers = registrationVerifiers[
            _registrationId
        ];

        for (uint256 i = 0; i < verifiers.approvers.length; i++) {
            if (verifiers.approvers[i].verifier == verifier) return true;
        }

        for (uint256 i = 0; i < verifiers.decliners.length; i++) {
            if (verifiers.decliners[i] == verifier) return true;
        }

        return false;
    }

    function hasCheckedClaim(address verifier, uint256 _claimId)
        public
        view
        returns (bool)
    {
        ClaimVerifiers memory verifiers = claimVerifiers[
            _claimId
        ];

        for (uint256 i = 0; i < verifiers.approvers.length; i++) {
            if (verifiers.approvers[i] == verifier) return true;
        }

        for (uint256 i = 0; i < verifiers.decliners.length; i++) {
            if (verifiers.decliners[i] == verifier) return true;
        }

        return false;
    }


    function getUserRegistrations(address user) public view returns (Registration[] memory) {
        Registration[] memory userRegistrations = userToRegistration[user];

        return userRegistrations;
    }

    function getUserClaims(address user) public view returns (Claim[] memory) {
        Claim[] memory claimsMade = userToClaim[user];

        return claimsMade;
    }

    function getUncheckedRegs(address verifier) public view returns (Registration[] memory regs) {
        regs = new Registration[](registrations.length);

        for (uint256 i = 0; i < registrations.length; i++) {
            if (!hasCheckedReg(verifier, i)) regs[i] = registrations[i];
        }
    }

    function getUncheckedClaims(address verifier) public view returns (Claim[] memory pendingClaims) {
        pendingClaims = new Claim[](claims.length);

        for (uint256 i = 0; i < claims.length; i++) {
            if (!hasCheckedClaim(verifier, i)) pendingClaims[i] = claims[i];
        }
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
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DeInsureToken is ERC1155, Ownable {

    // defines the premium percent to be paid 
    struct PackageType {
        uint tokenId;
        uint premiumPercentage;
    }

    mapping (uint => string) public tokenURIs;
    uint private tokenCounter;

    PackageType[] public tokenTypes;
    address public poolAddress;

    enum InsuranceValuationType {
        USER_VALUED,
        COMPANY_VALUED
    }

    // maps user to claims beyond contributions based on tokenType
    mapping (address => mapping(uint => uint)) public exceedingAmounts;

    constructor() ERC1155("") {
        tokenCounter = 0;
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        return tokenURIs[tokenId];
    }


    // defines the monthly premium percentage as a 4-digit number (fraction * 10000)
    function createNewPackage(uint _premiumPercentage, string memory tokenURI) public onlyOwner {
        
        uint _tokenCode = tokenCounter + 1;

        require(abi.encodePacked(tokenURIs[_tokenCode]).length == 0, "Already set URI for this package");
        tokenURIs[_tokenCode] = tokenURI;
        _mint(msg.sender, _tokenCode, 1, "");

        tokenTypes.push(PackageType(_tokenCode, _premiumPercentage));

        tokenCounter = _tokenCode;
    }

    function isTokenType(uint _tokenType) public view returns (bool) {
        for (uint i = 0; i < tokenTypes.length; i++) {
            if (tokenTypes[i].tokenId == _tokenType) return true;
        }

        return false;
    }

    function getPackageType(uint _tokenType) public view returns (PackageType memory) {
        PackageType memory pkg;
        for (uint i = 0; i < tokenTypes.length; i++) {
            if (tokenTypes[i].tokenId == _tokenType) pkg = tokenTypes[i];
        }

        return pkg;
    }

    function getPackages() external view returns (PackageType[] memory) {
        
        return tokenTypes;
    }

    function setPoolAddress(address _addr) public onlyOwner {
        require(poolAddress == address(0), "Pool address already set");
        poolAddress = _addr;
    }

    function mintToClient(address client, uint _tokenId, uint _amount) public {
        require(msg.sender == poolAddress, "Not authorized to call this function");

        _mint(client, _tokenId, _amount, "");
    }

    function burnFromClient(address client, uint _tokenId, uint _amount) public {
        require(msg.sender == poolAddress, "Not authorized to call this function");
        uint balanceOfToken = balanceOf(client, _tokenId);
        if (balanceOfToken < _amount) {
            _burn(client, _tokenId, balanceOfToken);
            exceedingAmounts[client][_tokenId] += (_amount - balanceOfToken);
            return;
        }

        _burn(client, _tokenId, _amount);
    }



    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

struct ConfirmWithValuation {
    uint256 valuationAmount;
    address verifier;
}

struct RegistrationVerifiers {
    ConfirmWithValuation[] approvers;
    address[] decliners;
}

struct ClaimVerifiers {
    address[] approvers;
    address[] decliners;
}

struct Registration {
    uint256 tokenType;
    string docsURI;
    address user;
    uint256 status;
    uint256 createdAt;
    uint256 valuationAmount;
}
//ERC115 is representing categories of insurance e.g, premium, third party e.t.c
//the IPFS contains an object that holds the documents url, other meta data like name, ...
struct Claim {
    string docsURI;
    uint256 amount;
    address user;
    uint256 tokenType; //this represents the type of the insurance e.g premium, third party
    uint256 status;
    uint256 createdAt;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
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
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
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