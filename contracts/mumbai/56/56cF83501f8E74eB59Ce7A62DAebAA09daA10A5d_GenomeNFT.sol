// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/ERC1155/extensions/ERC1155URIStorage.sol";
import "../access/Ownable.sol";

contract GenomeNFT is ERC1155URIStorage, Ownable {
	address private _marketplace = address(0);

	constructor() ERC1155("uri") {}

	function mint(
		address account,
		uint256 id,
		uint256 amount,
		bytes calldata data
	) public virtual {
		require(
			msg.sender == owner() || msg.sender == _marketplace,
			"Only can mint by owner or marketplace"
		);
		_mint(account, id, amount, data);
	}

	function setURI(uint256 tokenId, string memory tokenURI) public virtual {
		require(
			msg.sender == owner() || msg.sender == _marketplace,
			"Only can be set by owner or marketplace"
		);
		_setURI(tokenId, tokenURI);
	}

	function setMarketplace(address marketplace) public onlyOwner {
		_marketplace = marketplace;
	}

	function getMarketplace() public view returns (address) {
		return _marketplace;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../../utils/Strings.sol";
import "../ERC1155.sol";

abstract contract ERC1155URIStorage is ERC1155 {
	using Strings for uint256;

	// Optional base URI
	string private _baseURI = "";

	// Optional mapping for token URIs
	mapping(uint256 => string) private _tokenURIs;

	function uri(uint256 tokenId)
		public
		view
		virtual
		override
		returns (string memory)
	{
		string memory tokenURI = _tokenURIs[tokenId];

		// If token URI is set, concatenate base URI and tokenURI (via abi.encodePacked).
		return
			bytes(tokenURI).length > 0
				? string(abi.encodePacked(_baseURI, tokenURI))
				: super.uri(tokenId);
	}

	function _setURI(uint256 tokenId, string memory tokenURI)
		internal
		virtual
	{
		_tokenURIs[tokenId] = tokenURI;
		emit URI(uri(tokenId), tokenId);
	}

	function _setBaseURI(string memory baseURI) internal virtual {
		_baseURI = baseURI;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

abstract contract Ownable is Context {
	address private _owner;

	event OwnershipTransferred(
		address indexed previousOwner,
		address indexed newOwner
	);

	constructor() {
		_transferOwnership(_msgSender());
	}

	function owner() public view virtual returns (address) {
		return _owner;
	}

	modifier onlyOwner() {
		require(owner() == _msgSender(), "Ownable: caller is not the owner");
		_;
	}

	function renounceOwnership() public virtual onlyOwner {
		_transferOwnership(address(0));
	}

	function transferOwnership(address newOwner) public virtual onlyOwner {
		require(
			newOwner != address(0),
			"Ownable: new owner is the zero address"
		);
		_transferOwnership(newOwner);
	}

	function _transferOwnership(address newOwner) internal virtual {
		address oldOwner = _owner;
		_owner = newOwner;
		emit OwnershipTransferred(oldOwner, newOwner);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Strings {
	bytes16 private constant alphabet = "0123456789abcdef";

	function toString(uint256 value) internal pure returns (string memory) {
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

	function toHexString(uint256 value)
		internal
		pure
		returns (string memory)
	{
		if (value == 0) {
			return "0x00";
		}

		uint256 temp = value;
		uint256 length = 0;
		while (temp != 0) {
			length++;
			temp >>= 8;
		}
		return toHexString(value, length);
	}

	function toHexString(uint256 value, uint256 length)
		internal
		pure
		returns (string memory)
	{
		bytes memory buffer = new bytes(2 * length + 2);
		buffer[0] = "0";
		buffer[1] = "x";
		for (uint256 i = 2 * length + 1; i > 1; i--) {
			buffer[i] = alphabet[value & 0xf];
			value >>= 4;
		}
		require(value == 0, "Strings: hex length insufficient");
		return string(buffer);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
	using Address for address;

	mapping(uint256 => mapping(address => uint256)) private _balances;

	mapping(address => mapping(address => bool)) private _operatorApprovals;

	string private _uri;

	constructor(string memory uri_) {
		_setURI(uri_);
	}

	function supportsInterface(bytes4 interfaceId)
		public
		view
		virtual
		override(ERC165, IERC165)
		returns (bool)
	{
		return
			interfaceId == type(IERC1155).interfaceId ||
			interfaceId == type(IERC1155MetadataURI).interfaceId ||
			super.supportsInterface(interfaceId);
	}

	function uri(uint256)
		public
		view
		virtual
		override
		returns (string memory)
	{
		return _uri;
	}

	function balanceOf(address account, uint256 id)
		public
		view
		virtual
		override
		returns (uint256)
	{
		require(
			account != address(0),
			"ERC1155: balance query for the zero address"
		);
		return _balances[id][account];
	}

	function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
		public
		view
		virtual
		override
		returns (uint256[] memory)
	{
		require(
			accounts.length == ids.length,
			"ERC1155: accounts and ids length mismatch"
		);

		uint256[] memory batchBalances = new uint256[](accounts.length);

		for (uint256 i = 0; i < accounts.length; i++) {
			batchBalances[i] = balanceOf(accounts[i], ids[i]);
		}

		return batchBalances;
	}

	function setApprovalForAll(address operator, bool approved)
		public
		virtual
		override
	{
		require(
			_msgSender() != operator,
			"ERC1155: setting approval status for self"
		);

		_operatorApprovals[_msgSender()][operator] = approved;
		emit ApprovalForAll(_msgSender(), operator, approved);
	}

	function isApprovedForAll(address account, address operator)
		public
		view
		virtual
		override
		returns (bool)
	{
		return _operatorApprovals[account][operator];
	}

	function safeTransferFrom(
		address from,
		address to,
		uint256 id,
		uint256 amount,
		bytes memory data
	) public virtual override {
		require(to != address(0), "ERC1155: transfer to the zero address");
		require(
			from == _msgSender() || isApprovedForAll(from, _msgSender()),
			"ERC1155: caller is not owner nor approved"
		);

		address operator = _msgSender();

		_beforeTokenTransfer(
			operator,
			from,
			to,
			_asSingletonArray(id),
			_asSingletonArray(amount),
			data
		);

		uint256 fromBalance = _balances[id][from];
		require(
			fromBalance >= amount,
			"ERC1155: insufficient balance for transfer"
		);
		_balances[id][from] = fromBalance - amount;
		_balances[id][to] += amount;

		emit TransferSingle(operator, from, to, id, amount);

		_doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
	}

	function safeBatchTransferFrom(
		address from,
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) public virtual override {
		require(
			ids.length == amounts.length,
			"ERC1155: ids and amounts length mismatch"
		);
		require(to != address(0), "ERC1155: transfer to the zero address");
		require(
			from == _msgSender() || isApprovedForAll(from, _msgSender()),
			"ERC1155: transfer caller is not owner nor approved"
		);

		address operator = _msgSender();

		_beforeTokenTransfer(operator, from, to, ids, amounts, data);

		for (uint256 i = 0; i < ids.length; ++i) {
			uint256 id = ids[i];
			uint256 amount = amounts[i];

			uint256 fromBalance = _balances[id][from];
			require(
				fromBalance >= amount,
				"ERC1155: insufficient balance for transfer"
			);
			_balances[id][from] = fromBalance - amount;
			_balances[id][to] += amount;
		}

		emit TransferBatch(operator, from, to, ids, amounts);

		_doSafeBatchTransferAcceptanceCheck(
			operator,
			from,
			to,
			ids,
			amounts,
			data
		);
	}

	function _setURI(string memory newuri) internal virtual {
		_uri = newuri;
	}

	function _mint(
		address account,
		uint256 id,
		uint256 amount,
		bytes memory data
	) internal virtual {
		require(account != address(0), "ERC1155: mint to the zero address");

		address operator = _msgSender();

		_beforeTokenTransfer(
			operator,
			address(0),
			account,
			_asSingletonArray(id),
			_asSingletonArray(amount),
			data
		);

		_balances[id][account] += amount;
		emit TransferSingle(operator, address(0), account, id, amount);

		_doSafeTransferAcceptanceCheck(
			operator,
			address(0),
			account,
			id,
			amount,
			data
		);
	}

	function _mintBatch(
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) internal virtual {
		require(to != address(0), "ERC1155: mint to the zero address");
		require(
			ids.length == amounts.length,
			"ERC1155: ids and amounts length mismatch"
		);

		address operator = _msgSender();

		_beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

		for (uint256 i = 0; i < ids.length; i++) {
			_balances[ids[i]][to] += amounts[i];
		}

		emit TransferBatch(operator, address(0), to, ids, amounts);

		_doSafeBatchTransferAcceptanceCheck(
			operator,
			address(0),
			to,
			ids,
			amounts,
			data
		);
	}

	function _burn(
		address account,
		uint256 id,
		uint256 amount
	) internal virtual {
		require(account != address(0), "ERC1155: burn from the zero address");

		address operator = _msgSender();

		_beforeTokenTransfer(
			operator,
			account,
			address(0),
			_asSingletonArray(id),
			_asSingletonArray(amount),
			""
		);

		uint256 accountBalance = _balances[id][account];
		require(
			accountBalance >= amount,
			"ERC1155: burn amount exceeds balance"
		);
		_balances[id][account] = accountBalance - amount;

		emit TransferSingle(operator, account, address(0), id, amount);
	}

	function _burnBatch(
		address account,
		uint256[] memory ids,
		uint256[] memory amounts
	) internal virtual {
		require(account != address(0), "ERC1155: burn from the zero address");
		require(
			ids.length == amounts.length,
			"ERC1155: ids and amounts length mismatch"
		);

		address operator = _msgSender();

		_beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

		for (uint256 i = 0; i < ids.length; i++) {
			uint256 id = ids[i];
			uint256 amount = amounts[i];

			uint256 accountBalance = _balances[id][account];
			require(
				accountBalance >= amount,
				"ERC1155: burn amount exceeds balance"
			);
			_balances[id][account] = accountBalance - amount;
		}

		emit TransferBatch(operator, account, address(0), ids, amounts);
	}

	function _beforeTokenTransfer(
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
			try
				IERC1155Receiver(to).onERC1155Received(
					operator,
					from,
					id,
					amount,
					data
				)
			returns (bytes4 response) {
				if (response != IERC1155Receiver(to).onERC1155Received.selector) {
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
			try
				IERC1155Receiver(to).onERC1155BatchReceived(
					operator,
					from,
					ids,
					amounts,
					data
				)
			returns (bytes4 response) {
				if (
					response != IERC1155Receiver(to).onERC1155BatchReceived.selector
				) {
					revert("ERC1155: ERC1155Receiver rejected tokens");
				}
			} catch Error(string memory reason) {
				revert(reason);
			} catch {
				revert("ERC1155: transfer to non ERC1155Receiver implementer");
			}
		}
	}

	function _asSingletonArray(uint256 element)
		private
		pure
		returns (uint256[] memory)
	{
		uint256[] memory array = new uint256[](1);
		array[0] = element;

		return array;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

interface IERC1155 is IERC165 {
	event TransferSingle(
		address indexed operator,
		address indexed from,
		address indexed to,
		uint256 id,
		uint256 value
	);
	event TransferBatch(
		address indexed operator,
		address indexed from,
		address indexed to,
		uint256[] ids,
		uint256[] values
	);
	event ApprovalForAll(
		address indexed account,
		address indexed operator,
		bool approved
	);
	event URI(string value, uint256 indexed id);

	function balanceOf(address account, uint256 id)
		external
		view
		returns (uint256);

	function balanceOfBatch(
		address[] calldata accounts,
		uint256[] calldata ids
	) external view returns (uint256[] memory);

	function setApprovalForAll(address operator, bool approved) external;

	function isApprovedForAll(address account, address operator)
		external
		view
		returns (bool);

	function safeTransferFrom(
		address from,
		address to,
		uint256 id,
		uint256 amount,
		bytes calldata data
	) external;

	function safeBatchTransferFrom(
		address from,
		address to,
		uint256[] calldata ids,
		uint256[] calldata amounts,
		bytes calldata data
	) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

interface IERC1155Receiver is IERC165 {
	function onERC1155Received(
		address operator,
		address from,
		uint256 id,
		uint256 value,
		bytes calldata data
	) external returns (bytes4);

	function onERC1155BatchReceived(
		address operator,
		address from,
		uint256[] calldata ids,
		uint256[] calldata values,
		bytes calldata data
	) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155.sol";

interface IERC1155MetadataURI is IERC1155 {
	function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Address {
	function isContract(address account) internal view returns (bool) {
		uint256 size;
		assembly {
			size := extcodesize(account)
		}
		return size > 0;
	}

	function sendValue(address payable recipient, uint256 amount) internal {
		require(
			address(this).balance >= amount,
			"Address: insufficient balance"
		);

		(bool success, ) = recipient.call{ value: amount }("");
		require(
			success,
			"Address: unable to send value, recipient may have reverted"
		);
	}

	function functionCall(address target, bytes memory data)
		internal
		returns (bytes memory)
	{
		return functionCall(target, data, "Address: low-level call failed");
	}

	function functionCall(
		address target,
		bytes memory data,
		string memory errorMessage
	) internal returns (bytes memory) {
		return functionCallWithValue(target, data, 0, errorMessage);
	}

	function functionCallWithValue(
		address target,
		bytes memory data,
		uint256 value
	) internal returns (bytes memory) {
		return
			functionCallWithValue(
				target,
				data,
				value,
				"Address: low-level call with value failed"
			);
	}

	function functionCallWithValue(
		address target,
		bytes memory data,
		uint256 value,
		string memory errorMessage
	) internal returns (bytes memory) {
		require(
			address(this).balance >= value,
			"Address: insufficient balance for call"
		);
		require(isContract(target), "Address: call to non-contract");

		(bool success, bytes memory returndata) = target.call{ value: value }(
			data
		);
		return _verifyCallResult(success, returndata, errorMessage);
	}

	function functionStaticCall(address target, bytes memory data)
		internal
		view
		returns (bytes memory)
	{
		return
			functionStaticCall(
				target,
				data,
				"Address: low-level static call failed"
			);
	}

	function functionStaticCall(
		address target,
		bytes memory data,
		string memory errorMessage
	) internal view returns (bytes memory) {
		require(isContract(target), "Address: static call to non-contract");
		(bool success, bytes memory returndata) = target.staticcall(data);
		return _verifyCallResult(success, returndata, errorMessage);
	}

	function functionDelegateCall(address target, bytes memory data)
		internal
		returns (bytes memory)
	{
		return
			functionDelegateCall(
				target,
				data,
				"Address: low-level delegate call failed"
			);
	}

	function functionDelegateCall(
		address target,
		bytes memory data,
		string memory errorMessage
	) internal returns (bytes memory) {
		require(isContract(target), "Address: delegate call to non-contract");

		(bool success, bytes memory returndata) = target.delegatecall(data);
		return _verifyCallResult(success, returndata, errorMessage);
	}

	function _verifyCallResult(
		bool success,
		bytes memory returndata,
		string memory errorMessage
	) private pure returns (bytes memory) {
		if (success) {
			return returndata;
		} else {
			if (returndata.length > 0) {
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

abstract contract Context {
	function _msgSender() internal view virtual returns (address) {
		return msg.sender;
	}

	function _msgData() internal view virtual returns (bytes calldata) {
		this;
		return msg.data;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

abstract contract ERC165 is IERC165 {
	function supportsInterface(bytes4 interfaceId)
		public
		view
		virtual
		override
		returns (bool)
	{
		return interfaceId == type(IERC165).interfaceId;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC165 {
	function supportsInterface(bytes4 interfaceId)
		external
		view
		returns (bool);
}