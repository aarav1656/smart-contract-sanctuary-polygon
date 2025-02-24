// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC20Permit.sol";

contract MiddleWare {

       function forwardPermit(address _token, address spender,  uint amount, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
       IERC20Permit token = IERC20Permit(_token);
        token.permit(msg.sender, spender, amount, deadline, v, r, s);       
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IERC20Permit {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}