// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.9;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "./DarkForestTypes.sol";
import "./DarkForestLazyUpdate.sol";

library DarkForestPlanet {
    function isPopCapBoost(uint256 _location) public pure returns (bool) {
        bytes memory _b = abi.encodePacked(_location);
        return uint256(uint8(_b[11])) < 16;
    }

    function isPopGroBoost(uint256 _location) public pure returns (bool) {
        bytes memory _b = abi.encodePacked(_location);
        return uint256(uint8(_b[12])) < 16;
    }

    function isResCapBoost(uint256 _location) public pure returns (bool) {
        bytes memory _b = abi.encodePacked(_location);
        return uint256(uint8(_b[13])) < 16;
    }

    function isResGroBoost(uint256 _location) public pure returns (bool) {
        bytes memory _b = abi.encodePacked(_location);
        return uint256(uint8(_b[14])) < 16;
    }

    function isRangeBoost(uint256 _location) public pure returns (bool) {
        bytes memory _b = abi.encodePacked(_location);
        return uint256(uint8(_b[15])) < 16;
    }

    function _getDecayedPop(
        uint256 _popMoved,
        uint256 _maxDist,
        uint256 _range,
        uint256 _populationCap
    ) public pure returns (uint256 _decayedPop) {
        int128 _scaleInv = ABDKMath64x64.exp_2(
            ABDKMath64x64.divu(_maxDist, _range)
        );
        int128 _bigPlanetDebuff = ABDKMath64x64.divu(_populationCap, 20);
        int128 _beforeDebuff = ABDKMath64x64.div(
            ABDKMath64x64.fromUInt(_popMoved),
            _scaleInv
        );
        if (_beforeDebuff > _bigPlanetDebuff) {
            _decayedPop = ABDKMath64x64.toUInt(
                ABDKMath64x64.sub(_beforeDebuff, _bigPlanetDebuff)
            );
        } else {
            _decayedPop = 0;
        }
    }

    function _createArrival(
        uint256 _oldLoc,
        uint256 _newLoc,
        uint256 _maxDist,
        uint256 _popMoved,
        uint256 _silverMoved,
        uint256 GLOBAL_SPEED_IN_HUNDRETHS,
        uint256 planetEventsCount,
        mapping(uint256 => DarkForestTypes.Planet) storage planets,
        mapping(uint256 => DarkForestTypes.ArrivalData) storage planetArrivals
    ) internal {
        // enter the arrival data for event id planetEventsCount
        DarkForestTypes.Planet memory planet = planets[_oldLoc];
        uint256 _popArriving = _getDecayedPop(
            _popMoved,
            _maxDist,
            planet.range,
            planet.populationCap
        );
        require(_popArriving > 0, "Not enough forces to make move");
        planetArrivals[planetEventsCount] = DarkForestTypes.ArrivalData({
            id: planetEventsCount,
            player: msg.sender,
            fromPlanet: _oldLoc,
            toPlanet: _newLoc,
            popArriving: _popArriving,
            silverMoved: _silverMoved,
            departureTime: block.timestamp,
            arrivalTime: block.timestamp +
                (_maxDist * 100) /
                GLOBAL_SPEED_IN_HUNDRETHS
        });
    }

    function initializePlanet(
        DarkForestTypes.Planet storage _planet,
        DarkForestTypes.PlanetExtendedInfo storage _planetExtendedInfo,
        DarkForestTypes.PlanetDefaultStats storage _planetDefaultStats,
        uint256 _version,
        DarkForestTypes.PlanetType _planetType,
        DarkForestTypes.PlanetResource _planetResource,
        uint256 _planetLevel,
        uint256 _location
    ) public {
        _planetExtendedInfo.isInitialized = true;
        // planet initialize should set the planet to default state, including having the owner be adress 0x0
        // then it's the responsibility for the mechanics to set the owner to the player
        _planet.owner = address(0);
        _planet.range = isRangeBoost(_location)
            ? _planetDefaultStats.range * 2
            : _planetDefaultStats.range;

        _planet.populationCap = isPopCapBoost(_location)
            ? _planetDefaultStats.populationCap * 2
            : _planetDefaultStats.populationCap;

        _planet.population = _planetType ==
            DarkForestTypes.PlanetType.TRADING_POST
            ? 1500000
            : SafeMath.div(
                SafeMath.mul(
                    _planet.populationCap,
                    _planetDefaultStats.barbarianPercentage
                ),
                100
            );

        _planet.populationGrowth = isPopGroBoost(_location)
            ? _planetDefaultStats.populationGrowth * 2
            : _planetDefaultStats.populationGrowth;
        // TESTING
        // _planet.populationGrowth *= 100;

        _planet.planetResource = _planetResource;

        _planet.silverCap = isResCapBoost(_location)
            ? _planetDefaultStats.silverCap * 2
            : _planetDefaultStats.silverCap;
        _planet.silverGrowth = 0;
        if (_planetResource == DarkForestTypes.PlanetResource.SILVER) {
            _planet.silverGrowth = isResGroBoost(_location)
                ? _planetDefaultStats.silverGrowth * 2
                : _planetDefaultStats.silverGrowth;
            // TESTING
            // _planet.silverGrowth *= 100;
        }

        _planet.silver = 0;
        _planet.silverMax = _planetDefaultStats.silverMax;
        _planet.planetLevel = _planetLevel;

        _planetExtendedInfo.version = _version;
        _planetExtendedInfo.lastUpdated = block.timestamp;
        _planetExtendedInfo.upgradeState0 = 0;
        _planetExtendedInfo.upgradeState1 = 0;
        _planetExtendedInfo.upgradeState2 = 0;
    }

    function upgradePlanet(
        DarkForestTypes.Planet storage _planet,
        DarkForestTypes.PlanetExtendedInfo storage _planetExtendedInfo,
        uint256 _branch,
        DarkForestTypes.PlanetDefaultStats[] storage planetDefaultStats,
        DarkForestTypes.Upgrade[4][3] storage upgrades
    ) public {
        // do checks
        require(
            _planet.owner == msg.sender,
            "Only owner can perform operation on planets"
        );
        uint256 planetLevel = _planet.planetLevel;
        require(
            planetLevel > 0,
            "Planet level is not high enough for this upgrade"
        );
        require(_branch < 3, "Upgrade branch not valid");
        uint256 upgradeBranchCurrentLevel;
        if (_branch == 0) {
            upgradeBranchCurrentLevel = _planetExtendedInfo.upgradeState0;
        } else if (_branch == 1) {
            upgradeBranchCurrentLevel = _planetExtendedInfo.upgradeState1;
        } else if (_branch == 2) {
            upgradeBranchCurrentLevel = _planetExtendedInfo.upgradeState2;
        }
        require(upgradeBranchCurrentLevel < 4, "Upgrade branch already maxed");
        if (upgradeBranchCurrentLevel == 2) {
            if (_branch == 0) {
                require(
                    _planetExtendedInfo.upgradeState1 < 3 &&
                        _planetExtendedInfo.upgradeState2 < 3,
                    "Can't upgrade a second branch to level 3"
                );
            }
            if (_branch == 1) {
                require(
                    _planetExtendedInfo.upgradeState0 < 3 &&
                        _planetExtendedInfo.upgradeState2 < 3,
                    "Can't upgrade a second branch to level 3"
                );
            }
            if (_branch == 2) {
                require(
                    _planetExtendedInfo.upgradeState0 < 3 &&
                        _planetExtendedInfo.upgradeState1 < 3,
                    "Can't upgrade a second branch to level 3"
                );
            }
        }


            DarkForestTypes.Upgrade memory upgrade
         = upgrades[_branch][upgradeBranchCurrentLevel];
        uint256 upgradeCost = (planetDefaultStats[planetLevel].silverCap *
            upgrade.silverCostMultiplier) / 100;
        require(
            _planet.silver >= upgradeCost,
            "Insufficient silver to upgrade"
        );

        // do upgrade
        _planet.populationCap =
            (_planet.populationCap * upgrade.popCapMultiplier) /
            100;
        _planet.populationGrowth =
            (_planet.populationGrowth * upgrade.popGroMultiplier) /
            100;
        _planet.silverCap =
            (_planet.silverCap * upgrade.silverCapMultiplier) /
            100;
        _planet.silverGrowth =
            (_planet.silverGrowth * upgrade.silverGroMultiplier) /
            100;
        _planet.silverMax =
            (_planet.silverMax * upgrade.silverMaxMultiplier) /
            100;
        _planet.range = (_planet.range * upgrade.rangeMultiplier) / 100;
        _planet.silver -= upgradeCost;
        if (_branch == 0) {
            _planetExtendedInfo.upgradeState0 += 1;
        } else if (_branch == 1) {
            _planetExtendedInfo.upgradeState1 += 1;
        } else if (_branch == 2) {
            _planetExtendedInfo.upgradeState2 += 1;
        }
    }

    function move(
        uint256 _oldLoc,
        uint256 _newLoc,
        uint256 _maxDist,
        uint256 _popMoved,
        uint256 _silverMoved,
        uint256 GLOBAL_SPEED_IN_HUNDRETHS,
        uint256 planetEventsCount,
        mapping(uint256 => DarkForestTypes.Planet) storage planets,
        mapping(uint256 => DarkForestTypes.PlanetEventMetadata[])
            storage planetEvents,
        mapping(uint256 => DarkForestTypes.ArrivalData) storage planetArrivals
    ) public {
        require(
            planets[_oldLoc].owner == msg.sender,
            "Only owner can perform operation on planets"
        );
        // we want strict > so that the population can't go to 0
        require(
            planets[_oldLoc].population > _popMoved,
            "Tried to move more population that what exists"
        );
        require(
            planets[_oldLoc].silver >= _silverMoved,
            "Tried to move more silver than what exists"
        );

        // all checks pass. execute move
        // push the new move into the planetEvents array for _newLoc
        planetEvents[_newLoc].push(
            DarkForestTypes.PlanetEventMetadata({
                id: planetEventsCount,
                eventType: DarkForestTypes.PlanetEventType.ARRIVAL,
                timeTrigger: block.timestamp +
                    (_maxDist * 100) /
                    GLOBAL_SPEED_IN_HUNDRETHS,
                timeAdded: block.timestamp
            })
        );

        _createArrival(
            _oldLoc,
            _newLoc,
            _maxDist,
            _popMoved,
            _silverMoved,
            GLOBAL_SPEED_IN_HUNDRETHS,
            planetEventsCount,
            planets,
            planetArrivals
        );

        // subtract ships and silver sent
        planets[_oldLoc].population -= _popMoved;
        planets[_oldLoc].silver -= _silverMoved;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.9;

library DarkForestTypes {
    enum PlanetResource {NONE, SILVER}
    enum PlanetEventType {ARRIVAL}
    enum PlanetType {PLANET, TRADING_POST}

    struct Planet {
        address owner;
        uint256 range;
        uint256 population;
        uint256 populationCap;
        uint256 populationGrowth;
        PlanetResource planetResource;
        uint256 silverCap;
        uint256 silverGrowth;
        uint256 silver;
        uint256 silverMax;
        uint256 planetLevel;
        PlanetType planetType;
    }

    struct PlanetExtendedInfo {
        bool isInitialized;
        uint256 version;
        uint256 lastUpdated;
        uint256 upgradeState0;
        uint256 upgradeState1;
        uint256 upgradeState2;
    }

    struct PlanetEventMetadata {
        uint256 id;
        PlanetEventType eventType;
        uint256 timeTrigger;
        uint256 timeAdded;
    }

    struct ArrivalData {
        uint256 id;
        address player;
        uint256 fromPlanet;
        uint256 toPlanet;
        uint256 popArriving;
        uint256 silverMoved;
        uint256 departureTime;
        uint256 arrivalTime;
    }

    struct PlanetDefaultStats {
        string label;
        uint256 populationCap;
        uint256 populationGrowth;
        uint256 range;
        uint256 silverGrowth;
        uint256 silverCap;
        uint256 silverMax;
        uint256 barbarianPercentage;
        uint256 energyCost;
    }

    struct Upgrade {
        uint256 popCapMultiplier;
        uint256 popGroMultiplier;
        uint256 silverCapMultiplier;
        uint256 silverGroMultiplier;
        uint256 silverMaxMultiplier;
        uint256 rangeMultiplier;
        uint256 silverCostMultiplier;
    }
}

pragma solidity ^0.6.9;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/Math.sol";
import "./ABDKMath64x64.sol";
import "./DarkForestTypes.sol";

library DarkForestLazyUpdate {
    function _updateSilver(
        DarkForestTypes.Planet storage _planet,
        DarkForestTypes.PlanetExtendedInfo storage _planetExtendedInfo,
        uint256 _updateToTime
    ) private {
        // This function should never be called directly and should only be called
        // by the refresh planet function. This require is in place to make sure
        // no one tries to updateSilver on non silver producing planet.
        require(
            _planet.planetResource == DarkForestTypes.PlanetResource.SILVER,
            "Can only update silver on silver producing planet"
        );
        if (_planet.owner == address(0)) {
            // unowned planet doesn't gain silver
            return;
        }

        // WE NEED TO MAKE SURE WE NEVER TAKE LOG(0)
        uint256 _startSilverProd;

        if (_planet.population > _planet.populationCap / 2) {
            // midpoint was before lastUpdated, so start prod from lastUpdated
            _startSilverProd = _planetExtendedInfo.lastUpdated;
        } else {
            // midpoint was after lastUpdated, so calculate & start prod from lastUpdated
            int128 _popCap = ABDKMath64x64.fromUInt(_planet.populationCap);
            int128 _pop = ABDKMath64x64.fromUInt(_planet.population);
            int128 _logVal = ABDKMath64x64.ln(
                ABDKMath64x64.div(ABDKMath64x64.sub(_popCap, _pop), _pop)
            );

            int128 _diffNumerator = ABDKMath64x64.mul(_logVal, _popCap);
            int128 _diffDenominator = ABDKMath64x64.mul(
                ABDKMath64x64.fromUInt(4),
                ABDKMath64x64.fromUInt(_planet.populationGrowth)
            );

            int128 _popCurveMidpoint = ABDKMath64x64.add(
                ABDKMath64x64.div(_diffNumerator, _diffDenominator),
                ABDKMath64x64.fromUInt(_planetExtendedInfo.lastUpdated)
            );

            _startSilverProd = ABDKMath64x64.toUInt(_popCurveMidpoint);
        }

        // Check if the pop curve midpoint happens in the past
        if (_startSilverProd < _updateToTime) {
            uint256 _timeDiff;

            if (_startSilverProd > _planetExtendedInfo.lastUpdated) {
                _timeDiff = SafeMath.sub(_updateToTime, _startSilverProd);
            } else {
                _timeDiff = SafeMath.sub(
                    _updateToTime,
                    _planetExtendedInfo.lastUpdated
                );
            }

            if (_planet.silver < _planet.silverCap) {
                uint256 _silverMined = SafeMath.mul(
                    _planet.silverGrowth,
                    _timeDiff
                );

                _planet.silver = Math.min(
                    _planet.silverCap,
                    SafeMath.add(_planet.silver, _silverMined)
                );
            }
        }
    }

    function _updatePopulation(
        DarkForestTypes.Planet storage _planet,
        DarkForestTypes.PlanetExtendedInfo storage _planetExtendedInfo,
        uint256 _updateToTime
    ) private {
        if (_planet.owner == address(0)) {
            // unowned planet doesn't increase in population
            return;
        }

        int128 _timeElapsed = ABDKMath64x64.sub(
            ABDKMath64x64.fromUInt(_updateToTime),
            ABDKMath64x64.fromUInt(_planetExtendedInfo.lastUpdated)
        );

        int128 _one = ABDKMath64x64.fromUInt(1);

        int128 _denominator = ABDKMath64x64.add(
            ABDKMath64x64.mul(
                ABDKMath64x64.exp(
                    ABDKMath64x64.div(
                        ABDKMath64x64.mul(
                            ABDKMath64x64.mul(
                                ABDKMath64x64.fromInt(-4),
                                ABDKMath64x64.fromUInt(_planet.populationGrowth)
                            ),
                            _timeElapsed
                        ),
                        ABDKMath64x64.fromUInt(_planet.populationCap)
                    )
                ),
                ABDKMath64x64.sub(
                    ABDKMath64x64.div(
                        ABDKMath64x64.fromUInt(_planet.populationCap),
                        ABDKMath64x64.fromUInt(_planet.population)
                    ),
                    _one
                )
            ),
            _one
        );

        _planet.population = ABDKMath64x64.toUInt(
            ABDKMath64x64.div(
                ABDKMath64x64.fromUInt(_planet.populationCap),
                _denominator
            )
        );
    }

    function updatePlanet(
        DarkForestTypes.Planet storage _planet,
        DarkForestTypes.PlanetExtendedInfo storage _planetExtendedInfo,
        uint256 _updateToTime
    ) public {
        // assumes planet is already initialized
        _updatePopulation(_planet, _planetExtendedInfo, _updateToTime);

        if (_planet.planetResource == DarkForestTypes.PlanetResource.SILVER) {
            _updateSilver(_planet, _planetExtendedInfo, _updateToTime);
        }

        _planetExtendedInfo.lastUpdated = _updateToTime;
    }

    // assumes that the planet last updated time is equal to the arrival time trigger
    function applyArrival(
        DarkForestTypes.Planet storage _planet,
        DarkForestTypes.ArrivalData storage _planetArrival
    ) private {
        // for readability, trust me.

        // checks whether the planet is owned by the player sending ships
        if (_planetArrival.player == _planet.owner) {
            // simply increase the population if so
            _planet.population = SafeMath.add(
                _planet.population,
                _planetArrival.popArriving
            );
        } else {
            if (_planet.population > _planetArrival.popArriving) {
                // handles if the planet population is bigger than the arriving ships
                // simply reduce the amount of planet population by the arriving ships
                _planet.population = SafeMath.sub(
                    _planet.population,
                    _planetArrival.popArriving
                );
            } else {
                // handles if the planet population is equal or less the arriving ships
                // reduce the arriving ships amount with the current population and the
                // result is the new population of the planet now owned by the attacking
                // player
                _planet.owner = _planetArrival.player;
                _planet.population = SafeMath.sub(
                    _planetArrival.popArriving,
                    _planet.population
                );
                if (_planet.population == 0) {
                    // make sure pop is never 0
                    _planet.population = 1;
                }
            }
        }

        _planet.silver = Math.min(
            _planet.silverMax,
            SafeMath.add(_planet.silver, _planetArrival.silverMoved)
        );
    }

    function _applyPendingEvents(
        uint256 _location,
        mapping(uint256 => DarkForestTypes.PlanetEventMetadata[]) storage planetEvents,
        mapping(uint256 => DarkForestTypes.Planet) storage planets,
        mapping(uint256 => DarkForestTypes.PlanetExtendedInfo) storage planetsExtendedInfo,
        mapping(uint256 => DarkForestTypes.ArrivalData) storage planetArrivals
    ) public {
        uint256 _earliestEventTime;
        uint256 _bestIndex;
        do {
            // set to to the upperbound of uint256
            _earliestEventTime = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

            // loops through the array and fine the earliest event times
            for (uint256 i = 0; i < planetEvents[_location].length; i++) {
                if (
                    planetEvents[_location][i].timeTrigger < _earliestEventTime
                ) {
                    _earliestEventTime = planetEvents[_location][i].timeTrigger;
                    _bestIndex = i;
                }
            }

            // TODO: the invalid opcode error is somewhere in this block
            // only process the event if it occurs before the current time and the timeTrigger is not 0
            // which comes from uninitialized PlanetEventMetadata
            if (
                planetEvents[_location].length != 0 &&
                planetEvents[_location][_bestIndex].timeTrigger <=
                block.timestamp
            ) {
                updatePlanet(
                    planets[_location],
                    planetsExtendedInfo[_location],
                    planetEvents[_location][_bestIndex].timeTrigger
                );

                // process event based on event type
                if (
                    planetEvents[_location][_bestIndex].eventType ==
                    DarkForestTypes.PlanetEventType.ARRIVAL
                ) {
                    applyArrival(
                        planets[planetArrivals[planetEvents[_location][_bestIndex]
                            .id]
                            .toPlanet],
                        planetArrivals[planetEvents[_location][_bestIndex].id]
                    );
                }

                // swaps the array element with the one in the end, and pop it
                planetEvents[_location][_bestIndex] = planetEvents[_location][planetEvents[_location]
                    .length - 1];
                planetEvents[_location].pop();
            }
        } while (_earliestEventTime <= block.timestamp);
    }
}

// SPDX-License-Identifier: UNLICENSED
/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity ^0.5.0 || ^0.6.0;

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
  int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;
  int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  /**
   * Convert signed 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromInt (int256 x) internal pure returns (int128) {
    require (x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
    return int128 (x << 64);
  }

  /**
   * Convert signed 64.64 fixed point number into signed 64-bit integer number
   * rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64-bit integer number
   */
  function toInt (int128 x) internal pure returns (int64) {
    return int64 (x >> 64);
  }

  /**
   * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromUInt (uint256 x) internal pure returns (int128) {
    require (x <= 0x7FFFFFFFFFFFFFFF);
    return int128 (x << 64);
  }

  /**
   * Convert signed 64.64 fixed point number into unsigned 64-bit integer
   * number rounding down.  Revert on underflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return unsigned 64-bit integer number
   */
  function toUInt (int128 x) internal pure returns (uint64) {
    require (x >= 0);
    return uint64 (x >> 64);
  }

  /**
   * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
   * number rounding down.  Revert on overflow.
   *
   * @param x signed 128.128-bin fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function from128x128 (int256 x) internal pure returns (int128) {
    int256 result = x >> 64;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Convert signed 64.64 fixed point number into signed 128.128 fixed point
   * number.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 128.128 fixed point number
   */
  function to128x128 (int128 x) internal pure returns (int256) {
    return int256 (x) << 64;
  }

  /**
   * Calculate x + y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function add (int128 x, int128 y) internal pure returns (int128) {
    int256 result = int256(x) + y;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate x - y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sub (int128 x, int128 y) internal pure returns (int128) {
    int256 result = int256(x) - y;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate x * y rounding down.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function mul (int128 x, int128 y) internal pure returns (int128) {
    int256 result = int256(x) * y >> 64;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
   * number and y is signed 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y signed 256-bit integer number
   * @return signed 256-bit integer number
   */
  function muli (int128 x, int256 y) internal pure returns (int256) {
    if (x == MIN_64x64) {
      require (y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
        y <= 0x1000000000000000000000000000000000000000000000000);
      return -y << 63;
    } else {
      bool negativeResult = false;
      if (x < 0) {
        x = -x;
        negativeResult = true;
      }
      if (y < 0) {
        y = -y; // We rely on overflow behavior here
        negativeResult = !negativeResult;
      }
      uint256 absoluteResult = mulu (x, uint256 (y));
      if (negativeResult) {
        require (absoluteResult <=
          0x8000000000000000000000000000000000000000000000000000000000000000);
        return -int256 (absoluteResult); // We rely on overflow behavior here
      } else {
        require (absoluteResult <=
          0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int256 (absoluteResult);
      }
    }
  }

  /**
   * Calculate x * y rounding down, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y unsigned 256-bit integer number
   * @return unsigned 256-bit integer number
   */
  function mulu (int128 x, uint256 y) internal pure returns (uint256) {
    if (y == 0) return 0;

    require (x >= 0);

    uint256 lo = (uint256 (x) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
    uint256 hi = uint256 (x) * (y >> 128);

    require (hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
    hi <<= 64;

    require (hi <=
      0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
    return hi + lo;
  }

  /**
   * Calculate x / y rounding towards zero.  Revert on overflow or when y is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function div (int128 x, int128 y) internal pure returns (int128) {
    require (y != 0);
    int256 result = (int256 (x) << 64) / y;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are signed 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x signed 256-bit integer number
   * @param y signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divi (int256 x, int256 y) internal pure returns (int128) {
    require (y != 0);

    bool negativeResult = false;
    if (x < 0) {
      x = -x; // We rely on overflow behavior here
      negativeResult = true;
    }
    if (y < 0) {
      y = -y; // We rely on overflow behavior here
      negativeResult = !negativeResult;
    }
    uint128 absoluteResult = divuu (uint256 (x), uint256 (y));
    if (negativeResult) {
      require (absoluteResult <= 0x80000000000000000000000000000000);
      return -int128 (absoluteResult); // We rely on overflow behavior here
    } else {
      require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return int128 (absoluteResult); // We rely on overflow behavior here
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divu (uint256 x, uint256 y) internal pure returns (int128) {
    require (y != 0);
    uint128 result = divuu (x, y);
    require (result <= uint128 (MAX_64x64));
    return int128 (result);
  }

  /**
   * Calculate -x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function neg (int128 x) internal pure returns (int128) {
    require (x != MIN_64x64);
    return -x;
  }

  /**
   * Calculate |x|.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function abs (int128 x) internal pure returns (int128) {
    require (x != MIN_64x64);
    return x < 0 ? -x : x;
  }

  /**
   * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function inv (int128 x) internal pure returns (int128) {
    require (x != 0);
    int256 result = int256 (0x100000000000000000000000000000000) / x;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function avg (int128 x, int128 y) internal pure returns (int128) {
    return int128 ((int256 (x) + int256 (y)) >> 1);
  }

  /**
   * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
   * Revert on overflow or in case x * y is negative.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function gavg (int128 x, int128 y) internal pure returns (int128) {
    int256 m = int256 (x) * int256 (y);
    require (m >= 0);
    require (m <
        0x4000000000000000000000000000000000000000000000000000000000000000);
    return int128 (sqrtu (uint256 (m), uint256 (x) + uint256 (y) >> 1));
  }

  /**
   * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y uint256 value
   * @return signed 64.64-bit fixed point number
   */
  function pow (int128 x, uint256 y) internal pure returns (int128) {
    uint256 absoluteResult;
    bool negativeResult = false;
    if (x >= 0) {
      absoluteResult = powu (uint256 (x) << 63, y);
    } else {
      // We rely on overflow behavior here
      absoluteResult = powu (uint256 (uint128 (-x)) << 63, y);
      negativeResult = y & 1 > 0;
    }

    absoluteResult >>= 63;

    if (negativeResult) {
      require (absoluteResult <= 0x80000000000000000000000000000000);
      return -int128 (absoluteResult); // We rely on overflow behavior here
    } else {
      require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return int128 (absoluteResult); // We rely on overflow behavior here
    }
  }

  /**
   * Calculate sqrt (x) rounding down.  Revert if x < 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sqrt (int128 x) internal pure returns (int128) {
    require (x >= 0);
    return int128 (sqrtu (uint256 (x) << 64, 0x10000000000000000));
  }

  /**
   * Calculate binary logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function log_2 (int128 x) internal pure returns (int128) {
    require (x > 0);

    int256 msb = 0;
    int256 xc = x;
    if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
    if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
    if (xc >= 0x10000) { xc >>= 16; msb += 16; }
    if (xc >= 0x100) { xc >>= 8; msb += 8; }
    if (xc >= 0x10) { xc >>= 4; msb += 4; }
    if (xc >= 0x4) { xc >>= 2; msb += 2; }
    if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

    int256 result = msb - 64 << 64;
    uint256 ux = uint256 (x) << 127 - msb;
    for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
      ux *= ux;
      uint256 b = ux >> 255;
      ux >>= 127 + b;
      result += bit * int256 (b);
    }

    return int128 (result);
  }

  /**
   * Calculate natural logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function ln (int128 x) internal pure returns (int128) {
    require (x > 0);

    return int128 (
        uint256 (log_2 (x)) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF >> 128);
  }

  /**
   * Calculate binary exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp_2 (int128 x) internal pure returns (int128) {
    require (x < 0x400000000000000000); // Overflow

    if (x < -0x400000000000000000) return 0; // Underflow

    uint256 result = 0x80000000000000000000000000000000;

    if (x & 0x8000000000000000 > 0)
      result = result * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
    if (x & 0x4000000000000000 > 0)
      result = result * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
    if (x & 0x2000000000000000 > 0)
      result = result * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
    if (x & 0x1000000000000000 > 0)
      result = result * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
    if (x & 0x800000000000000 > 0)
      result = result * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
    if (x & 0x400000000000000 > 0)
      result = result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
    if (x & 0x200000000000000 > 0)
      result = result * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
    if (x & 0x100000000000000 > 0)
      result = result * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
    if (x & 0x80000000000000 > 0)
      result = result * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
    if (x & 0x40000000000000 > 0)
      result = result * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
    if (x & 0x20000000000000 > 0)
      result = result * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
    if (x & 0x10000000000000 > 0)
      result = result * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
    if (x & 0x8000000000000 > 0)
      result = result * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
    if (x & 0x4000000000000 > 0)
      result = result * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
    if (x & 0x2000000000000 > 0)
      result = result * 0x1000162E525EE054754457D5995292026 >> 128;
    if (x & 0x1000000000000 > 0)
      result = result * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
    if (x & 0x800000000000 > 0)
      result = result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
    if (x & 0x400000000000 > 0)
      result = result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
    if (x & 0x200000000000 > 0)
      result = result * 0x10000162E43F4F831060E02D839A9D16D >> 128;
    if (x & 0x100000000000 > 0)
      result = result * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
    if (x & 0x80000000000 > 0)
      result = result * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
    if (x & 0x40000000000 > 0)
      result = result * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
    if (x & 0x20000000000 > 0)
      result = result * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
    if (x & 0x10000000000 > 0)
      result = result * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
    if (x & 0x8000000000 > 0)
      result = result * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
    if (x & 0x4000000000 > 0)
      result = result * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
    if (x & 0x2000000000 > 0)
      result = result * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
    if (x & 0x1000000000 > 0)
      result = result * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
    if (x & 0x800000000 > 0)
      result = result * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
    if (x & 0x400000000 > 0)
      result = result * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
    if (x & 0x200000000 > 0)
      result = result * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
    if (x & 0x100000000 > 0)
      result = result * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
    if (x & 0x80000000 > 0)
      result = result * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
    if (x & 0x40000000 > 0)
      result = result * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
    if (x & 0x20000000 > 0)
      result = result * 0x100000000162E42FEFB2FED257559BDAA >> 128;
    if (x & 0x10000000 > 0)
      result = result * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
    if (x & 0x8000000 > 0)
      result = result * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
    if (x & 0x4000000 > 0)
      result = result * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
    if (x & 0x2000000 > 0)
      result = result * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
    if (x & 0x1000000 > 0)
      result = result * 0x10000000000B17217F7D20CF927C8E94C >> 128;
    if (x & 0x800000 > 0)
      result = result * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
    if (x & 0x400000 > 0)
      result = result * 0x100000000002C5C85FDF477B662B26945 >> 128;
    if (x & 0x200000 > 0)
      result = result * 0x10000000000162E42FEFA3AE53369388C >> 128;
    if (x & 0x100000 > 0)
      result = result * 0x100000000000B17217F7D1D351A389D40 >> 128;
    if (x & 0x80000 > 0)
      result = result * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
    if (x & 0x40000 > 0)
      result = result * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
    if (x & 0x20000 > 0)
      result = result * 0x100000000000162E42FEFA39FE95583C2 >> 128;
    if (x & 0x10000 > 0)
      result = result * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
    if (x & 0x8000 > 0)
      result = result * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
    if (x & 0x4000 > 0)
      result = result * 0x10000000000002C5C85FDF473E242EA38 >> 128;
    if (x & 0x2000 > 0)
      result = result * 0x1000000000000162E42FEFA39F02B772C >> 128;
    if (x & 0x1000 > 0)
      result = result * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
    if (x & 0x800 > 0)
      result = result * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
    if (x & 0x400 > 0)
      result = result * 0x100000000000002C5C85FDF473DEA871F >> 128;
    if (x & 0x200 > 0)
      result = result * 0x10000000000000162E42FEFA39EF44D91 >> 128;
    if (x & 0x100 > 0)
      result = result * 0x100000000000000B17217F7D1CF79E949 >> 128;
    if (x & 0x80 > 0)
      result = result * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
    if (x & 0x40 > 0)
      result = result * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
    if (x & 0x20 > 0)
      result = result * 0x100000000000000162E42FEFA39EF366F >> 128;
    if (x & 0x10 > 0)
      result = result * 0x1000000000000000B17217F7D1CF79AFA >> 128;
    if (x & 0x8 > 0)
      result = result * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
    if (x & 0x4 > 0)
      result = result * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
    if (x & 0x2 > 0)
      result = result * 0x1000000000000000162E42FEFA39EF358 >> 128;
    if (x & 0x1 > 0)
      result = result * 0x10000000000000000B17217F7D1CF79AB >> 128;

    result >>= 63 - (x >> 64);
    require (result <= uint256 (MAX_64x64));

    return int128 (result);
  }

  /**
   * Calculate natural exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp (int128 x) internal pure returns (int128) {
    require (x < 0x400000000000000000); // Overflow

    if (x < -0x400000000000000000) return 0; // Underflow

    return exp_2 (
        int128 (int256 (x) * 0x171547652B82FE1777D0FFDA0D23A7D12 >> 128));
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return unsigned 64.64-bit fixed point number
   */
  function divuu (uint256 x, uint256 y) private pure returns (uint128) {
    require (y != 0);

    uint256 result;

    if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
      result = (x << 64) / y;
    else {
      uint256 msb = 192;
      uint256 xc = x >> 192;
      if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
      if (xc >= 0x10000) { xc >>= 16; msb += 16; }
      if (xc >= 0x100) { xc >>= 8; msb += 8; }
      if (xc >= 0x10) { xc >>= 4; msb += 4; }
      if (xc >= 0x4) { xc >>= 2; msb += 2; }
      if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

      result = (x << 255 - msb) / ((y - 1 >> msb - 191) + 1);
      require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

      uint256 hi = result * (y >> 128);
      uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

      uint256 xh = x >> 192;
      uint256 xl = x << 64;

      if (xl < lo) xh -= 1;
      xl -= lo; // We rely on overflow behavior here
      lo = hi << 128;
      if (xl < lo) xh -= 1;
      xl -= lo; // We rely on overflow behavior here

      assert (xh == hi >> 128);

      result += xl / y;
    }

    require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
    return uint128 (result);
  }

  /**
   * Calculate x^y assuming 0^0 is 1, where x is unsigned 129.127 fixed point
   * number and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x unsigned 129.127-bit fixed point number
   * @param y uint256 value
   * @return unsigned 129.127-bit fixed point number
   */
  function powu (uint256 x, uint256 y) private pure returns (uint256) {
    if (y == 0) return 0x80000000000000000000000000000000;
    else if (x == 0) return 0;
    else {
      int256 msb = 0;
      uint256 xc = x;
      if (xc >= 0x100000000000000000000000000000000) { xc >>= 128; msb += 128; }
      if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
      if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
      if (xc >= 0x10000) { xc >>= 16; msb += 16; }
      if (xc >= 0x100) { xc >>= 8; msb += 8; }
      if (xc >= 0x10) { xc >>= 4; msb += 4; }
      if (xc >= 0x4) { xc >>= 2; msb += 2; }
      if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

      int256 xe = msb - 127;
      if (xe > 0) x >>= xe;
      else x <<= -xe;

      uint256 result = 0x80000000000000000000000000000000;
      int256 re = 0;

      while (y > 0) {
        if (y & 1 > 0) {
          result = result * x;
          y -= 1;
          re += xe;
          if (result >=
            0x8000000000000000000000000000000000000000000000000000000000000000) {
            result >>= 128;
            re += 1;
          } else result >>= 127;
          if (re < -127) return 0; // Underflow
          require (re < 128); // Overflow
        } else {
          x = x * x;
          y >>= 1;
          xe <<= 1;
          if (x >=
            0x8000000000000000000000000000000000000000000000000000000000000000) {
            x >>= 128;
            xe += 1;
          } else x >>= 127;
          if (xe < -127) return 0; // Underflow
          require (xe < 128); // Overflow
        }
      }

      if (re > 0) result <<= re;
      else if (re < 0) result >>= -re;

      return result;
    }
  }

  /**
   * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
   * number.
   *
   * @param x unsigned 256-bit integer number
   * @return unsigned 128-bit integer number
   */
  function sqrtu (uint256 x, uint256 r) private pure returns (uint128) {
    if (x == 0) return 0;
    else {
      require (r > 0);
      while (true) {
        uint256 rr = x / r;
        if (r == rr || r + 1 == rr) return uint128 (r);
        else if (r == rr + 1) return uint128 (rr);
        r = r + rr + 1 >> 1;
      }
    }
  }
}

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.6.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}