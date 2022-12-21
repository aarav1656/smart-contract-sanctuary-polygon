// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.4;

// @openzeppelin 4.4.1
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "./Base.sol";
import "./interfaces/IRaffleDrawV2.sol";
import "./interfaces/IChibiLuckyToken.sol";

contract RaffleDrawV2 is Base, IRaffleDrawV2 {
    /** --------------------STORAGE VARIABLES-------------------- */
    /**
     * raffle draws
     */
    mapping(uint256 => Draw) public raffleDraws;
    /**
     * the total number of raffle draws
     */
    uint256 public totalRaffleDraws;
    /**
     * draw metadata
     */
    mapping(uint256 => DrawMetadata) private _drawMetadata;
    /**
     * role for managing raffle draws
     */
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    /**
     * external contracts
     */
    ERC1155Burnable public luckyTokenContract;
    /**
     * raffle id counter
     */
    uint256 private _raffleDrawIdCounter;

    /** --------------------STORAGE VARIABLES-------------------- */

    /** --------------------EXTERNAL FUNCTIONS-------------------- */
    /**
     * see {IRaffleDraw-buyEntries}
     */
    function buyEntries(
        uint256 drawId,
        uint256[] calldata luckyTokenIds,
        uint256[] calldata numberOfTokens
    ) external override {
        // CHECK
        require(drawId <= totalRaffleDraws, "CHIBI:INVALID_ID");
        require(luckyTokenIds.length > 0, "CHIBI:INVALID_LUCKY_TOKENS");
        Draw memory draw = raffleDraws[drawId];
        require(draw.status == DrawStatus.ACTIVE, "CHIBI:INVALID_STATUS");
        require(
            draw.endDate >= block.timestamp,
            "CHIBI:TOO_LATE_TO_BUY_ENTRIES"
        );

        uint24 newEntries = uint24(
            _calculateNumberOfEntries(draw.tier, luckyTokenIds, numberOfTokens)
        );
        require(
            (draw.currentEntries + newEntries) <= draw.totalEntries,
            "CHIBI:EXCEED_MAXIMUM_AVAILABLE_ENTRIES"
        );
        require(
            (_drawMetadata[drawId].boughtEntries[msg.sender] + newEntries) <=
                draw.maxEntriesPerWallet,
            "CHIBI:EXCEED_MAXIMUM_AVAILABLE_ENTRIES_FOR_A_WALLET"
        );

        for (uint256 i = 0; i < luckyTokenIds.length; i++) {
            require(
                numberOfTokens[i] > 0,
                "CHIBI:NUMBER_OF_TOKEN_MUST_BE_GREATER_THAN_0"
            );
            require(
                numberOfTokens[i] <=
                    luckyTokenContract.balanceOf(msg.sender, luckyTokenIds[i]),
                "CHIBI:NOT_ENOUGH_TOKENS"
            );
        }
        require(
            luckyTokenContract.isApprovedForAll(msg.sender, address(this)),
            "CHIBI:NOT_ALLOWED_TO_BURN_LUCKY_TOKEN"
        );

        // EFFECTS
        // burn Lucky tokens before buying entries
        luckyTokenContract.burnBatch(msg.sender, luckyTokenIds, numberOfTokens);

        // ACTIONS
        // update currentEntries;
        raffleDraws[drawId].currentEntries += newEntries;
        // update unique players
        uint24 currentPlayers = raffleDraws[drawId].numberOfPlayers;
        uint256 currentBoughtEntries = _drawMetadata[drawId].boughtEntries[
            msg.sender
        ];
        if (currentBoughtEntries == 0) {
            // add a new unique player
            _drawMetadata[drawId].indexToPlayer[currentPlayers] = msg.sender;
            currentPlayers += 1;
            raffleDraws[drawId].numberOfPlayers = currentPlayers;
        }
        // update bought entries
        _drawMetadata[drawId].boughtEntries[msg.sender] =
            currentBoughtEntries +
            newEntries;

        emit RaffleDrawEntriesBought(drawId, msg.sender, newEntries);
    }

    /**
     * see {IRaffleDraw-findRaffleDraws}
     */
    function findRaffleDraws(uint256[] calldata drawIds)
        external
        view
        override
        returns (Draw[] memory draws)
    {
        draws = new Draw[](drawIds.length);
        for (uint256 i = 0; i < draws.length; i++) {
            draws[i] = raffleDraws[drawIds[i]];
        }
    }

    /**
     * see {IRaffleDraw-getDrawPlayerStatus}
     */
    function getDrawPlayerStatus(address player, uint256[] calldata drawIds)
        external
        view
        override
        returns (DrawPlayerStatus[] memory statuses)
    {
        statuses = new DrawPlayerStatus[](drawIds.length);
        for (uint256 i = 0; i < drawIds.length; i++) {
            Draw memory draw = raffleDraws[drawIds[i]];
            if (
                draw.status == DrawStatus.ACTIVE &&
                draw.endDate >= block.timestamp
            ) {
                uint256 walletAvailableEntries = draw.maxEntriesPerWallet -
                    _drawMetadata[drawIds[i]].boughtEntries[player];
                uint256 drawAvailableEntries = draw.totalEntries -
                    draw.currentEntries;
                bool canBuyEntries = walletAvailableEntries > 0 &&
                    drawAvailableEntries > 0;
                uint256 availableEntries = walletAvailableEntries;
                if (availableEntries > drawAvailableEntries) {
                    availableEntries = drawAvailableEntries;
                }
                statuses[i] = DrawPlayerStatus({
                    canBuyEntries: canBuyEntries,
                    availableEntries: availableEntries
                });
            }
        }
    }

    /**
     * see {IRaffleDraw-calculateNumberOfEntries}
     */
    function calculateNumberOfEntries(
        Tier tier,
        uint256[] calldata luckyTokenIds,
        uint256[] calldata numberOfTokens
    ) external pure override returns (uint256 numberOfEntries) {
        numberOfEntries = _calculateNumberOfEntries(
            tier,
            luckyTokenIds,
            numberOfTokens
        );
    }

    /**
     * see {IRaffleDraw-pickWinners}
     */
    function pickWinners(uint256 drawId)
        external
        override
        onlyRole(MANAGER_ROLE)
    {
        Draw memory draw = raffleDraws[drawId];
        require(drawId <= totalRaffleDraws, "CHIBI:INVALID_ID");
        require(draw.status == DrawStatus.ACTIVE, "CHIBI:INVALID_STATUS");
        require(draw.endDate < block.timestamp, "CHIBI:CANNOT_PICK_WINNER_YET");

        address[] memory winners;
        if (draw.numberOfPlayers <= draw.numberOfPrizes) {
            // all are winners
            winners = new address[](draw.numberOfPlayers);
            for (uint256 i = 0; i < draw.numberOfPlayers; i++) {
                winners[i] = _drawMetadata[drawId].indexToPlayer[i];
            }
        } else {
            winners = new address[](draw.numberOfPrizes);
            uint256 remainedTotalEntries;
            uint256 remainedPlayers = draw.numberOfPlayers;
            address[] memory players = new address[](draw.numberOfPlayers);
            uint256[] memory boughtEntries = new uint256[](
                draw.numberOfPlayers
            );

            for (uint256 i = 0; i < draw.numberOfPlayers; i++) {
                players[i] = _drawMetadata[drawId].indexToPlayer[i];
                boughtEntries[i] = _drawMetadata[drawId].boughtEntries[
                    players[i]
                ];
                remainedTotalEntries += boughtEntries[i];
            }

            for (uint256 i = 0; i < draw.numberOfPrizes; i++) {
                // get a random entry
                uint256 randomEntry = uint256(
                    keccak256(
                        abi.encodePacked(
                            block.difficulty,
                            block.number,
                            i == 0 ? address(0) : winners[i - 1], // previous winner
                            i
                        )
                    )
                ) % remainedTotalEntries;
                // find matching player
                uint256 checkedEntries = 0;
                for (uint256 j = 0; j < remainedPlayers; j++) {
                    checkedEntries += boughtEntries[i];
                    if (randomEntry < checkedEntries) {
                        // pick winner
                        winners[i] = players[j];
                        remainedTotalEntries -= boughtEntries[j];
                        if (j < remainedPlayers - 1) {
                            //switch last remained player to the current position
                            players[j] = players[remainedPlayers - 1];
                            boughtEntries[j] = boughtEntries[
                                remainedPlayers - 1
                            ];
                        }
                        break;
                    }
                }

                // decrease remained players
                remainedPlayers -= 1;
            }
        }

        emit RaffleDrawWinnerPicked(drawId, winners);

        raffleDraws[drawId].status = DrawStatus.COMPLETED;
        emit RaffleDrawStatusUpdated(drawId, DrawStatus.COMPLETED);
    }

    /**
     * see {IRaffleDraw-addRaffleDraw}
     */
    function addRaffleDraw(
        Tier tier,
        uint40 endDate,
        uint24 totalEntries,
        uint24 maxEntriesPerWallet,
        uint24 numberOfPrizes,
        string calldata name
    ) external override onlyRole(MANAGER_ROLE) {
        _raffleDrawIdCounter += 1;
        uint256 id = _raffleDrawIdCounter;
        raffleDraws[id] = Draw({
            tier: tier,
            status: DrawStatus.INACTIVE,
            endDate: endDate,
            totalEntries: totalEntries,
            maxEntriesPerWallet: maxEntriesPerWallet,
            numberOfPrizes: numberOfPrizes,
            numberOfPlayers: 0,
            name: name,
            description: "",
            imageUrl: "",
            currentEntries: 0
        });
        totalRaffleDraws += 1;

        emit RaffleDrawAdded(
            id,
            DrawStatus.INACTIVE,
            tier,
            endDate,
            totalEntries,
            maxEntriesPerWallet,
            numberOfPrizes,
            name
        );
    }

    /**
     * see {IRaffleDraw-updateRaffleDraw}
     */
    function updateRaffleDraw(
        uint256 id,
        Tier tier,
        uint40 endDate,
        uint24 totalEntries,
        uint24 maxEntriesPerWallet,
        uint24 numberOfPrizes
    ) external override onlyRole(MANAGER_ROLE) {
        require(id <= totalRaffleDraws, "CHIBI:INVALID_ID");
        require(
            raffleDraws[id].status == DrawStatus.INACTIVE,
            "CHIBI:INVALID_STATUS"
        );

        raffleDraws[id].tier = tier;
        raffleDraws[id].endDate = endDate;
        raffleDraws[id].totalEntries = totalEntries;
        raffleDraws[id].maxEntriesPerWallet = maxEntriesPerWallet;
        raffleDraws[id].numberOfPrizes = numberOfPrizes;

        emit RaffleDrawUpdated(
            id,
            tier,
            endDate,
            totalEntries,
            maxEntriesPerWallet,
            numberOfPrizes
        );
    }

    /**
     * see {IRaffleDraw-updateRaffleDrawDesc}
     */
    function updateRaffleDrawDesc(
        uint256 id,
        string calldata name,
        string calldata description,
        string calldata imageUrl
    ) external override onlyRole(MANAGER_ROLE) {
        require(id <= totalRaffleDraws, "CHIBI:INVALID_ID");
        require(
            raffleDraws[id].status == DrawStatus.INACTIVE,
            "CHIBI:INVALID_STATUS"
        );

        raffleDraws[id].name = name;
        raffleDraws[id].description = description;
        raffleDraws[id].imageUrl = imageUrl;

        emit RaffleDrawDescUpdated(id, name, description, imageUrl);
    }

    /**
     * see {IRaffleDraw-activateRaffleDraw}
     */
    function activateRaffleDraw(uint256 id, bool isActive)
        external
        override
        onlyRole(MANAGER_ROLE)
    {
        require(id <= totalRaffleDraws, "CHIBI:INVALID_ID");
        require(
            raffleDraws[id].status != DrawStatus.COMPLETED,
            "CHIBI:RAFFLE_DRAW_ALREADY_COMPLETED"
        );
        if (raffleDraws[id].status == DrawStatus.INACTIVE && isActive) {
            raffleDraws[id].status = DrawStatus.ACTIVE;
            emit RaffleDrawStatusUpdated(id, DrawStatus.ACTIVE);
        } else if (raffleDraws[id].status == DrawStatus.ACTIVE && !isActive) {
            require(
                raffleDraws[id].currentEntries == 0,
                "CHIBI:ENTRIES_ALREADY_BOUGHT"
            );
            raffleDraws[id].status = DrawStatus.INACTIVE;
            emit RaffleDrawStatusUpdated(id, DrawStatus.INACTIVE);
        }
    }

    /**
     * see {IRaffleDraw-setExternalContractAddresses}
     */
    function setExternalContractAddresses(address luckyTokenAddr)
        external
        override
        onlyOwner
    {
        luckyTokenContract = ERC1155Burnable(luckyTokenAddr);
    }

    /** --------------------EXTERNAL FUNCTIONS-------------------- */

    /** --------------------PRIVATE FUNCTIONS-------------------- */
    /**
     * calculate number of entries can be bought using luck tokens (based on tier)
     */
    function _calculateNumberOfEntries(
        Tier tier,
        uint256[] calldata luckyTokenIds,
        uint256[] calldata numberOfTokens
    ) private pure returns (uint256 numberOfEntries) {
        require(
            luckyTokenIds.length == numberOfTokens.length,
            "CHIBI:ARRAY_LENGTHS_MUST_MATCH"
        );
        for (uint256 i = 0; i < luckyTokenIds.length; i++) {
            if (tier == Tier.Common) {
                // Common Raffles: Gold(1) tokens = 4 entries, Silver(2) token = 2 entries, Bronze(3) token = 1 entry.
                require(
                    luckyTokenIds[i] >= 1 && luckyTokenIds[i] <= 3,
                    "CHIBI:INVALID_TOKEN_ID"
                );
                if (luckyTokenIds[i] == 1) {
                    numberOfEntries += 4 * numberOfTokens[i];
                } else if (luckyTokenIds[i] == 2) {
                    numberOfEntries += 2 * numberOfTokens[i];
                } else {
                    numberOfEntries += numberOfTokens[i];
                }
            } else if (tier == Tier.Rare) {
                // Rare Raffles: Gold token = 2 entries, Silver token = 1 entry.
                require(
                    luckyTokenIds[i] >= 1 && luckyTokenIds[i] <= 2,
                    "CHIBI:INVALID_TOKEN_ID"
                );
                if (luckyTokenIds[i] == 1) {
                    numberOfEntries += 2 * numberOfTokens[i];
                } else {
                    numberOfEntries += numberOfTokens[i];
                }
            } else {
                // Epic Raffles: Gold token = 1 entry.
                require(luckyTokenIds[i] == 1, "CHIBI:INVALID_TOKEN_ID");
                numberOfEntries += numberOfTokens[i];
            }
        }
    }
    /** --------------------PRIVATE FUNCTIONS-------------------- */
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/ERC1155Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC1155.sol";

/**
 * @dev Extension of {ERC1155} that allows token holders to destroy both their
 * own tokens and those that they have been approved to use.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155Burnable is ERC1155 {
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

// @openzeppelin 4.4.1
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./AccessControl.sol";
import "./interfaces/IBase.sol";

/**
 * Base contract
 */
abstract contract Base is IBase, AccessControl, ReentrancyGuard {
    /** --------------------EXTERNAL FUNCTIONS-------------------- */
    /**
     * see {IBase-withdrawAllERC20}
     */
    function withdrawAllERC20(IERC20 token)
        external
        override
        onlyOwner
        nonReentrant
    {
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "CHIBI::BALANCE_MUST_BE_GREATER_THAN_0");

        token.transfer(owner(), balance);
    }

    /**
     * see {IBase-withdrawERC721}
     */
    function withdrawERC721(IERC721 token, uint256[] calldata tokenIds)
        external
        override
        onlyOwner
        nonReentrant
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            token.safeTransferFrom(address(this), owner(), tokenIds[i]);
        }
    }
    /** --------------------EXTERNAL FUNCTIONS-------------------- */
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.4;

interface IRaffleDrawV2 {
    enum Tier {
        Common,
        Rare,
        Epic
    }

    enum DrawStatus {
        ACTIVE,
        COMPLETED,
        INACTIVE
    }

    struct Draw {
        uint40 endDate;
        uint24 totalEntries;
        uint24 currentEntries;
        uint24 maxEntriesPerWallet;
        uint24 numberOfPrizes;
        uint24 numberOfPlayers;
        DrawStatus status;
        Tier tier;
        string name;
        string description;
        string imageUrl;
    }

    struct DrawMetadata {
        // index start from 1
        mapping(uint256 => address) indexToPlayer;
        // number of bought entries of each player
        mapping(address => uint256) boughtEntries;
    }

    struct DrawPlayerStatus {
        bool canBuyEntries;
        uint256 availableEntries;
    }

    struct DrawWinner {
        uint256[] drawEntries;
        mapping(uint256 => bool) entryMapping;
    }

    event RaffleDrawAdded(
        uint256 indexed id,
        DrawStatus indexed status,
        Tier indexed tier,
        uint40 endDate,
        uint24 totalEntries,
        uint24 maxEntriesPerWallet,
        uint24 numberOfPrizes,
        string name
    );

    event RaffleDrawUpdated(
        uint256 indexed id,
        Tier indexed tier,
        uint40 endDate,
        uint24 totalEntries,
        uint24 maxEntriesPerWallet,
        uint24 numberOfPrizes
    );

    event RaffleDrawDescUpdated(
        uint256 indexed id,
        string name,
        string description,
        string imageUrl
    );

    event RaffleDrawStatusUpdated(uint256 indexed id, DrawStatus status);

    event RaffleDrawEntriesBought(
        uint256 indexed id,
        address player,
        uint256 boughtEntries
    );

    event RaffleDrawWinnerPicked(uint256 indexed id, address[] winners);

    /**
     * buy entries in a Raffle Draw with Luck tokens
     * Common Raffles: Gold tokens = 4 entries, Silver token = 2 entries, Bronze token = 1 entry.
     * Rare Raffles: Gold token = 2 entries, Silver token = 1 entry.
     * Epic Raffles: Gold token = 1 entry.
     */
    function buyEntries(
        uint256 drawId,
        uint256[] calldata luckyTokenIds,
        uint256[] calldata numberOfTokens
    ) external;

    /**
     * find draws
     */
    function findRaffleDraws(uint256[] calldata drawIds)
        external
        view
        returns (Draw[] memory draws);

    /**
     * get draw status for a player
     */
    function getDrawPlayerStatus(address player, uint256[] calldata drawIds)
        external
        view
        returns (DrawPlayerStatus[] memory statuses);

    /**
     * calculate number of entries can be bought using luck tokens (based on tier)
     */
    function calculateNumberOfEntries(
        Tier tier,
        uint256[] calldata luckyTokenIds,
        uint256[] calldata numberOfTokens
    ) external pure returns (uint256 numberOfEntries);

    /**
     * pick winners - manager only
     */
    function pickWinners(uint256 drawId) external;

    /**
     * add new raffle draw
     */
    function addRaffleDraw(
        Tier tier,
        uint40 endDate,
        uint24 totalEntries,
        uint24 maxEntriesPerWallet,
        uint24 numberOfPrizes,
        string calldata name
    ) external;

    /**
     * update raffle draw end date
     */
    function updateRaffleDraw(
        uint256 id,
        Tier tier,
        uint40 endDate,
        uint24 totalEntries,
        uint24 maxEntriesPerWallet,
        uint24 numberOfPrizes
    ) external;

    /**
     * update raffle draw description
     */
    function updateRaffleDrawDesc(
        uint256 id,
        string calldata name,
        string calldata description,
        string calldata imageUrl
    ) external;

    /**
     * set raffle draw status
     */
    function activateRaffleDraw(uint256 id, bool isActive) external;

    /**
     * set external contract addresses
     */
    function setExternalContractAddresses(address luckyTokenAddr) external;
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.4;

interface IChibiLuckyToken {
    /**
     * free mint, each wallet can only mint one token
     */
    function freeMint() external;

    /**
     * mint tokens with $SHIN
     */
    function mintWithShin(uint256 numberOfTokens) external;

    /**
     * mint tokens with Seals. Each seal can only be used once.
     */
    function mintWithSeals(uint256[] calldata sealTokenIds) external;

    /**
     * mint tokens with Chibi Legends. Each Legend can only be used once.
     */
    function mintWithChibiLegends(uint256[] calldata legendTokenIds) external;

    /**
     * check if can use Seals to mint
     */
    function canUseSeals(uint16[] calldata sealTokenIds)
        external
        view
        returns (bool[] memory statuses);

    /**
     * check if can use Chibi Legends to mint
     */
    function canUseChibiLegends(uint16[] calldata legendTokenIds)
        external
        view
        returns (bool[] memory statuses);

    /**
     * mint - only minter
     */
    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    /**
     * mint batch - only minter
     */
    function mintBatch(
        address[] calldata addresses,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    /**
     * set base token URI & extension - only contract owner
     */
    function setURI(string memory newUri, string memory newExtension) external;

    /**
     * set external contract addresses (Shin) - only contract owner
     */
    function setExternalContractAddresses(
        address shinAddr,
        address chibiLegendAddr,
        address sealAddr
    ) external;

    /*
     * enable/disable mint - only contract owner
     */
    function enableMint(bool shouldEnableMintWithShin) external;

    /*
     * enable/disable free mint - only contract owner
     */
    function enableFreeMint(
        bool shouldFreeMintEnabled,
        uint256 newTotalFreeMint
    ) external;

    /*
     * enable/disable mint with Seals - only contract owner
     */
    function enableMintWithSeals(bool shouldEnableMintWithSeals) external;

    /*
     * enable/disable mint with Legends - only contract owner
     */
    function enableMintWithLegends(bool shouldEnableMintWithLegends) external;

    /*
     * set mint cost ($SHIN) - only contract owner
     */
    function setMintCost(uint256 newCost) external;

    /**
     * set Chibi Legend - Lucky Token mapping
     */
    function setChibiLegendLuckyTokenMapping(
        uint256[] calldata chibiLegendTokenIds,
        uint256[] calldata luckyTokenIds
    ) external;

    /**
     * set Seal - Lucky Token mapping
     */
    function setSealLuckyTokenMapping(
        uint256[] calldata sealTokenIds,
        uint256[] calldata luckyTokenIds
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

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

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

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

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

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

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
pragma solidity ^0.8.2;

// @openzeppelin 4.4.1
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./interfaces/IAccessControl.sol";

/**
 * Get the idea from Openzeppelin AccessControl
 */
abstract contract AccessControl is IAccessControl, Ownable {
    /** --------------------STORAGE VARIABLES-------------------- */
    struct RoleData {
        mapping(address => bool) members;
    }

    mapping(bytes32 => RoleData) private _roles;
    /** --------------------STORAGE VARIABLES-------------------- */

    /** --------------------MODIFIERS-------------------- */
    /**
     * Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /** --------------------MODIFIERS-------------------- */

    /** --------------------EXTERNAL FUNCTIONS-------------------- */
    /**
     * see {IAccessControl-hasRole}
     */
    function hasRole(bytes32 role, address account)
        external
        view
        override
        returns (bool)
    {
        return _roles[role].members[account];
    }

    /**
     * see {IAccessControl-grantRole}
     */
    function grantRole(bytes32 role, address account)
        external
        virtual
        override
        onlyOwner
    {
        _grantRole(role, account);
    }

    /**
     * see {IAccessControl-revokeRole}
     */
    function revokeRole(bytes32 role, address account)
        external
        virtual
        override
        onlyOwner
    {
        _revokeRole(role, account);
    }

    /**
     * see {IAccessControl-renounceRole}
     */
    function renounceRole(bytes32 role, address account)
        external
        virtual
        override
    {
        require(
            account == _msgSender(),
            "AccessControl: can only renounce roles for self"
        );

        _revokeRole(role, account);
    }

    /** --------------------EXTERNAL FUNCTIONS-------------------- */

    /** --------------------INTERNAL FUNCTIONS-------------------- */
    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!_hasRole(role, account)) {
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
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!_hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (_hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function _hasRole(bytes32 role, address account)
        internal
        view
        returns (bool)
    {
        return _roles[role].members[account];
    }
    /** --------------------INTERNAL FUNCTIONS-------------------- */
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.2;

// @openzeppelin 4.4.1
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * Base contract
 */
interface IBase {
    /**
     * withdraw all ERC20 tokens - contract owner only
     */
    function withdrawAllERC20(IERC20 token) external;

    /**
     * withdraw ERC721 tokens in an emergency case - contract owner only
     */
    function withdrawERC721(IERC721 token, uint256[] calldata tokenIds)
        external;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.2;

interface IAccessControl {
    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must be owner.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must be owner.
     */
    function revokeRole(bytes32 role, address account) external;

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
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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