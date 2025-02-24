/**
 *Submitted for verification at polygonscan.com on 2023-04-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Immutables {
    address private _owner;
    address[] private uniV3Factories;
    address[] private kyberV3Factories;
    address[] private uniV2Factories;

    constructor(){
        _owner = msg.sender;
    }

    modifier owner(){
        require (tx.origin==_owner);_;
    }
    
    function setUniV3Factories(address[] calldata factories) public owner{
        uniV3Factories=factories;
    }

    function setKyberV3Factories(address[] calldata factories) public owner{
        kyberV3Factories=factories;
    }

    function setUniV2Factories(address[] calldata factories) public owner{
        uniV2Factories=factories;
    }

    function getUniV3Factories() public view returns(address[] memory){
        return uniV3Factories;
    }

    function getKyberV3Factories() public view returns(address[] memory){
        return kyberV3Factories;
    }

    function getUniV2Factories() public view returns(address[] memory){
        return uniV2Factories;
    }

    function poolImmutables(address pool)public view returns (address t0,address t1,uint24 fee,bytes4 selector){
        for(uint i=0;i<uniV3Factories.length;i++)
            if(IPool(pool).factory()== uniV3Factories[i])
                return (IUniV3Pool(pool).token0(), IUniV3Pool(pool).token1(),IUniV3Pool(pool).fee(),bytes4(keccak256(bytes("uniV3Swap(address,address)"))));
        for(uint i=0;i<kyberV3Factories.length;i++)
            if(IPool(pool).factory()== kyberV3Factories[i])
                return (IKyberV3Pool(pool).token0(), IKyberV3Pool(pool).token1(),IKyberV3Pool(pool).swapFeeUnits()*10,bytes4(keccak256(bytes("kyberV3Swap(address,address)"))));
        for(uint i=0;i<uniV2Factories.length;i++)
            if (IPool(pool).factory()== uniV2Factories[i])
                return (IUniV2Pool(pool).token0(),IUniV2Pool(pool).token1(),3000,bytes4(keccak256(bytes("uniV2Swap(address,address)"))));
    }
}

interface IPool{
    function factory() external view returns (address);
}

interface IUniV2Pool {
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface IUniV3Pool {
    function swap(address recipient,bool zeroForOne,int256 amountSpecified,uint160 sqrtPriceLimitX96,bytes calldata data) external returns (int256 amount0, int256 amount1);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function fee() external view returns (uint24);
}

interface IKyberV3Pool {
    function swap(address recipient,int256 swapQty,bool isToken0,uint160 limitSqrtP,bytes calldata data) external returns (int256 amount0, int256 amount1);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function swapFeeUnits() external view returns (uint24);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient,uint256 amount) external returns (bool);
    function allowance(address owner,address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
}