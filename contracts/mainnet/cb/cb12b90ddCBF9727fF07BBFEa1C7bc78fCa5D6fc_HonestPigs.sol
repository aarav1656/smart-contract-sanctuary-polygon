// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

import "../HonestPigs/interfaces/IHonestPigs.sol";
import "../HonestPigs/interfaces/IMetaPigs.sol";
import "../../v2/interfaces/IRegistryFarmerV2.sol";
import "../../v2/interfaces/IHonestFarmerClubV2.sol";
import "../../v2/FarmGirls/interfaces/IFarmGirlsERC1155.sol";
import "../../v2/interfaces/ITheFarm.sol";
import "../../v2/interfaces/ITheFarmV2.sol";
import "../../v2/interfaces/IPotatoBurnable.sol";
import "../../v2/HonestChickens/HonestChickens.sol";
import "../PotatoChip/interfaces/IPotatoChipBurnable.sol";

/// @author Howdy Games
/// @title Just some honest pigs
contract HonestPigs is
	IHonestPigs,
	RegistryFarmerV2Consumer,
	Initializable,
	ERC1155Upgradeable,
	OwnableUpgradeable,
	ERC1155BurnableUpgradeable,
	ERC1155SupplyUpgradeable
{
	using CountersUpgradeable for CountersUpgradeable.Counter;

	string public name;
	string public symbol;
	string public contractURI;
	uint256 public constant MAX_SUPPLY = 3000;
	bool public isLive;

	mapping(MintPriceTypes => uint256) public mintPricePotatoByPriceType;

	CountersUpgradeable.Counter private numberOfPigsBreeded;

	HonestChickens chicken;

	uint256 public maxSupply;

	function initialize(string memory _contractURI, address _registryFarmerV2)
		public
		initializer
	{
		__ERC1155_init("");
		__Ownable_init();
		__ERC1155Burnable_init();
		__ERC1155Supply_init();

		name = "Howdy Games Pigs";
		symbol = "HFCP";
		contractURI = _contractURI;

		// Mint prices
		mintPricePotatoByPriceType[MintPriceTypes.NONE] = 600 * 10**18;
		mintPricePotatoByPriceType[MintPriceTypes.FARMER_OR_FARM_GIRL] =
			475 *
			10**18;
		mintPricePotatoByPriceType[MintPriceTypes.FARMER_AND_FARM_GIRL] =
			350 *
			10**18;

		mintPricePotatoByPriceType[MintPriceTypes.CHICKEN] = 200 ether;
		mintPricePotatoByPriceType[
			MintPriceTypes.CHICKEN_AND_FARMER_AND_FARMER_GIRL
		] = 100 ether;
		mintPricePotatoByPriceType[
			MintPriceTypes.CHICKEN_AND_FARMER_OR_FARMER_GIRL
		] = 150 ether;

		_setRegistryFarmer(_registryFarmerV2);
	}

	modifier mintIsLive() {
		require(isLive, "Mint is not live");
		_;
	}

	function _mintPigs(uint256 numberOfPigs, uint256 pigMintPricePotato)
		private
	{
		uint256 newPigsSupply = numberOfPigsBreeded.current() + numberOfPigs;
		require(
			newPigsSupply <= maxSupply,
			"Minting would exceed maximum supply"
		);

		uint256 totalPotatoCost = numberOfPigs * pigMintPricePotato;
		IPotatoChip potato = IPotatoChip(
			_getRegistryFarmer().getContract("PotatoChip")
		);
		potato.burnFrom(msg.sender, totalPotatoCost);

		uint256[] memory ids = new uint256[](numberOfPigs);
		uint256[] memory amounts = new uint256[](numberOfPigs);

		for (uint256 i = 0; i < numberOfPigs; i++) {
			numberOfPigsBreeded.increment();
			uint256 id = numberOfPigsBreeded.current();

			ids[i] = id;
			amounts[i] = 1;

			emit MintPigs(msg.sender, id);
		}

		_mintBatch(msg.sender, ids, amounts, "");
	}

	function mintPigs(uint256 numberOfPigs) public mintIsLive {
		_mintPigs(
			numberOfPigs,
			mintPricePotatoByPriceType[MintPriceTypes.NONE]
		);
	}

	function mintPigsWithFarmer(uint256 numberOfPigs, uint256 farmerId)
		public
		mintIsLive
	{
		require(_isFarmerHolder(farmerId), "Must hold farmer");

		_mintPigs(
			numberOfPigs,
			mintPricePotatoByPriceType[MintPriceTypes.FARMER_OR_FARM_GIRL]
		);
	}

	function mintPigsWithFarmGirl(uint256 numberOfPigs, uint256 farmGirlId)
		public
		mintIsLive
	{
		require(_isFarmGirlHolder(farmGirlId), "Must hold farm girl");

		_mintPigs(
			numberOfPigs,
			mintPricePotatoByPriceType[MintPriceTypes.FARMER_OR_FARM_GIRL]
		);
	}

	function mintPigsWithFarmerAndFarmGirl(
		uint256 numberOfPigs,
		uint256 farmerId,
		uint256 farmGirlId
	) public mintIsLive {
		require(
			_isFarmerHolder(farmerId) && _isFarmGirlHolder(farmGirlId),
			"Must hold both farmer and farm girl"
		);

		_mintPigs(
			numberOfPigs,
			mintPricePotatoByPriceType[MintPriceTypes.FARMER_AND_FARM_GIRL]
		);
	}

	function mintPigsWithChicken(
		uint256[] memory _chickenIds,
		uint256 _numberOfPigs
	) external mintIsLive {
		uint256 numberOfChickens = _chickenIds.length;
		for (uint256 index = 0; index < numberOfChickens; index++) {
			chicken.burn(msg.sender, _chickenIds[index], 1);
		}

		_mintPigs(
			_numberOfPigs,
			mintPricePotatoByPriceType[MintPriceTypes.CHICKEN]
		);
	}

	function mintPigsWithChickenAndFarmer(
		uint256[] memory _chickenIds,
		uint256 _farmerId,
		uint256 _numberOfPigs
	) external mintIsLive {
		require(_isFarmerHolder(_farmerId), "Must hold farmer or farm girl");

		uint256 numberOfChickens = _chickenIds.length;
		for (uint256 index = 0; index < numberOfChickens; index++) {
			chicken.burn(msg.sender, _chickenIds[index], 1);
		}

		_mintPigs(
			_numberOfPigs,
			mintPricePotatoByPriceType[
				MintPriceTypes.CHICKEN_AND_FARMER_OR_FARMER_GIRL
			]
		);
	}

	function mintPigsWithChickenAndFarmGirl(
		uint256[] memory _chickenIds,
		uint256 _farmGirlId,
		uint256 _numberOfPigs
	) external mintIsLive {
		require(
			_isFarmGirlHolder(_farmGirlId),
			"Must hold farmer or farm girl"
		);

		uint256 numberOfChickens = _chickenIds.length;
		for (uint256 index = 0; index < numberOfChickens; index++) {
			chicken.burn(msg.sender, _chickenIds[index], 1);
		}

		_mintPigs(
			_numberOfPigs,
			mintPricePotatoByPriceType[
				MintPriceTypes.CHICKEN_AND_FARMER_OR_FARMER_GIRL
			]
		);
	}

	function mintPigsWithChickenAndFarmerAndFarmGirl(
		uint256[] memory _chickenIds,
		uint256 _farmerId,
		uint256 _farmGirlId,
		uint256 _numberOfPigs
	) external mintIsLive {
		require(
			_isFarmerHolder(_farmerId) && _isFarmGirlHolder(_farmGirlId),
			"Must hold both farmer and farm girl"
		);

		uint256 numberOfChickens = _chickenIds.length;
		for (uint256 index = 0; index < numberOfChickens; index++) {
			chicken.burn(msg.sender, _chickenIds[index], 1);
		}

		_mintPigs(
			_numberOfPigs,
			mintPricePotatoByPriceType[MintPriceTypes.CHICKEN]
		);
	}

	function uri(uint256 id) public view override returns (string memory) {
		return IMetaPigs(_getRegistryFarmer().getContract("MetaPigs")).uri(id);
	}

	function uriBatch(uint256[] memory ids)
		public
		view
		returns (string[] memory _uris)
	{
		string[] memory uris = new string[](ids.length);

		for (uint256 i = 0; i < ids.length; i++) {
			uint256 id = ids[i];
			uris[i] = uri(id);
		}

		return uris;
	}

	// Utils
	function _isFarmerHolder(uint256 farmerId)
		private
		view
		returns (bool _isHolder)
	{
		IHonestFarmerClubV2 honestFarmerClub = IHonestFarmerClubV2(
			_getRegistryFarmer().getContract("HonestFarmerClub")
		);
		ITheFarmV2 theFarmV2 = ITheFarmV2(
			_getRegistryFarmer().getContract("TheFarmV2")
		);

		bool isHolder = honestFarmerClub.balanceOf(msg.sender, farmerId) == 1;
		bool isStaker = theFarmV2.getDepositorV2(
			Character.HONEST_FARMER,
			farmerId
		) == msg.sender;

		return isHolder || isStaker;
	}

	function _isFarmGirlHolder(uint256 farmGirlId)
		private
		view
		returns (bool _isHolder)
	{
		IFarmGirls farmGirls = IFarmGirls(
			_getRegistryFarmer().getContract("FarmGirls")
		);
		ITheFarmV2 theFarmV2 = ITheFarmV2(
			_getRegistryFarmer().getContract("TheFarmV2")
		);

		bool isHolder = farmGirls.balanceOf(msg.sender, farmGirlId) == 1;
		bool isStaker = theFarmV2.getDepositor(
			Character.FARM_GIRL,
			farmGirlId
		) == msg.sender;

		return isHolder || isStaker;
	}

	function setMintPrice(MintPriceTypes _priceType, uint256 _amount)
		external
		onlyOwner
	{
		mintPricePotatoByPriceType[_priceType] = _amount;
	}

	function setMaxSupply(uint256 _supply) external onlyOwner {
		maxSupply = _supply;
	}

	function setHonestChicken(HonestChickens _chicken) external onlyOwner {
		chicken = _chicken;
	}

	// Administrative
	function setRegistryFarmer(address _registryFarmerV2)
		public
		override
		onlyOwner
	{
		_setRegistryFarmer(_registryFarmerV2);
	}

	function toggleIsLive() public onlyOwner {
		isLive = !isLive;
	}

	function _beforeTokenTransfer(
		address operator,
		address from,
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) internal override(ERC1155Upgradeable, ERC1155SupplyUpgradeable) {
		super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
	}

	/**
	 * Override isApprovedForAll to auto-approve OS's proxy contract
	 */
	function isApprovedForAll(address _owner, address _operator)
		public
		view
		override
		returns (bool isOperator)
	{
		return
			_operator == address(0x207Fa8Df3a17D96Ca7EA4f2893fcdCb78a304101) ||
			ERC1155Upgradeable.isApprovedForAll(_owner, _operator);
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155Upgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "./extensions/IERC1155MetadataURIUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC1155Upgradeable, IERC1155MetadataURIUpgradeable {
    using AddressUpgradeable for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory uri_) internal onlyInitializing {
        __ERC1155_init_unchained(uri_);
    }

    function __ERC1155_init_unchained(string memory uri_) internal onlyInitializing {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
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
        require(account != address(0), "ERC1155: balance query for the zero address");
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
            "ERC1155: caller is not owner nor approved"
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
            "ERC1155: transfer caller is not owner nor approved"
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
     * Emits a {ApprovalForAll} event.
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
            try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155Received.selector) {
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
            try IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector) {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/ERC1155Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC1155Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {ERC1155} that allows token holders to destroy both their
 * own tokens and those that they have been approved to use.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155BurnableUpgradeable is Initializable, ERC1155Upgradeable {
    function __ERC1155Burnable_init() internal onlyInitializing {
    }

    function __ERC1155Burnable_init_unchained() internal onlyInitializing {
    }
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burnBatch(account, ids, values);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/extensions/ERC1155Supply.sol)

pragma solidity ^0.8.0;

import "../ERC1155Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
abstract contract ERC1155SupplyUpgradeable is Initializable, ERC1155Upgradeable {
    function __ERC1155Supply_init() internal onlyInitializing {
    }

    function __ERC1155Supply_init_unchained() internal onlyInitializing {
    }
    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155SupplyUpgradeable.totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                uint256 amount = amounts[i];
                uint256 supply = _totalSupply[id];
                require(supply >= amount, "ERC1155: burn amount exceeds totalSupply");
                unchecked {
                    _totalSupply[id] = supply - amount;
                }
            }
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

enum MintPriceTypes {
	NONE,
	CHICKEN,
	CHICKEN_AND_FARMER_AND_FARMER_GIRL,
	CHICKEN_AND_FARMER_OR_FARMER_GIRL,
	FARMER_OR_FARM_GIRL,
	FARMER_AND_FARM_GIRL
}

interface IHonestPigs {
	function mintPigs(uint256 numberOfPigs) external;

	function mintPigsWithFarmer(uint256 numberOfPigs, uint256 farmerId)
		external;

	function mintPigsWithFarmGirl(uint256 numberOfPigs, uint256 farmGirlId)
		external;

	function mintPigsWithFarmerAndFarmGirl(
		uint256 numberOfPigs,
		uint256 farmerId,
		uint256 farmGirlId
	) external;

	event MintPigs(address indexed minter, uint256 indexed id);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

enum PIG_LEVEL_COLOR {
	PINK,
	MUD,
	UMBER,
	BLACK,
	WHITE,
	WILD_BOAR
}

interface IMetaPigs {
	function uri(uint256 id) external view returns (string memory);

	function setIpfsHashByColor(PIG_LEVEL_COLOR color, string memory ipfsHash)
		external;

	function recordPigsGame(uint256 id) external;

	function getColor(uint256 pigId)
		external
		view
		returns (PIG_LEVEL_COLOR color);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IRegistryFarmerV2 {
	function setContract(string memory contractName, address _address) external;

	function getContract(string memory contractName)
		external
		view
		returns (address);

	event SetContract(string contractName, address indexed _address);
}

abstract contract RegistryFarmerV2Consumer {
	address public registryFarmerV2;

	function _setRegistryFarmer(address _registryFarmerV2) internal {
		registryFarmerV2 = _registryFarmerV2;
	}

	function _getRegistryFarmer() internal view returns (IRegistryFarmerV2) {
		return IRegistryFarmerV2(registryFarmerV2);
	}

	function setRegistryFarmer(address _registryFarmerV2) public virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/interfaces/IERC1155.sol";

import "../libraries/LibraryFarmer.sol";

interface IHonestFarmerClubV2 is IERC1155 {
	function mintFarmers(uint256 numberOfHonestFarmers) external payable;

	function mintWhitelistFarmers(uint256 numberOfHonestFarmers)
		external
		payable;

	function mintFreeFarmers() external;

	function migrateFarmers(address to, uint256[] memory ids) external;

	function setMintPrices(
		uint256 _mintPriceMATIC,
		uint256 _mintPriceMATICWhitelist
	) external;

	function toggleMint(LibraryFarmer.MintType mintType) external;

	function numberOfPostMigrationFarmersMinted()
		external
		view
		returns (uint256);

	function tokenCount() external view returns (uint256);

	function MAX_FARMER_SUPPLY() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/interfaces/IERC1155.sol";

interface IFarmGirls is IERC1155 {
	function mintWeddingRing(
		uint256 numberOfWeddingRings,
		uint256 husbandId,
		uint256 bestManId
	) external;

	function breedFarmGirls(uint256 numberOfFarmGirls) external;

	function uriBatch(uint256[] memory ids)
		external
		view
		returns (string[] memory _uris);

	function setBreedingIsLive(bool _breedingIsLive) external;

	function setWeddingRingCost(uint256 potato) external;

	event MintWeddingRings(
		address indexed minter,
		uint256 indexed husbandId,
		uint256 indexed bestManId,
		uint256 numberOfWeddingRings,
		uint256 totalPotatoCost
	);

	event BreedFarmGirl(address indexed minter, uint256 indexed farmGirlId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface ITheFarm {
	// Stake
	function stakeFarmer(uint256 farmerId, uint256 lockingDurationDays)
		external;

	function stakeFarmerBatch(
		uint256[] memory farmerIds,
		uint256 lockingDurationDays
	) external;

	// Claiming
	function claimBlocks(uint256 farmerId) external;

	function claimBlocksBatch(uint256[] memory farmerIds) external;

	// Withdraw
	function withdrawFarmer(uint256 farmerId) external;

	function withdrawFarmerBatch(uint256[] memory farmerIds) external;

	// Emission Delegation
	function addDelegate(address delegate) external;

	function removeDelegate(address delegate) external;

	// Admin
	function toggleIsClaimable() external;

	function setPotatoRewards(uint256 lockingDurationDays, uint256 potatoPerDay)
		external;

	function withdrawFunds() external;

	function emergencyWithdrawFarmers(uint256[] memory farmerIds) external;

	// Views
	function potatoPerDayByLockingDuration(uint256 lockingDurationDays)
		external
		view
		returns (uint256 _potatoPerDay);

	function claimedBlocksByFarmerId(uint256 farmerId)
		external
		view
		returns (uint256 _claimedBlocks);

	function isUnlocked(uint256 farmerId)
		external
		view
		returns (bool _isUnlocked);

	function getLatestDepositBlock(uint256 farmerId)
		external
		view
		returns (uint256);

	function getClaimableBlocksByBlock(uint256 farmerId, uint256 blockNumber)
		external
		view
		returns (uint256);

	function getClaimableBlocks(uint256 farmerId)
		external
		view
		returns (uint256);

	function unlockBlockByFarmerId(uint256 farmerId)
		external
		view
		returns (uint256);

	function getClaimableBlocksByBlockBatch(
		uint256[] memory farmerIds,
		uint256 blockNumber
	) external view returns (uint256[] memory _claimableBlocks);

	function getClaimableBlocksBatch(uint256[] memory farmerIds)
		external
		view
		returns (uint256[] memory _claimableBlocks);

	function getDepositor(uint256 farmerId)
		external
		view
		returns (address _depositor);

	function getDepositorBatch(uint256[] memory farmerIds)
		external
		view
		returns (address[] memory _depositors);

	function isStaked(uint256 farmerId) external view returns (bool);

	function isStakedBatch(uint256[] memory farmerIds)
		external
		view
		returns (bool[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

enum Character {
	HONEST_FARMER,
	FARM_GIRL
}

interface ITheFarmV2 {
	function stakeCharacter(
		Character character,
		uint256 characterId,
		uint256 lockingDurationEpochs
	) external;

	function stakeCharacterBatch(
		Character[] memory characters,
		uint256[] memory characterIds,
		uint256[] memory lockingDurationEpochs
	) external;

	function claimEpochs(Character character, uint256 characterId) external;

	function claimEpochsBatch(
		Character[] memory characters,
		uint256[] memory characterIds
	) external;

	function withdrawCharacter(Character character, uint256 characterId)
		external;

	function withdrawCharacterBatch(
		Character[] memory characters,
		uint256[] memory characterIds
	) external;

	// Administrative
	function emergencyWithdrawCharacter(
		Character character,
		uint256 characterId
	) external;

	function setEpochBlocks(uint256 _epochBlocks) external;

	function setPotatoPerEpoch(Character character, uint256 _potatoPerEpoch)
		external;

	// Views

	function isStaked(Character character, uint256 characterId)
		external
		view
		returns (bool);

	function isStakedBatch(
		Character[] memory characters,
		uint256[] memory characterIds
	) external view returns (bool[] memory);

	function isUnlocked(Character character, uint256 characterId)
		external
		view
		returns (bool _isUnlocked, uint256 _lockingDurationEpochs);

	function isUnlockedBatch(
		Character[] memory character,
		uint256[] memory characterId
	)
		external
		view
		returns (
			bool[] memory _isUnlocked,
			uint256[] memory _lockingDurationEpochs
		);

	function getDepositor(Character character, uint256 characterId)
		external
		view
		returns (address _depositor);

	function getDepositorBatch(
		Character[] memory characters,
		uint256[] memory characterIds
	) external view returns (address[] memory _depositors);

	function getDepositorV2(Character character, uint256 characterId)
		external
		view
		returns (address _depositor);

	function getDepositorBatchV2(
		Character[] memory characters,
		uint256[] memory characterIds
	) external view returns (address[] memory _depositors);

	function getClaimableEpochs(Character character, uint256 characterId)
		external
		view
		returns (uint256 _claimableEpochs, uint256 _claimableBlocks);

	function getClaimableEpochsBatch(
		Character[] memory characters,
		uint256[] memory characterIds
	)
		external
		view
		returns (
			uint256[] memory _claimableEpochs,
			uint256[] memory _claimableBlocks
		);

	// Events
	event StakeCharacter(
		Character indexed character,
		uint256 indexed characterId,
		uint256 lockingDurationEpochs
	);

	event MintStakingReward(
		Character indexed character,
		uint256 indexed characterId,
		uint256 potato
	);

	event WithdrawCharacter(Character character, uint256 characterId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";

interface IPotato is IERC20Metadata {
	function mintReward(
		uint8 rewardType,
		address recipient,
		uint256 amount
	) external;

	function mintAsDelegate(
		address recipient,
		uint256 amount,
		string memory reason
	) external;

	function emergencyFreeze() external;

	function unfreeze() external;

	function burn(uint256 amount) external;

	function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

import "./interfaces/IHonestChickens.sol";
import "./interfaces/IMetaChickens.sol";
import "../interfaces/IRegistryFarmerV2.sol";
import "../interfaces/IHonestFarmerClubV2.sol";
import "../FarmGirls/interfaces/IFarmGirlsERC1155.sol";
import "../interfaces/ITheFarm.sol";
import "../interfaces/ITheFarmV2.sol";
import "../interfaces/IPotatoBurnable.sol";

/// @author Howdy Games
/// @title Just some honest chickens
contract HonestChickens is
	IHonestChickens,
	RegistryFarmerV2Consumer,
	Initializable,
	ERC1155Upgradeable,
	OwnableUpgradeable,
	ERC1155BurnableUpgradeable,
	ERC1155SupplyUpgradeable
{
	using CountersUpgradeable for CountersUpgradeable.Counter;

	string public name;
	string public symbol;
	string public contractURI;
	uint256 public constant MAX_SUPPLY = 3000;
	bool public isLive;

	mapping(MintPriceType => uint256) public mintPricePotatoByPriceType;

	CountersUpgradeable.Counter private numberOfChickensBreeded;

	function initialize(string memory _contractURI, address _registryFarmerV2)
		public
		initializer
	{
		__ERC1155_init("");
		__Ownable_init();
		__ERC1155Burnable_init();
		__ERC1155Supply_init();

		name = "Howdy Games Chickens";
		symbol = "HFCC";
		contractURI = _contractURI;

		// Mint prices
		mintPricePotatoByPriceType[MintPriceType.NONE] = 1000 * 10**18;
		mintPricePotatoByPriceType[MintPriceType.FARMER_OR_FARM_GIRL] =
			800 *
			10**18;
		mintPricePotatoByPriceType[MintPriceType.FARMER_AND_FARM_GIRL] =
			600 *
			10**18;

		_setRegistryFarmer(_registryFarmerV2);
	}

	modifier mintIsLive() {
		require(isLive, "Mint is not live");
		_;
	}

	function _mintChickens(
		uint256 numberOfChickens,
		uint256 chickenMintPricePotato
	) private {
		uint256 newChickenSupply = numberOfChickensBreeded.current() +
			numberOfChickens;
		require(
			newChickenSupply <= MAX_SUPPLY,
			"Minting would exceed maximum supply"
		);

		uint256 totalPotatoCost = numberOfChickens * chickenMintPricePotato;
		IPotato potato = IPotato(_getRegistryFarmer().getContract("Potato"));
		potato.burnFrom(msg.sender, totalPotatoCost);

		uint256[] memory ids = new uint256[](numberOfChickens);
		uint256[] memory amounts = new uint256[](numberOfChickens);

		for (uint256 i = 0; i < numberOfChickens; i++) {
			numberOfChickensBreeded.increment();
			uint256 id = numberOfChickensBreeded.current();

			ids[i] = id;
			amounts[i] = 1;

			emit MintChicken(msg.sender, id);
		}

		_mintBatch(msg.sender, ids, amounts, "");
	}

	function mintChickens(uint256 numberOfChickens) public mintIsLive {
		_mintChickens(
			numberOfChickens,
			mintPricePotatoByPriceType[MintPriceType.NONE]
		);
	}

	function mintChickensWithFarmer(uint256 numberOfChickens, uint256 farmerId)
		public
		mintIsLive
	{
		require(_isFarmerHolder(farmerId), "Must hold farmer");

		_mintChickens(
			numberOfChickens,
			mintPricePotatoByPriceType[MintPriceType.FARMER_OR_FARM_GIRL]
		);
	}

	function mintChickensWithFarmGirl(
		uint256 numberOfChickens,
		uint256 farmGirlId
	) public mintIsLive {
		require(_isFarmGirlHolder(farmGirlId), "Must hold farm girl");

		_mintChickens(
			numberOfChickens,
			mintPricePotatoByPriceType[MintPriceType.FARMER_OR_FARM_GIRL]
		);
	}

	function mintChickensWithFarmerAndFarmGirl(
		uint256 numberOfChickens,
		uint256 farmerId,
		uint256 farmGirlId
	) public mintIsLive {
		require(
			_isFarmerHolder(farmerId) && _isFarmGirlHolder(farmGirlId),
			"Must hold both farmer and farm girl"
		);

		_mintChickens(
			numberOfChickens,
			mintPricePotatoByPriceType[MintPriceType.FARMER_AND_FARM_GIRL]
		);
	}

	function uri(uint256 id) public view override returns (string memory) {
		return
			IMetaChickens(_getRegistryFarmer().getContract("MetaChickens")).uri(
				id
			);
	}

	function uriBatch(uint256[] memory ids)
		public
		view
		returns (string[] memory _uris)
	{
		string[] memory uris = new string[](ids.length);

		for (uint256 i = 0; i < ids.length; i++) {
			uint256 id = ids[i];
			uris[i] = uri(id);
		}

		return uris;
	}

	// Utils
	function _isFarmerHolder(uint256 farmerId)
		private
		view
		returns (bool _isHolder)
	{
		IHonestFarmerClubV2 honestFarmerClub = IHonestFarmerClubV2(
			_getRegistryFarmer().getContract("HonestFarmerClub")
		);
		ITheFarm theFarm = ITheFarm(
			_getRegistryFarmer().getContract("TheFarm")
		);

		bool isHolder = honestFarmerClub.balanceOf(msg.sender, farmerId) == 1;
		bool isStaker = theFarm.getDepositor(farmerId) == msg.sender;

		return isHolder || isStaker;
	}

	function _isFarmGirlHolder(uint256 farmGirlId)
		private
		view
		returns (bool _isHolder)
	{
		IFarmGirls farmGirls = IFarmGirls(
			_getRegistryFarmer().getContract("FarmGirls")
		);
		ITheFarmV2 theFarmV2 = ITheFarmV2(
			_getRegistryFarmer().getContract("TheFarmV2")
		);

		bool isHolder = farmGirls.balanceOf(msg.sender, farmGirlId) == 1;
		bool isStaker = theFarmV2.getDepositor(
			Character.FARM_GIRL,
			farmGirlId
		) == msg.sender;

		return isHolder || isStaker;
	}

	// Administrative
	function setRegistryFarmer(address _registryFarmerV2)
		public
		override
		onlyOwner
	{
		_setRegistryFarmer(_registryFarmerV2);
	}

	function toggleIsLive() public onlyOwner {
		isLive = !isLive;
	}

	function _beforeTokenTransfer(
		address operator,
		address from,
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) internal override(ERC1155Upgradeable, ERC1155SupplyUpgradeable) {
		super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
	}

	/**
	 * Override isApprovedForAll to auto-approve OS's proxy contract
	 */
	function isApprovedForAll(address _owner, address _operator)
		public
		view
		override
		returns (bool isOperator)
	{
		return
			_operator == address(0x207Fa8Df3a17D96Ca7EA4f2893fcdCb78a304101) ||
			ERC1155Upgradeable.isApprovedForAll(_owner, _operator);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";

interface IPotatoChip is IERC20Metadata {
	function mintReward(
		uint8 rewardType,
		address recipient,
		uint256 amount
	) external;

	function mintAsDelegate(
		address recipient,
		uint256 amount,
		string memory reason
	) external;

	function emergencyFreeze() external;

	function unfreeze() external;

	function burn(uint256 amount) external;

	function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155Upgradeable.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

library LibraryFarmer {
	// Metadata
	enum Passion {
		Harvesting,
		Fishing,
		Planting
	}

	enum Skill {
		Degen,
		Honesty,
		Fitness,
		Strategy,
		Patience,
		Agility
	}

	enum VisualTraitType {
		Background,
		Skin,
		Clothing,
		Mouth,
		Nose,
		Head,
		Eyes,
		Ears
	}

	struct FarmerMetadata {
		uint256 internalTokenId;
		uint8[8] visualTraitValueIds;
		bool isSpecial;
		string ipfsHash;
	}

	// Mint
	enum MintType {
		PUBLIC,
		WHITELIST,
		FREE
	}

	function isWhitelistMintType(LibraryFarmer.MintType mintType)
		public
		pure
		returns (bool)
	{
		return mintType == LibraryFarmer.MintType.WHITELIST;
	}

	// Infrastructure
	enum FarmerContract {
		HonestFarmerClubV1,
		HonestFarmerClubV2,
		EnergyFarmer,
		MetaFarmer,
		MigrationTractor,
		OnchainArtworkFarmer,
		RevealFarmer,
		WhitelistFarmer
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/extensions/IERC20Metadata.sol";

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
pragma solidity ^0.8.14;

enum MintPriceType {
	NONE,
	FARMER_OR_FARM_GIRL,
	FARMER_AND_FARM_GIRL
}

interface IHonestChickens {
	function mintChickens(uint256 numberOfChickens) external;

	function mintChickensWithFarmer(uint256 numberOfChickens, uint256 farmerId)
		external;

	function mintChickensWithFarmGirl(
		uint256 numberOfChickens,
		uint256 farmGirlId
	) external;

	function mintChickensWithFarmerAndFarmGirl(
		uint256 numberOfChickens,
		uint256 farmerId,
		uint256 farmGirlId
	) external;

	event MintChicken(address indexed minter, uint256 indexed id);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

enum CHICKEN_LEVEL_COLOR {
	WHITE,
	YELLOW,
	GREEN,
	BLUE,
	RED,
	PURPLE
}

interface IMetaChickens {
	function uri(uint256 id) external view returns (string memory);

	function setIpfsHashByColor(
		CHICKEN_LEVEL_COLOR color,
		string memory ipfsHash
	) external;

	function recordChickenGame(uint256 id) external;
}