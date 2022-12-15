/**
 *Submitted for verification at polygonscan.com on 2022-12-14
*/

// File: contracts/Context.sol

pragma solidity 0.6.6;

contract Context {
    function msgSender() internal view returns (address payable sender) {
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
            sender = msg.sender;
        }
        return sender;
    }
}

// File: contracts/BasicAccessControl.sol

pragma solidity 0.6.6;

contract BasicAccessControl is Context {
    address payable public owner;
    // address[] public moderators;
    uint16 public totalModerators = 0;
    mapping(address => bool) public moderators;
    bool public isMaintaining = true;

    constructor() public {
        owner = msgSender();
    }

    modifier onlyOwner() {
        require(msgSender() == owner);
        _;
    }

    modifier onlyModerators() {
        require(msgSender() == owner || moderators[msgSender()] == true);
        _;
    }

    modifier isActive() {
        require(!isMaintaining);
        _;
    }

    function ChangeOwner(address payable _newOwner) public onlyOwner {
        if (_newOwner != address(0)) {
            owner = _newOwner;
        }
    }

    function AddModerator(address _newModerator) public onlyOwner {
        if (moderators[_newModerator] == false) {
            moderators[_newModerator] = true;
            totalModerators += 1;
        } else {
            delete moderators[_newModerator];
            totalModerators -= 1;
        }
    }

    function UpdateMaintaining(bool _isMaintaining) public onlyOwner {
        isMaintaining = _isMaintaining;
    }

    function Kill() public onlyOwner {
        selfdestruct(owner);
    }
}

// File: contracts/EthermonStakingBasic.sol

pragma solidity 0.6.6;

contract EthermonStakingBasic is BasicAccessControl {
    struct TokenData {
        uint256 endTime;
        uint256 lastCalled;
        uint16 level;
        uint8 validTeam;
        uint256 teamPower;
        uint256 balance;
        uint16 badge;
        address owner;
        uint64[] monId;
        uint32[] classId;
        uint256 lockId;
        uint256 pfpId;
        uint256 emons;
        Duration duration;
    }

    enum Duration {
        Days_30,
        Days_60,
        Days_90,
        Days_120,
        Days_180,
        Days_365
    }

    uint256 public decimal = 18;

    event TeamPowerLog(uint256 power);

    function setDecimal(uint256 _decimal) external onlyModerators {
        decimal = _decimal;
    }
}

// File: contracts/EthermonStakingData.sol

pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;

contract EthermonStakingData is EthermonStakingBasic {
    event Withdraw(
        address _owner,
        uint64[] _monId,
        uint256 _pfpId,
        uint256 _emons,
        uint256 _endTime,
        uint256 _lastCalled,
        uint256 _lockId,
        uint16 _level,
        uint8 _validTeam,
        uint256 _teamPower,
        uint16 _badge,
        uint256 _balance,
        uint8 _duration
    );

    event Deposite(
        address _from,
        address _to,
        uint64[] _monId,
        uint32[] _classId,
        uint256 _pfpId,
        uint256 _emons,
        uint256 _endTime,
        uint256 _lockId,
        uint16 _level,
        uint256 _teamPower,
        uint16 _badge,
        uint8 _duration
    );

    event UpdateRewards(
        address _owner,
        uint256 _lockId,
        uint256 _pfpId,
        uint256 _timeElapsed,
        uint256 _endTime,
        uint256 _teamPower,
        uint256 _sumTeamPower,
        uint16 _level,
        uint256 _balance,
        uint8 _duration,
        uint256 _lastCalled,
        uint8 _validTeam
    );

    event UpdateData(
        address _owner,
        uint256 _lockId,
        uint64[] _monId,
        uint32[] _classId,
        uint256 _pfpId,
        uint16 _level,
        uint16 _badgeAdvantage,
        uint256 _endTime,
        uint256 lastCalled,
        uint8 _duration
    );

    mapping(uint256 => TokenData) internal tokenIds;
    mapping(address => mapping(uint64 => bool)) internal monIds;
    mapping(address => mapping(uint256 => bool)) internal pfpIds;

    mapping(uint256 => uint256) public miscData; //Can make below variables as dynamic means would be able to add to more variables

    // and all of the functions would be for update this or that would be removed this contract will only store data coming from
    // logical staking contract

    constructor() public {
        // SumTeamPower: 0;
        // NewSumTeamPower: 1;
        // EmonPerPeriod: 2;
        // totalStaked: 3;
        // EmonPeriodMultiplier: 4;
        miscData[0] = 1;
        miscData[1] = 1;
        miscData[2] = 0;
        miscData[3] = 0;
        miscData[4] = 1;
    }

    uint256 public SumTeamPower = 1;
    uint256 public NewSumTeamPower = 1;
    uint256 public EmonPerPeriod = 0;
    uint256 public totalStaked = 0;
    uint16 public EmonPeriodMultiplier = 1;

    function setMiscData(uint256 _index, uint256 _value)
        external
        onlyModerators
    {
        miscData[_index] = _value;
    }

    function addTokenData(bytes memory _data) public onlyModerators {
        TokenData memory data = abi.decode(_data, (TokenData));

        require(data.teamPower > 0, " Team power is 0");

        tokenIds[data.lockId] = data;

        emit Deposite(
            data.owner,
            address(this),
            data.monId,
            data.classId,
            data.pfpId,
            data.emons,
            data.endTime,
            data.lockId,
            data.level,
            data.teamPower,
            data.badge,
            uint8(data.duration)
        );
    }

    function getTokenDataTup(uint256 _lockId)
        public
        view
        returns (TokenData memory)
    {
        TokenData memory token = tokenIds[_lockId];
        return token;
    }

    function getTokenData(uint256 _lockId)
        public
        view
        returns (
            uint256,
            uint256,
            uint16,
            uint8,
            uint256,
            uint256,
            uint16,
            address,
            uint64[] memory,
            uint32[] memory,
            uint256,
            uint256,
            uint256,
            Duration
        )
    {
        uint256 lockId = _lockId;
        TokenData memory token = tokenIds[lockId];
        return (
            token.endTime,
            token.lastCalled,
            token.level,
            token.validTeam,
            token.teamPower,
            token.balance,
            token.badge,
            token.owner,
            token.monId,
            token.classId,
            token.lockId,
            token.pfpId,
            token.emons,
            token.duration
        );
    }

    function getMonStaker(address _owner, uint64 _monId)
        public
        view
        returns (bool)
    {
        require(_monId > 0, "Invalid mon id");
        return monIds[_owner][_monId];
    }

    function getPfpStaker(address _owner, uint256 _pfpId)
        public
        view
        returns (bool)
    {
        require(_pfpId > 0, "Invalid mon id");
        return pfpIds[_owner][_pfpId];
    }

    function setMonStaker(address _owner, uint64 _monId) public onlyModerators {
        require(_monId > 0 && _owner != address(0), "Invalid values provided");
        monIds[_owner][_monId] = true;
    }

    function setPfpStaker(address _owner, uint256 _pfpId)
        public
        onlyModerators
    {
        require(_pfpId > 0 && _owner != address(0), "Invalid values provided");
        pfpIds[_owner][_pfpId] = true;
    }

    function removeMonStaker(address _owner, uint64 _monId)
        public
        onlyModerators
    {
        require(_monId > 0 && _owner != address(0), "Invalid values provided");
        delete monIds[_owner][_monId];
    }

    function removePfpStaker(address _owner, uint256 _pfpId)
        public
        onlyModerators
    {
        require(_pfpId > 0 && _owner != address(0), "Invalid values provided");
        delete pfpIds[_owner][_pfpId];
    }

    function getGlobData()
        public
        view
        returns (
            uint256 _NewSumTeamPower,
            uint256 _SumTeamPower,
            uint256 _EmonPerPeriod,
            uint256 _totalStaked,
            uint256 _EmonPeriodMultiplier
        )
    {
        _SumTeamPower = miscData[0];
        _NewSumTeamPower = miscData[1];
        _EmonPerPeriod = miscData[2];
        _totalStaked = miscData[3];
        _EmonPeriodMultiplier = miscData[4];
    }

    function removeTokenData(TokenData memory _data) public onlyModerators {
        delete tokenIds[_data.lockId];

        emit Withdraw(
            _data.owner,
            _data.monId,
            _data.pfpId,
            _data.emons,
            _data.endTime,
            _data.lastCalled,
            _data.lockId,
            _data.level,
            _data.validTeam,
            _data.teamPower,
            _data.badge,
            _data.balance,
            uint8(_data.duration)
        );
    }

    function updateTokenData(bytes memory _data) public onlyModerators {
        TokenData memory data = abi.decode(_data, (TokenData));
        require(data.owner != address(0), "Data not present");
        tokenIds[data.lockId] = data;
        UpdateData(
            data.owner,
            data.lockId,
            data.monId,
            data.classId,
            data.pfpId,
            data.level,
            data.badge,
            data.endTime,
            data.lastCalled,
            uint8(data.duration)
        );
    }

    function updateTokenReward(
        bytes memory _data,
        uint256 _timeElapsed,
        uint256 _lastCalled
    ) public onlyModerators {
        TokenData memory data = abi.decode(_data, (TokenData));
        require(data.owner != address(0), "Data not present");
        tokenIds[data.lockId] = data;

        emit UpdateRewards(
            data.owner,
            data.lockId,
            data.pfpId,
            _timeElapsed,
            data.endTime,
            data.teamPower,
            SumTeamPower,
            data.level,
            data.balance,
            uint8(data.duration),
            _lastCalled,
            data.validTeam
        );
    }
}