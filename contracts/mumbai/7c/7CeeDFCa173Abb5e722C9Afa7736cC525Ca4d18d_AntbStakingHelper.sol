// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import './interfaces/IERC20.sol';
import './interfaces/IAntbStaking.sol';

contract AntbStakingHelper {
    address public immutable staking;
    address public immutable ANTB;

    constructor(address _staking, address _ANTB) {
        require(_staking != address(0));
        staking = _staking;
        require(_ANTB != address(0));
        ANTB = _ANTB;
    }

    function stake(uint256 _amount, address _recipient) external {
        IERC20(ANTB).transferFrom(msg.sender, address(this), _amount);
        IERC20(ANTB).approve(staking, _amount);
        IAntbStaking(staking).stake(_amount, _recipient);
        IAntbStaking(staking).claim(_recipient);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

interface IERC20Mintable {
    function mint(uint256 amount_) external;

    function mint(address account_, uint256 ammount_) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

interface IAntbStaking {
    function stake(uint256 _amount, address _recipient) external returns (bool);

    function claim(address _recipient) external;
}