/**
 *Submitted for verification at polygonscan.com on 2023-04-04
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;


abstract contract INFT {
    function getApproved(uint256 tokenId) external virtual returns (address);
    function isApprovedForAll(address account, address operator) external virtual returns (bool);
    function transferFrom(address from, address to, uint256 tokenId) external virtual;
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external virtual;
    function safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external virtual;
}

contract NFTReceiver {

    bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;
    bytes4 constant ERC1155_RECEIVED = 0xf23a6e61;
    bytes4 constant ERC1155_BATCH_RECEIVED = 0xbc197c81;

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns(bytes4) {
        return ERC1155_RECEIVED;
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata) external pure returns(bytes4) {
        return ERC1155_BATCH_RECEIVED;
    }
    function onERC721Received(address, uint256, bytes calldata) external pure returns(bytes4) {
        return ERC721_RECEIVED;
    }
}

contract AccessControl {

    bool public paused = false;
    address public owner;
    address public newContractOwner;
    mapping(address => bool) public authorizedContracts;

    event Pause();
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        owner = msg.sender;
    }

    modifier ifNotPaused {
        require(!paused);
        _;
    }

    modifier onlyContractOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyAuthorizedContract {
        require(authorizedContracts[msg.sender]);
        _;
    }

    modifier onlyContractOwnerOrAuthorizedContract {
        require(authorizedContracts[msg.sender] || msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyContractOwner {
        require(_newOwner != address(0));
        newContractOwner = _newOwner;
    }

    function acceptOwnership() public ifNotPaused {
        require(msg.sender == newContractOwner);
        emit OwnershipTransferred(owner, newContractOwner);
        owner = newContractOwner;
        newContractOwner = address(0);
    }

    function setAuthorizedContract(address _buyContract, bool _approve) public onlyContractOwner {
        if (_approve) {
            authorizedContracts[_buyContract] = true;
        } else {
            delete authorizedContracts[_buyContract];
        }
    }

    function setPause(bool _paused) public onlyContractOwner {
        paused = _paused;
        if (paused) {
            emit Pause();
        }
    }

}

contract AssetLocking is AccessControl, NFTReceiver {

    uint256 lockingPeriod = 86400;

    mapping(address => mapping(address => mapping(uint256 => uint256))) private _lockedAssets;
    mapping(address => uint256) private _lockedAssetsCount;
    mapping(address => uint256) private _lockedUntil;
    mapping(address => bool) private _isErc721;

    event LockAsset(address indexed owner, address contractAddress, uint256 tokenId);
    event LockBatchAssets(address indexed owner, address contractAddress, uint256[] tokenIds, uint256[] amounts);
    event RelockAsset(address indexed owner);
    event UnlockAsset(address indexed owner, address contractAddress, uint256 tokenId);
    event UnlockBatchAssets(address indexed owner, address contractAddress, uint256[] tokenIds, uint256[] amounts);

    constructor() {

    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return bytes4(keccak256("supportsInterface(bytes4)")) == interfaceId;
    }

    function setLockingPeriod(uint256 _lockingPeriod) onlyContractOwner external returns (bool) {
        lockingPeriod = _lockingPeriod;
        return true;
    }

    function lock(address contractAddress, uint256 tokenId) external returns (uint256) {
        INFT nftContract = INFT(contractAddress);
        try nftContract.getApproved(tokenId) {
            if (nftContract.getApproved(tokenId) == address(this)) {
                nftContract.transferFrom(msg.sender, address(this), tokenId);
                _isErc721[contractAddress] = true;
            } else { revert(); }
        } catch {
            if (nftContract.isApprovedForAll(msg.sender, address(this))) {
                nftContract.safeTransferFrom(msg.sender, address(this), tokenId, 1, "");
            } else {
                revert();
            }
        }

        _lockedAssets[msg.sender][contractAddress][tokenId]++;
        _lockedAssetsCount[msg.sender]++;
        _lockedUntil[msg.sender] = block.timestamp + lockingPeriod;

        // return new timestamp the asset is locked until
        emit LockAsset(msg.sender, contractAddress, tokenId);
        return _lockedUntil[msg.sender];
    }

    function lockBatch(address contractAddress, uint256[] memory tokenIds, uint256[] memory amounts) external returns (uint256) {
        INFT nftContract = INFT(contractAddress);
        try nftContract.getApproved(1) {
            revert();
        } catch {
            if (nftContract.isApprovedForAll(msg.sender, address(this))) {
                nftContract.safeBatchTransferFrom(msg.sender, address(this), tokenIds, amounts, "");
            } else {
                revert();
            }
        }

        for (uint256 j = 0; j < amounts.length ; j++) {
            _lockedAssets[msg.sender][contractAddress][tokenIds[j]] += amounts[j];
            _lockedAssetsCount[msg.sender] += amounts[j];
        }
        _lockedUntil[msg.sender] = block.timestamp + lockingPeriod;

        // return new timestamp the asset is locked until
        emit LockBatchAssets(msg.sender,contractAddress,tokenIds,amounts);
        return _lockedUntil[msg.sender];
    }

    function relock() external returns (uint256) {
        _lockedUntil[msg.sender] = block.timestamp + lockingPeriod;

        // return new timestamp the asset is locked until
        emit RelockAsset(msg.sender);
        return _lockedUntil[msg.sender];
    }

    function unlock(address contractAddress, uint256 tokenId) external returns (uint256) {
        require(_lockedAssets[msg.sender][contractAddress][tokenId] > 0, "Insufficient assets locked!");
        require(_lockedUntil[msg.sender] < block.timestamp, "Assets are still locked!");

        _lockedAssets[msg.sender][contractAddress][tokenId]--;
        _lockedAssetsCount[msg.sender]--;

        if (_isErc721[contractAddress]) {
            INFT(contractAddress).transferFrom(address(this), msg.sender, tokenId);
        } else {
            INFT(contractAddress).safeTransferFrom(address(this), msg.sender, tokenId, 1, "");
        }

        // return remaining locked count
        emit UnlockAsset(msg.sender,contractAddress,tokenId);
        return _lockedAssets[msg.sender][contractAddress][tokenId];
    }

    function unlockBatch(address contractAddress, uint256[] memory tokenIds, uint256[] memory amounts) external returns (uint256) {
        require(tokenIds.length==amounts.length, "Length of tokenIds and amounts does not match!");
        require(_lockedUntil[msg.sender] < block.timestamp, "Assets are still locked!");
        require(_isErc721[contractAddress] == false, "Batch transfers are only supported for ERC1155!");

        for (uint256 j = 0; j < amounts.length ; j++) {
            require(_lockedAssets[msg.sender][contractAddress][tokenIds[j]] >= amounts[j], "Insufficient assets locked!");

            _lockedAssets[msg.sender][contractAddress][tokenIds[j]] -= amounts[j];
            _lockedAssetsCount[msg.sender] -= amounts[j];
        }

        INFT(contractAddress).safeBatchTransferFrom(address(this), msg.sender, tokenIds, amounts, "");

        // return remaining locked total count
        emit UnlockBatchAssets(msg.sender,contractAddress,tokenIds,amounts);
        return _lockedAssetsCount[owner];
    }

    function checkCount(address owner, address contractAddress, uint256 tokenId) external view returns (uint256) {
        return _lockedAssets[owner][contractAddress][tokenId];
    }

    function checkTotalCount(address owner) external view returns (uint256) {
        return _lockedAssetsCount[owner];
    }

    function checkUntil(address owner) external view returns (uint256) {
        return _lockedUntil[owner];
    }

}