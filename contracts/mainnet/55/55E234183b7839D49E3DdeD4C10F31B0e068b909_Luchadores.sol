// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./common/IChildToken.sol";
import "./common/ContextMixin.sol";
import "./common/NativeMetaTransaction.sol";
import "./lib/Base64.sol";

interface ILuchaNames {
	function getName(address originContract, uint256 id) external view returns (string memory);
}

contract Luchadores is ERC721Enumerable, IChildToken, AccessControl, NativeMetaTransaction, ContextMixin {
	using Strings for uint256;

	ILuchaNames public luchaNames;

	address luchadoresRoot = 0x8b4616926705Fb61E9C4eeAc07cd946a5D4b0760;

	struct Item {
		bytes12 name;
		string svg;
	}
	
	struct Art {
		string[] baseColor;
		string[] altColor;
		string[] eyeColor;
		string[] skinColor;
		mapping(uint256 => Item) spirit;
		mapping(uint256 => Item) cape;
		mapping(uint256 => Item) torso;
		mapping(uint256 => Item) arms;
		mapping(uint256 => Item) mask;
		mapping(uint256 => Item) mouth;
		mapping(uint256 => Item) bottoms;
		mapping(uint256 => Item) boots;
	}

	Art art;

	mapping(uint256 => uint256) luchadorDNAs;

	bool customNamesEnabled;
	bool dnaLocked;

	uint256 public constant BATCH_LIMIT = 20;
	event WithdrawnBatch(address indexed user, uint256[] tokenIds);

	bytes32 public constant DEPOSITOR_ROLE = keccak256("DEPOSITOR_ROLE");

	constructor(address _luchaNames, address childChainManager) ERC721("Luchadores", "LUCHADORES") {
		luchaNames = ILuchaNames(_luchaNames);

		_setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
		_setupRole(DEPOSITOR_ROLE, childChainManager);
		_initializeEIP712("Luchadores");

		art.baseColor = ["ebebf7", "1c1d2f", "cc0d3d", "d22f94", "890ec1", "1c49d8", "19b554", "13cac6", "f7c23c", "f18e2f"];
		art.altColor = ["dadae6", "13141f", "ea184d", "e0369f", "9511d2", "2854e6", "1da951", "11b9b5", "e8b63a", "e28327"];
		art.eyeColor = ["3b6ba5", "3b8fa5", "3ba599", "3ba577", "339842", "7fa53b", "a5823b", "a5693b", "844f1d", "4e2906"];
		art.skinColor = ["f9d1b7", "f7b897", "f39c77", "ffcb84", "bd7e47", "b97e4b", "b97a50", "5a3214", "50270e", "3a1b09"];
		art.spirit[0] = Item("Bull", "<path fill='#A9A18A' d='M21 2V1h-1V0h-1v2h1v1h-3v2h2v1h2V5h1V2zM5 3H4V2h1V0H4v1H3v1H2v3h1v1h2V5h2V3H6z'/><g fill='#000' opacity='.15'><path d='M21 4h1v1h-1zM19 5h-1v1h3V5h-1z'/><path d='M2 4h1v1H2zM4 5H3v1h3V5H5z'/></g>");
		art.spirit[1] = Item("Jaguar", "<path class='lucha-base' d='M6 2V1H5v5h1V5h1V3h1V2H7zM18 1v1h-2v1h1v2h1v1h1V1z'/><g fill='#000'><path d='M5 1h1v1H5zM6 2v1h2V2H7zM18 1h1v1h-1zM16 2v1h2V2h-1z' opacity='.3'/><path d='M6 3V2H5v4h1V5h1V3zM18 2v1h-1v2h1v1h1V2z' opacity='.2'/></g>");
		art.cape[0] = Item("Classic", "<path class='lucha-alt' d='M20 11H3v12h1v-1h2v-1h12v1h2v1h1V11z'/><g fill='#000'><path opacity='.2' d='M20 11v12h1V11zM3 12v11h1V11H3z'/><path opacity='.5' d='M19 11H4v11h2v-1h12v1h2V11z'/></g>");
		art.cape[1] = Item("Hooded", "<path class='lucha-alt' d='M20 11H3v12h1v-1h2v-1h12v1h2v1h1V11z'/><g fill='#000'><path opacity='.2' d='M20 11v12h1V11zM3 12v11h1V11H3z'/><path opacity='.5' d='M19 11H4v11h2v-1h12v1h2V11z'/></g>");
		art.torso[0] = Item("Shirt", "<path class='lucha-base' d='M22 12v-1h-1v-1h-1V9H4v1H3v1H2v1H1v5h4v-3h1v1h1v1h1v2h8v-2h1v-1h1v-1h1v3h4v-5z'/><path d='M22 12v-1h-1v-1h-1V9H4v1H3v1H2v1H1v5h4v-3h1v1h1v1h1v2h8v-2h1v-1h1v-1h1v3h4v-5z' fill='#000' opacity='.15'/>");
		art.torso[1] = Item("Open Shirt", "<path class='lucha-base' d='M10 9H4v1H3v1H2v1H1v3h4v-1h1v1h1v1h1v2h3V9zM22 12v-1h-1v-1h-1V9h-7v9h3v-2h1v-1h1v-1h1v1h4v-3z'/><path d='M10 9H4v1H3v1H2v1H1v3h4v-1h1v1h1v1h1v2h3V9zM22 12v-1h-1v-1h-1V9h-7v9h3v-2h1v-1h1v-1h1v1h4v-3z' fill='#000' opacity='.15'/>");
		art.torso[2] = Item("Singlet", "<path class='lucha-base' d='M16 9H7v3h1-1v4h1v1h8v-1h1v-4h-1 1V9z'/><path fill='#000' opacity='.15' d='M16 9H7v7h1v1h8v-1h1V9z'/>");
		art.torso[3] = Item("Suspenders", "<path class='lucha-base' d='M15 9v9h1V9zM8 10v8h1V9H8z'/><path d='M8 10v8h1V9H8zM15 9v9h1V9z' fill='#000' opacity='.15'/>");
		art.arms[0] = Item("Gloves", "<path class='lucha-base' d='M5 16H1v3h4v-1h1v-1H5zM22 16h-3v1h-1v1h1v1h4v-3z'/><path class='lucha-alt' d='M3 16H1v1h4v-1H4zM22 16h-3v1h4v-1z'/>");
		art.arms[1] = Item("Wrist Bands", "<path class='lucha-base' d='M3 15H1v2h4v-2H4zM22 15h-3v2h4v-2z'/>");
		art.arms[2] = Item("Right Band", "<path class='lucha-alt' d='M4 14H1v1h4v-1z'/>");
		art.arms[3] = Item("Left Band", "<path class='lucha-base' d='M22 14h-3v1h4v-1z'/>");
		art.arms[4] = Item("Arm Bands", "<path class='lucha-base' d='M4 14H1v1h4v-1zM22 14h-3v1h4v-1z'/>");
		art.arms[5] = Item("Sleeves", "<path class='lucha-base' d='M22 14h-3v3h4v-3zM3 14H1v3h4v-3H4z'/><path class='lucha-alt' d='M22 14h-3v1h4v-1zM3 14H1v1h4v-1H4z'/>");
		art.mask[0] = Item("Split", "<path d='M11 0H9v1H8v1H7v1H6v2H5v5h1v2h1v1h1v1h1v1h3V0z'/>");
		art.mask[1] = Item("Cross", "<path d='M14 2h-1V0h-2v2H9v2h2v4h2V4h2V2zM12 13h-1v2h2v-2z'/>");
		art.mask[2] = Item("Fierce", "<path d='M17 3v1h-2v1h-1v1h-1v3h5V3zM11 8V6h-1V5H9V4H7V3H6v6h5zM11 13v2h2v-2h-1z'/>");
		art.mask[3] = Item("Striped", "<path d='M11 2h2V1h1V0h-4v1h1zM6 10v2h1v-1h1v-1H7zM17 10h-1v1h1v1h1v-2z'/><path d='M16 3h1V2h-1V1h-1v1h-1v1h-1v1h-2V3h-1V2H9V1H8v1H7v1h1v1h1v1h1v1h1v9h2V6h1V5h1V4h1z'/>");
		art.mask[4] = Item("Bolt", "<path d='M13 3h-3V2h1V1h1V0H9v1H8v1H7v1H6v2h3v1H8v2H7v2h1V9h1V8h1V7h1V6h1V5h1V4h1V3z'/>");
		art.mask[5] = Item("Winged", "<path d='M18 5V3h-1V2h-1v1h-1v1h-1v1h-1v1h-2V5h-1V4H9V3H8V2H7v1H6v2H5v5h1v2h1v-1h1v-1h3V9h2v1h3v1h1v1h1v-2h1V5z'/>");
		art.mask[6] = Item("Classic", "<path d='M18 5V3h-1V2h-1v2h-1v1h-1v1h-1v3h-2V6h-1V5H9V4H8V2H7v1H6v2H5v4h1v1h2v3h1v1h6v-1h1v-3h2V9h1V5z'/>");
		art.mask[7] = Item("Arrow", "<path d='M18 5V3h-1V2h-1V1h-1V0H9v1H8v1H7v1H6v2H5v5h1v2h1v1h1v1h1v1h1v-4h1V5H9V3h1V2h1V1h2v1h1v1h1v2h-2v6h1v4h1v-1h1v-1h1v-1h1v-2h1V5z'/>");
		art.mask[8] = Item("Dash", "<path d='M13 3V2h-2v2h2zM13 1V0h-2v1h1zM10 4H9V1H8v1H7v1H6v2H5v5h1v2h1v1h1v1h1v1h1v-2H9v-3h2V5h-1zM18 5V3h-1V2h-1V1h-1v3h-1v1h-1v5h2v3h-1v2h1v-1h1v-1h1v-1h1v-2h1V5z'/>");
		art.mouth[0] = Item("Moustache", "<path fill='#421c03' opacity='.9' d='M14 10H9v3h1v-2h4v2h1v-3z'/>");
		art.bottoms[0] = Item("Tights", "<path class='lucha-alt' d='M15 17H8v6h3v-3h2v3h3v-6z'/>");
		art.bottoms[1] = Item("Trunk Tights", "<path class='lucha-base' d='M15 17H8v3h8v-3z'/><path class='lucha-alt' d='M15 18v1h-2v4h3v-5zM9 19v-1H8v5h3v-4h-1z'/>");
		art.boots[0] = Item("Two Tone", "<path class='lucha-alt' d='M9 22H8v1H7v1h4v-2h-1zM16 23v-1h-3v2h4v-1z'/>");
		art.boots[1] = Item("High", "<path class='lucha-alt' d='M9 20H8v1h3v-1h-1zM15 20h-2v1h3v-1z'/>");
	}

	function imageData(uint256 _tokenId) public view returns (string memory) {
		require(_tokenId > 0 && _tokenId <= 10000, "imageData: Nonexistent token");

		uint8[12] memory dna = splitNumber(luchadorDNAs[_tokenId]);

		string memory capeShoulders = (dna[1] == 0 || dna[1] == 1)? "<path class='lucha-alt' d='M20 10V9h-2v1h-1v1h4v-1zM5 9H4v1H3v1h4v-1H6V9z'/><path fill='#000' opacity='.2' d='M6 9H4v1H3v1h4v-1H6zM20 10V9h-2v1h-1v1h4v-1z'/>" : "";
		string memory capeHood = dna[1] == 1 ? "<path class='lucha-alt' d='M18 4V3h-1V2h-1V1h-1V0H9v1H8v1H7v1H6v2H5v5h1V6h1V5h2V4h1V3h4v1h1v1h2v1h1v4h1V5h-1z'/><g fill='#000'><path d='M18 4V3h-1V2h-1V1h-1V0H9v1H8v1H7v1H6v2H5v5h1V5h1V4h1V3h1V2h6v1h1v1h1v1h1v5h1V5h-1z' opacity='.2'/><path d='M16 4V3h-1V2H9v1H8v1H7v1h2V4h1V3h4v1h1v1h2V4zM6 5h1v1H6zM17 5h1v1h-1z' opacity='.5'/></g>" : "";

		return string(abi.encodePacked(
			"<svg id='luchador", _tokenId.toString(), "' xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'>",
				styles(_tokenId, dna),
				"<g class='lucha-breathe'>",
					art.spirit[dna[0]].svg,
					art.cape[dna[1]].svg,
					"<path class='lucha-skin' d='M22 12v-1h-1v-1h-1V9h-1V5h-1V3h-1V2h-1V1h-1V0H9v1H8v1H7v1H6v2H5v4H4v1H3v1H2v1H1v8h4v-1h1v-2H5v-3h1v1h1v1h1v2h8v-2h1v-1h1v-1h1v3h-1v2h1v1h4v-8z'/>",
					art.torso[dna[2]].svg,
					art.arms[dna[3]].svg,
					capeShoulders,
					"<path class='lucha-base' d='M18 5V3h-1V2h-1V1h-1V0H9v1H8v1H7v1H6v2H5v5h1v2h1v1h1v1h1v1h6v-1h1v-1h1v-1h1v-2h1V5z'/>",
					"<g class='lucha-alt'>", art.mask[dna[4]].svg, "</g>",
					capeHood,
					"<path fill='#FFF' d='M9 6H6v3h4V6zM17 6h-3v3h4V6z'/><path class='lucha-eyes' d='M16 6h-2v3h3V6zM8 6H7v3h3V6H9z'/><path fill='#FFF' d='M7 6h1v1H7zM16 6h1v1h-1z' opacity='.4'/><path fill='#000' d='M15 7h1v1h-1zM8 7h1v1H8z'/>",
					"<path class='lucha-skin' d='M14 10H9v3h6v-3z'/>",
					"<path fill='#000' opacity='.9' d='M13 11h-3v1h4v-1z'/>",
					art.mouth[dna[5]].svg,
				"</g>",
				"<path class='lucha-skin' d='M16 23v-6H8v6H7v1h4v-4h2v4h4v-1z'/>",
				"<path class='lucha-base' d='M15 17H8v1h1v1h2v1h2v-1h2v-1h1v-1z'/>",
				art.bottoms[dna[6]].svg,
				"<path class='lucha-base' d='M9 21H8v2H7v1h4v-3h-1zM16 23v-2h-3v3h4v-1z'/>",
				art.boots[dna[7]].svg,
			"</svg>"
		));
	}

	function styles(uint256 _tokenId, uint8[12] memory _dna) internal view returns (string memory) {
		return string(abi.encodePacked(
			"<style>#luchador", _tokenId.toString(), " .lucha-base { fill: #", art.baseColor[_dna[8]],
				"; } #luchador", _tokenId.toString(), " .lucha-alt { fill: #", art.altColor[_dna[9]],
				"; } #luchador", _tokenId.toString(), " .lucha-eyes { fill: #", art.eyeColor[_dna[10]],
				"; } #luchador", _tokenId.toString(), " .lucha-skin { fill: #", art.skinColor[_dna[11]],
				"; } #luchador", _tokenId.toString(), " .lucha-breathe { animation: 0.5s lucha-breathe infinite alternate ease-in-out; } @keyframes lucha-breathe { from { transform: translateY(0px); } to { transform: translateY(1%); } }</style>"
		));
	}

	function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
		require(_tokenId > 0 && _tokenId <= 10000, "tokenURI: Nonexistent token");

		uint8[12] memory dna = splitNumber(luchadorDNAs[_tokenId]);

		Item[8] memory artItems = [
			art.spirit[dna[0]],
			art.cape[dna[1]],
			art.torso[dna[2]],
			art.arms[dna[3]],
			art.mask[dna[4]],
			art.mouth[dna[5]],
			art.bottoms[dna[6]],
			art.boots[dna[7]]
		];

		string memory attributes;

		string[8] memory traitType = ["Spirit", "Cape", "Torso", "Arms", "Mask", "Mouth", "Bottoms", "Boots"];

		for (uint256 i = 0; i < artItems.length; i++) {
			if (artItems[i].name == "") continue;

			attributes = string(abi.encodePacked(attributes,
				bytes(attributes).length == 0	? '{' : ', {',
					'"trait_type": "', traitType[i],'",',
					'"value": "', bytes12ToString(artItems[i].name), '"',
				'}'
			));
		}

		string memory customName = customNamesEnabled ? luchaNames.getName(luchadoresRoot, _tokenId) : '';
		string memory name = bytes(customName).length > 0 ? customName : string(abi.encodePacked('Luchador #', _tokenId.toString()));

		return string(abi.encodePacked(
			"data:application/json;base64,",
			Base64.encode(
				bytes(
					string(abi.encodePacked(
						'{',
							'"name": "', name, '",', 
							'"description": "Luchadores are randomly generated using Chainlink VRF and have 100% on-chain art and metadata - Only 10000 will ever exist!",',
							'"image_data": "', imageData(_tokenId), '",',
							'"external_url": "https://luchadores.io/luchador/', _tokenId.toString(), '",',
							'"attributes": [', attributes, ']',
						'}'
					))
				)
			)
		));
	}

	function splitNumber(uint256 _number) internal pure returns (uint8[12] memory) {
		uint8[12] memory numbers;

		for (uint256 i = 0; i < numbers.length; i++) {
			numbers[i] = uint8(_number % 10);
			_number /= 10;
		}

		return numbers;
	}

	function bytes12ToString(bytes12 _bytes12) internal pure returns (string memory) {
		uint8 i = 0;
		while(i < 12 && _bytes12[i] != 0) {
			i++;
		}

		bytes memory bytesArray = new bytes(i);
		for (i = 0; i < 12 && _bytes12[i] != 0; i++) {
			bytesArray[i] = _bytes12[i];
		}

		return string(bytesArray);
	}

	function setDNA(uint256[] calldata ids, uint256[] calldata dnas) external onlyRole(DEFAULT_ADMIN_ROLE) {
		require(!dnaLocked, "setDNA: locked");
		require(ids.length == dnas.length, "Array lengths do not match");

		for (uint256 i = 0; i < ids.length; i++) {
			luchadorDNAs[ids[i]] = dnas[i];
		}
	}

	function setCustomNamesEnabled(bool val) external onlyRole(DEFAULT_ADMIN_ROLE) {
		customNamesEnabled = val;
	}

	function lockDNA() external onlyRole(DEFAULT_ADMIN_ROLE) {
		dnaLocked = true;
	}

	// in case a luchador is accidentally sent to this contract
	function rescueLuchador(address to, uint256[] calldata tokenIds) external onlyRole(DEFAULT_ADMIN_ROLE) {
		for (uint256 i; i < tokenIds.length; i++) {
			_safeTransfer(address(this), to, tokenIds[i], "");
		}
	}

	// This is to support Native meta transactions
	// never use msg.sender directly, use _msgSender() instead
	function _msgSender() internal override view returns (address sender) {
		return ContextMixin.msgSender();
	}

	function deposit(address user, bytes calldata depositData) external override onlyRole(DEPOSITOR_ROLE) {
		// deposit single
		if (depositData.length == 32) {
			uint256 tokenId = abi.decode(depositData, (uint256));
			_mint(user, tokenId);
		// deposit batch
		} else {
			uint256[] memory tokenIds = abi.decode(depositData, (uint256[]));
			uint256 length = tokenIds.length;
			for (uint256 i; i < length; i++) {
				_mint(user, tokenIds[i]);
			}
		}
	}

	function withdraw(uint256 tokenId) external {
		require(_msgSender() == ownerOf(tokenId), "Invalid token owner");
		_burn(tokenId);
	}

	function withdrawBatch(uint256[] calldata tokenIds) external {
		uint256 length = tokenIds.length;
		require(length <= BATCH_LIMIT, "Batch limit exceeded");
		for (uint256 i; i < length; i++) {
			uint256 tokenId = tokenIds[i];
			require(_msgSender() == ownerOf(tokenId), string(abi.encodePacked("Invalid token owner", tokenId)));
			_burn(tokenId);
		}
		emit WithdrawnBatch(_msgSender(), tokenIds);
	}

	function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, AccessControl) returns (bool) {
		return super.supportsInterface(interfaceId);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT

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
        _checkRole(role, _msgSender());
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
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
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
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
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
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
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

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IChildToken {
  function deposit(address user, bytes calldata depositData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract ContextMixin {
	function msgSender()
		internal
		view
		returns (address payable sender)
	{
		if (msg.sender == address(this)) {
			bytes memory array = msg.data;
			uint256 index = msg.data.length;
			assembly {
				// Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
				sender := and(
					mload(add(array, index)),
					0xffffffffffffffffffffffffffffffffffffffff
				)
			}
		} else {
			sender = payable(msg.sender);
		}
		return sender;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./EIP712Base.sol";

contract NativeMetaTransaction is EIP712Base {
	bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(
		bytes(
			"MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
		)
	);
	event MetaTransactionExecuted(
		address userAddress,
		address payable relayerAddress,
		bytes functionSignature
	);
	mapping(address => uint256) nonces;

	/*
		* Meta transaction structure.
		* No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
		* He should call the desired function directly in that case.
		*/
	struct MetaTransaction {
		uint256 nonce;
		address from;
		bytes functionSignature;
	}

	function executeMetaTransaction(
		address userAddress,
		bytes memory functionSignature,
		bytes32 sigR,
		bytes32 sigS,
		uint8 sigV
	) public payable returns (bytes memory) {
		MetaTransaction memory metaTx = MetaTransaction({
			nonce: nonces[userAddress],
			from: userAddress,
			functionSignature: functionSignature
		});

		require(
			verify(userAddress, metaTx, sigR, sigS, sigV),
			"Signer and signature do not match"
		);

		// increase nonce for user (to avoid re-use)
		++nonces[userAddress];

		emit MetaTransactionExecuted(
			userAddress,
			payable(msg.sender),
			functionSignature
		);

		// Append userAddress and relayer address at the end to extract it from calling context
		(bool success, bytes memory returnData) = address(this).call(
			abi.encodePacked(functionSignature, userAddress)
		);
		require(success, "Function call not successful");

		return returnData;
	}

	function hashMetaTransaction(MetaTransaction memory metaTx)
		internal
		pure
		returns (bytes32)
	{
		return
			keccak256(
				abi.encode(
					META_TRANSACTION_TYPEHASH,
					metaTx.nonce,
					metaTx.from,
					keccak256(metaTx.functionSignature)
				)
			);
	}

	function getNonce(address user) public view returns (uint256 nonce) {
		nonce = nonces[user];
	}

	function verify(
		address signer,
		MetaTransaction memory metaTx,
		bytes32 sigR,
		bytes32 sigS,
		uint8 sigV
	) internal view returns (bool) {
		require(signer != address(0), "NativeMetaTransaction: INVALID_SIGNER");
		return
			signer ==
			ecrecover(
				toTypedMessageHash(hashMetaTransaction(metaTx)),
				sigV,
				sigR,
				sigS
			);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
	bytes internal constant TABLE =
		"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

	/// @notice Encodes some bytes to the base64 representation
	function encode(bytes memory data) internal pure returns (string memory) {
		uint256 len = data.length;
		if (len == 0) return "";

		// multiply by 4/3 rounded up
		uint256 encodedLen = 4 * ((len + 2) / 3);

		// Add some extra buffer at the end
		bytes memory result = new bytes(encodedLen + 32);

		bytes memory table = TABLE;

		assembly {
			let tablePtr := add(table, 1)
			let resultPtr := add(result, 32)

			for {
					let i := 0
			} lt(i, len) {

			} {
				i := add(i, 3)
				let input := and(mload(add(data, i)), 0xffffff)

				let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
				out := shl(8, out)
				out := add(
					out,
					and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
				)
				out := shl(8, out)
				out := add(
					out,
					and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
				)
				out := shl(8, out)
				out := add(
					out,
					and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
				)
				out := shl(224, out)

				mstore(resultPtr, out)

				resultPtr := add(resultPtr, 4)
			}

			switch mod(len, 3)
			case 1 {
				mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
			}
			case 2 {
				mstore(sub(resultPtr, 1), shl(248, 0x3d))
			}

			mstore(result, encodedLen)
		}

		return string(result);
	}
}

// SPDX-License-Identifier: MIT

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
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
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
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
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
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

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
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
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
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
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

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
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
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

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
pragma solidity ^0.8.0;

import "./Initializable.sol";

contract EIP712Base is Initializable {
	struct EIP712Domain {
		string name;
		string version;
		address verifyingContract;
		bytes32 salt;
	}

	string constant public ERC712_VERSION = "1";

	bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(
		bytes(
			"EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
		)
	);
	bytes32 internal domainSeperator;

	// supposed to be called once while initializing.
	// one of the contractsa that inherits this contract follows proxy pattern
	// so it is not possible to do this in a constructor
	function _initializeEIP712(
		string memory name
	)
		internal
		initializer
	{
		_setDomainSeperator(name);
	}

	function _setDomainSeperator(string memory name) internal {
		domainSeperator = keccak256(
			abi.encode(
				EIP712_DOMAIN_TYPEHASH,
				keccak256(bytes(name)),
				keccak256(bytes(ERC712_VERSION)),
				address(this),
				bytes32(getChainId())
			)
		);
	}

	function getDomainSeperator() public view returns (bytes32) {
		return domainSeperator;
	}

	function getChainId() public view returns (uint256) {
		return block.chainid;
	}

	/**
		* Accept message hash and returns hash message in EIP712 compatible form
		* So that it can be used to recover signer from signature signed using EIP712 formatted data
		* https://eips.ethereum.org/EIPS/eip-712
		* "\\x19" makes the encoding deterministic
		* "\\x01" is the version byte to make it compatible to EIP-191
		*/
	function toTypedMessageHash(bytes32 messageHash)
		internal
		view
		returns (bytes32)
	{
		return
			keccak256(
				abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash)
			);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Initializable {
	bool inited = false;

	modifier initializer() {
		require(!inited, "already inited");
		_;
		inited = true;
	}
}