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
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// CraftingChroniclesBetting Version 1.0
contract CraftingChroniclesBetting {
    struct Bet {
        address player;
        uint256 betAmount;
        uint256 riskType;
    }

    struct History {
        uint256 date;
        uint256 betAmount;
        uint256 betOutput;
        uint256 riskType;
    }

    IERC20 private _token;
    address public _admin;
    address[] private vipWinner;
    address[] private freeMintWinner;

    mapping(uint256 => bool) public allowedBetAmount;
    bool private manualBet = false;

    uint256 private _maxAmount;
    uint256 private _minAmount;

    Bet[] public _lobbyBet;
    // mapping(uint256 => uint256[]) private riskCase;
    mapping(address => History[]) private _playerHistory;

    event BetPlaced(address indexed user, uint256 amount);
    event BetPaid(address indexed user, uint256 amount);

    constructor(address token) {
        _token = IERC20(token);
        _admin = msg.sender;
        _maxAmount = 10 ether;
        _minAmount = 1 ether;
    }

    function placeBet(uint256 amount, uint256 riskType) external {
        require(
            (amount <= _maxAmount && amount >= _minAmount) ||
                allowedBetAmount[amount],
            "Amount is not allowed!"
        );
        require(riskType < 3, "Risk type not allowed");
        require(isLobbyOpen(), "Lobby is actually full");
        require(_token.balanceOf(msg.sender) >= amount, "Insufficient balance");
        require(
            _token.allowance(msg.sender, address(this)) >= amount,
            "Insufficient allowance"
        );

        _token.transferFrom(msg.sender, address(this), amount);
        _lobbyBet.push(
            Bet({player: msg.sender, betAmount: amount, riskType: riskType})
        );
        emit BetPlaced(msg.sender, amount);
    }

    // function payBet() external onlyAdmin {
    function payBet() external {
        for (uint256 i = 0; i < _lobbyBet.length; i++) {
            uint256 amount = _lobbyBet[i].betAmount;
            address player = _lobbyBet[i].player;
            uint256 riskType = _lobbyBet[i].riskType;

            uint256 outcome = _hashRand(player, i) + 1;

            uint256 toPay;

            if (riskType == 0) {
                // LOW RISK
                if (outcome > 9000) {
                    toPay = amount * 1;
                    vipWinner.push(player);
                } else if (outcome > 7500) {
                    toPay = amount * 0;
                } else if (outcome > 3500) {
                    toPay = amount * 1;
                } else {
                    toPay = amount * 2;
                }
            } else if (riskType == 1) {
                // MEDIUM RISK
                if (outcome > 9990) {
                    toPay = amount * 1;
                    freeMintWinner.push(player);
                } else if (outcome > 9000) {
                    toPay = amount * 1;
                    vipWinner.push(player);
                } else if (outcome > 6500) {
                    toPay = amount * 0;
                } else if (outcome > 4000) {
                    toPay = amount * 1;
                } else if (outcome > 1500) {
                    toPay = amount * 2;
                } else if (outcome > 500) {
                    toPay = (amount * 25) / 10;
                } else {
                    toPay = amount * 3;
                }
            } else {
                // HIGH RISK
                if (outcome > 9950) {
                    toPay = amount * 1;
                    freeMintWinner.push(player);
                } else if (outcome > 9000) {
                    toPay = amount * 1;
                    vipWinner.push(player);
                } else if (outcome > 500) {
                    toPay = amount * 0;
                } else {
                    toPay = amount * 10;
                }
            }

            if (toPay > 0 && _token.balanceOf(address(this)) > toPay)
                _token.transfer(player, toPay);

            _playerHistory[player].push(
                History({
                    date: block.timestamp,
                    betAmount: amount,
                    betOutput: toPay,
                    riskType: riskType
                })
            );

            emit BetPaid(player, toPay);
        }
        delete _lobbyBet;
    }

    function setPayToken(address token) external onlyAdmin {
        _token = IERC20(token);
    }

    function enableBetAmount(uint256 number, bool enabled) external onlyAdmin {
        allowedBetAmount[number] = enabled;
    }

    function setMinAmount(uint256 minAmount) external onlyAdmin {
        _minAmount = minAmount;
    }

    function setMaxAmount(uint256 minAmount) external onlyAdmin {
        _minAmount = minAmount;
    }

    function getLobbyBet() public view returns (Bet[] memory) {
        return _lobbyBet;
    }

    function getPlayerHistory(
        address player
    ) public view returns (History[] memory) {
        return _playerHistory[player];
    }

    function hashRand(
        address player,
        uint256 index
    ) external view onlyAdmin returns (uint256) {
        return _hashRand(player, index);
    }

    function isLobbyOpen() public view returns (bool) {
        return _lobbyBet.length < 200;
    }

    function checkFreeMintWinner(address player) public view returns (bool) {
        for (uint256 i = 0; i < freeMintWinner.length; i++) {
            if (freeMintWinner[i] == player) return true;
        }
        return false;
    }

    function _hashRand(
        address player,
        uint256 index
    ) internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.prevrandao,
                        player,
                        index
                    )
                )
            ) % 10000;
    }

    modifier onlyAdmin() {
        require(msg.sender == _admin, "only admin");
        _;
    }
}