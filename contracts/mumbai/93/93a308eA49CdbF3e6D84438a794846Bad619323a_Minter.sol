// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IMinter {
    function update_period() external returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IRewardsDistributor {
  function checkpoint_token() external;

  function checkpoint_total_supply() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IStratum {
  function totalSupply() external view returns (uint);

  function balanceOf(address) external view returns (uint);

  function approve(address spender, uint value) external returns (bool);

  function transfer(address, uint) external returns (bool);

  function transferFrom(address, address, uint) external returns (bool);

  function mint(address, uint) external returns (bool);

  function minter() external returns (address);

  function claim(address, uint) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IVoter {
    function _ve() external view returns (address);
    function governor() external view returns (address);
    function emergencyCouncil() external view returns (address);
    function attachTokenToGauge(uint _tokenId, address account) external;
    function detachTokenFromGauge(uint _tokenId, address account) external;
    function emitDeposit(uint _tokenId, address account, uint amount) external;
    function emitWithdraw(uint _tokenId, address account, uint amount) external;
    function isWhitelisted(address token) external view returns (bool);
    function notifyRewardAmount(uint amount) external;
    function distribute(address _gauge) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IVotingEscrow {

    struct Point {
        int128 bias;
        int128 slope; // # -dweight / dt
        uint256 ts;
        uint256 blk; // block
    }

    function token() external view returns (address);
    function team() external returns (address);
    function epoch() external view returns (uint);
    function point_history(uint loc) external view returns (Point memory);
    function user_point_history(uint tokenId, uint loc) external view returns (Point memory);
    function user_point_epoch(uint tokenId) external view returns (uint);

    function ownerOf(uint) external view returns (address);
    function isApprovedOrOwner(address, uint) external view returns (bool);
    function transferFrom(address, address, uint) external;

    function voting(uint tokenId) external;
    function abstain(uint tokenId) external;
    function attach(uint tokenId) external;
    function detach(uint tokenId) external;

    function checkpoint() external;
    function deposit_for(uint tokenId, uint value) external;
    function create_lock_for(uint, uint, address) external returns (uint);

    function balanceOfNFT(uint) external view returns (uint);
    function totalSupply() external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

library Math {
  function max(uint a, uint b) internal pure returns (uint) {
    return a >= b ? a : b;
  }

  function min(uint a, uint b) internal pure returns (uint) {
    return a < b ? a : b;
  }

  function sqrt(uint y) internal pure returns (uint z) {
    if (y > 3) {
      z = y;
      uint x = y / 2 + 1;
      while (x < z) {
        z = x;
        x = (y / x + x) / 2;
      }
    } else if (y != 0) {
      z = 1;
    }
  }

  function cbrt(uint256 n) internal pure returns (uint256) {
    unchecked {
      uint256 x = 0;
      for (uint256 y = 1 << 255; y > 0; y >>= 3) {
        x <<= 1;
        uint256 z = 3 * x * (x + 1) + 1;
        if (n / y >= z) {
          n -= y * z;
          x += 1;
        }
      }
      return x;
    }
  }

  function sub(uint x, uint y) internal pure returns (uint z) {
    require((z = x - y) <= x, "Math: Sub-underflow");
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import "contracts/libraries/Math.sol";
import "contracts/interfaces/IMinter.sol";
import "contracts/interfaces/IRewardsDistributor.sol";
import "contracts/interfaces/IStratum.sol";
import "contracts/interfaces/IVoter.sol";
import "contracts/interfaces/IVotingEscrow.sol";

// codifies the minting rules as per ve(3,3), abstracted from the token to support any token that allows minting

contract Minter is IMinter {
  uint internal constant WEEK = 86400 * 7; // allows minting once per week (reset every Thursday 00:00 UTC)
  uint internal constant TAIL_EMISSION = 2; // 0.2%
  uint internal constant PRECISION = 1000;
  uint internal emission;
  uint internal numEpoch;
  IStratum public immutable _stratum;
  IVoter public immutable _voter;
  IVotingEscrow public immutable _ve;
  IRewardsDistributor public immutable _rewards_distributor;
  uint public weekly = 750_000 * 1e18; // represents a starting weekly emission of 750k STRAT (STRAT has 18 decimals)
  uint public active_period;
  uint internal constant LOCK = 86400 * 7 * 52 * 4;

  address internal initializer;
  address public team;
  address public pendingTeam;
  uint public teamRate;
  uint public constant MAX_TEAM_RATE = 50; // 5%

  event Mint(
    address indexed sender,
    uint weekly,
    uint circulating_supply,
    uint circulating_emission
  );

  constructor(
    address __voter, // the voting & distribution system
    address __ve, // the ve(3,3) system that will be locked into
    address __rewards_distributor // the distribution system that ensures users aren't diluted
  ) {
    initializer = msg.sender;
    team = msg.sender;
    teamRate = 20; // 2%
    emission = 990; // 99%, changes to 99.5% on epoch 20
    _stratum = IStratum(IVotingEscrow(__ve).token());
    _voter = IVoter(__voter);
    _ve = IVotingEscrow(__ve);
    _rewards_distributor = IRewardsDistributor(__rewards_distributor);
    active_period = ((block.timestamp + (2 * WEEK)) / WEEK) * WEEK;
  }

  function initialize(
    address[] memory claimants,
    uint[] memory amounts,
    uint max // sum amounts / max = % ownership of top protocols, so if initial 20m is distributed, and target is 25% protocol ownership, then max - 4 x 20m = 80m
  ) external {
    require(initializer == msg.sender);
    _stratum.mint(address(this), max);
    _stratum.approve(address(_ve), type(uint).max);
    for (uint i = 0; i < claimants.length; i++) {
      _ve.create_lock_for(amounts[i], LOCK, claimants[i]);
    }
    initializer = address(0);
    active_period = ((block.timestamp) / WEEK) * WEEK; // allow minter.update_period() to mint new emissions THIS Thursday
  }

  function setTeam(address _team) external {
    require(msg.sender == team, "not team");
    pendingTeam = _team;
  }

  function acceptTeam() external {
    require(msg.sender == pendingTeam, "not pending team");
    team = pendingTeam;
  }

  function setTeamRate(uint _teamRate) external {
    require(msg.sender == team, "not team");
    require(_teamRate <= MAX_TEAM_RATE, "rate too high");
    teamRate = _teamRate;
  }

  // calculate circulating supply as total token supply - locked supply
  function circulating_supply() public view returns (uint) {
    return _stratum.totalSupply() - _ve.totalSupply();
  }

  // emission calculation is 1% of available supply to mint adjusted by circulating / total supply
  function calculate_emission() public view returns (uint) {
    return (weekly * emission) / PRECISION;
  }

  // weekly emission takes the max of calculated (aka target) emission versus circulating tail end emission
  function weekly_emission() public view returns (uint) {
    return Math.max(calculate_emission(), circulating_emission());
  }

  // calculates tail end (infinity) emissions as 0.2% of total supply
  function circulating_emission() public view returns (uint) {
    return (circulating_supply() * TAIL_EMISSION) / PRECISION;
  }

  // calculate inflation and adjust ve balances accordingly
  // NOT USED as of 4ccc042242e935e9cc7224526db9fb323e29327b
  function calculate_growth(uint _minted) public view returns (uint) {
    uint _veTotal = _ve.totalSupply();
    uint _stratumTotal = _stratum.totalSupply();
    return
      (((((_minted * _veTotal) / _stratumTotal) * _veTotal) / _stratumTotal) *
        _veTotal) /
      _stratumTotal /
      2;
  }

  // update period can only be called once per cycle (1 week)
  function update_period() external returns (uint) {
    uint _period = active_period;
    if (block.timestamp >= _period + WEEK && initializer == address(0)) {
      // only trigger if new week
      _period = (block.timestamp / WEEK) * WEEK;
      active_period = _period;
      weekly = weekly_emission();

      // uint _growth = calculate_growth(weekly);
      uint _teamEmissions = (teamRate * weekly) / PRECISION;
      uint _required = weekly + _teamEmissions;
      uint _balanceOf = _stratum.balanceOf(address(this));
      if (_balanceOf < _required) {
        _stratum.mint(address(this), _required - _balanceOf);
      }

      unchecked {
        ++numEpoch;
      }
      if (numEpoch == 20) emission = 995;

      require(_stratum.transfer(team, _teamEmissions));

      // REMOVE REBASE LOGIC
      //   require(_stratum.transfer(address(_rewards_distributor), _growth));
      //   _rewards_distributor.checkpoint_token(); // checkpoint token balance that was just minted in rewards distributor
      //   _rewards_distributor.checkpoint_total_supply(); // checkpoint supply

      _stratum.approve(address(_voter), weekly);
      _voter.notifyRewardAmount(weekly);

      emit Mint(
        msg.sender,
        weekly,
        circulating_supply(),
        circulating_emission()
      );
    }
    return _period;
  }
}