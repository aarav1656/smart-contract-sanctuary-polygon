/**
 *Submitted for verification at polygonscan.com on 2022-10-28
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/reserve.sol
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.5.15 >=0.7.6;

////// src/lib/casten-auth/src/auth.sol
// Copyright (C) Casten 2022, based on MakerDAO dss https://github.com/makerdao/dss
/* pragma solidity >=0.5.15; */

contract Auth {
    mapping (address => uint256) public wards;
    
    event Rely(address indexed usr);
    event Deny(address indexed usr);

    function rely(address usr) external auth {
        wards[usr] = 1;
        emit Rely(usr);
    }
    function deny(address usr) external auth {
        wards[usr] = 0;
        emit Deny(usr);
    }

    modifier auth {
        require(wards[msg.sender] == 1, "not-authorized");
        _;
    }

}

////// src/lib/casten-math/src/math.sol
// Copyright (C) 2018 Rain <[email protected]>
/* pragma solidity >=0.5.15; */

contract Math {
    uint256 constant ONE = 10 ** 27;

    function safeAdd(uint x, uint y) public pure returns (uint z) {
        require((z = x + y) >= x, "safe-add-failed");
    }

    function safeSub(uint x, uint y) public pure returns (uint z) {
        require((z = x - y) <= x, "safe-sub-failed");
    }

    function safeMul(uint x, uint y) public pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "safe-mul-failed");
    }

    function safeDiv(uint x, uint y) public pure returns (uint z) {
        z = x / y;
    }

    function rmul(uint x, uint y) public pure returns (uint z) {
        z = safeMul(x, y) / ONE;
    }

    function rdiv(uint x, uint y) public pure returns (uint z) {
        require(y > 0, "division by zero");
        z = safeAdd(safeMul(x, ONE), y / 2) / y;
    }

    function rdivup(uint x, uint y) internal pure returns (uint z) {
        require(y > 0, "division by zero");
        // always rounds up
        z = safeAdd(safeMul(x, ONE), safeSub(y, 1)) / y;
    }


}

////// src/reserve.sol
/* pragma solidity >=0.7.6; */

/* import "./lib/casten-math/src/math.sol"; */
/* import "./lib/casten-auth/src/auth.sol"; */

interface ERC20Like_1 {
    function balanceOf(address) external view returns (uint256);
    function transferFrom(address, address, uint) external returns (bool);
    function mint(address, uint256) external;
    function burn(address, uint256) external;
    function totalSupply() external view returns (uint256);
    function approve(address, uint) external;
}

interface LendingAdapter_2 {
    function remainingCredit() external view returns (uint);
    function draw(uint amount) external;
    function wipe(uint amount) external;
    function debt() external returns(uint);
    function activated() external view returns(bool);
}

// The reserve keeps track of the currency and the bookkeeping
// of the total balance
contract Reserve is Math, Auth {
    ERC20Like_1 public currency;

    // additional currency from lending adapters
    // for deactivating set to address(0)
    LendingAdapter_2 public lending;

    // currency available for borrowing new loans
    uint256 public currencyAvailable;

    // address or contract which holds the currency
    // by default it is address(this)
    address pot;

    // total currency in the reserve
    uint public balance_;

    //if reserve doesn't have enough funds while withdrawing fee, this variable in updated
    address public treasury;
    
    uint public pendingInterestFee;
    uint256 public originationFeePerc;
    uint256 public feeOnInterestPerc;

    event File(bytes32 indexed what, uint amount);
    event File(bytes32 indexed what, address value);
    event Depend(bytes32 contractName, address addr);

    constructor(address currency_) {
        currency = ERC20Like_1(currency_);
        pot = address(this);
        currency.approve(pot, type(uint256).max);
        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    // deposits currency in the the reserve
    function deposit(uint currencyAmount) public auth {
        if(currencyAmount == 0) return;
        _deposit(msg.sender, currencyAmount);
    }

    // hard deposit guarantees that the currency stays in the reserve
    function hardDeposit(uint currencyAmount) public auth {
        _depositAction(msg.sender, currencyAmount);
    }

    function _depositAction(address usr, uint currencyAmount) internal {
        require(currency.transferFrom(usr, pot, currencyAmount), "reserve-deposit-failed");
        balance_ = safeAdd(balance_, currencyAmount);
    }

    function _deposit(address usr, uint currencyAmount) internal {
        _depositAction(usr, currencyAmount);
        if(address(lending) != address(0) && lending.debt() > 0 && lending.activated()) {
            uint wipeAmount = lending.debt();
            uint available = balance_;
            if(available < wipeAmount) {
                wipeAmount = available;
            }
            lending.wipe(wipeAmount);
        }
    }


    // returns the amount of currency currently in the reserve
    function totalBalance() public view returns (uint) {
        return balance_;
    }

    // return the amount of currency and the available currency from the lending adapter
    function totalBalanceAvailable() public view returns (uint) {
        if(address(lending) == address(0)) {
            return balance_;
        }

        return safeAdd(balance_, lending.remainingCredit());
    }

    // remove currency from the reserve
    function payout(uint currencyAmount) public auth {
        if(currencyAmount == 0) return;
        _payout(msg.sender, currencyAmount);
    }

    function _payoutAction(address usr, uint currencyAmount) internal {
        require(currency.transferFrom(pot, usr, currencyAmount), "reserve-payout-failed");
        balance_ = safeSub(balance_, currencyAmount);
    }

    // hard payout guarantees that the currency stays in the reserve
    function hardPayout(uint currencyAmount) public auth {
        _payoutAction(msg.sender, currencyAmount);
    }

    function _payout(address usr, uint currencyAmount)  internal {
        uint reserveBalance = balance_;
        if (currencyAmount > reserveBalance && address(lending) != address(0) && lending.activated()) {
            uint drawAmount = safeSub(currencyAmount, reserveBalance);
            uint left = lending.remainingCredit();
            if(drawAmount > left) {
                drawAmount = left;
            }

            lending.draw(drawAmount);
        }

        _payoutAction(usr, currencyAmount);
    }

    // payout currency for loans not all funds
    // in the reserve are compulsory available for loans in the current epoch
    function payoutForLoans(uint currencyAmount) public auth {
        require(
            currencyAvailable  >= currencyAmount,
            "not-enough-currency-reserve"
        );

        currencyAvailable = safeSub(currencyAvailable, currencyAmount);
        _payout(msg.sender, currencyAmount);
    }

    function transferFeeOnInterest(uint _amt) external auth {
        if(_amt < balance_) {
            balance_ = safeSub(balance_, _amt);
            require(currency.transferFrom(pot, treasury, _amt), "fee-payout-failed");
        } else {
            pendingInterestFee = safeAdd(pendingInterestFee, _amt);
        }
    }

    function withdrawPendingFee() external auth {
        uint _pendingInterestFee = pendingInterestFee;
        pendingInterestFee = 0;
        balance_ = safeSub(balance_, _pendingInterestFee);
        require(currency.transferFrom(pot, treasury, _pendingInterestFee), "fee-payout-failed");
    }

    function file(bytes32 what, uint amount) public auth {
        if (what == "currencyAvailable") {
            currencyAvailable = amount;
        } else if(what == "originationFeePerc") {
            //2 decimals - 100 for 1 %
            originationFeePerc = amount;
        } else if(what == "feeOnInterest") {
            //2 decimals - 1000 for 10 %
            feeOnInterestPerc = amount;
        } else revert();
        emit File(what, amount);
    }

    function file(bytes32 what, address _value) public auth {
        if(what == "treasuryAddress") {
            treasury = _value;
        } else revert();

        emit File(what, _value);
    }

    function depend(bytes32 contractName, address addr) public auth {
        if (contractName == "currency") {
            currency = ERC20Like_1(addr);
            if (pot == address(this)) {
                currency.approve(pot, type(uint256).max);
            }
        } else if (contractName == "pot") {
            pot = addr;
        } else if (contractName == "lending") {
            lending = LendingAdapter_2(addr);
        } else revert();
        emit Depend(contractName, addr);
    }
}