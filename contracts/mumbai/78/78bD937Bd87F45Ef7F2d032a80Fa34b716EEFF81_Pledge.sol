// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Pledge is IERC721ReceiverUpgradeable, OwnableUpgradeable {
    uint256 private STAKE_STATUS_STAKING; // 质押中
    uint256 private STAKE_STATUS_CANCELED; // 已赎回
    uint256 private WEEK_TIMESTAMP;  //一周时间戳
    uint256 private DAY_TIMESTAMP;  //一天时间戳
    uint256 public DAY_FREE_REWARD;  //每日积分奖励 FREE
    uint256 public DAY_TOLL_REWARD;  //每日积分奖励 TOLL


    function initialize() public initializer
    {
        __Ownable_init();

        STAKE_STATUS_STAKING = 1;
        STAKE_STATUS_CANCELED = 2;
        WEEK_TIMESTAMP = 7200;
        DAY_TIMESTAMP = 900;
        DAY_FREE_REWARD = 20;
        DAY_TOLL_REWARD = 100;
    }

    
    /* NFT配置模块 */
    IERC721Upgradeable public NFT;
    function setNftAddress(IERC721Upgradeable _contractAddress) public
    {
        NFT = _contractAddress;
    }
    /* End */



    /* 用户信息模块 */

    struct UserInfo {
        uint256 ogStake; //OG质押数量
        uint256 nftStake; //NFT质押数量
        uint256 actualScore; //用户实际已拥有的积分
        uint256 estimatedScore; //用户预估所得积分
    }

    mapping (address => UserInfo) public userInfos;
    mapping (address => uint256) public userStore;

    //OG质押数量 NFT质押数量 用户实际已拥有的积分 用户预估所得积分
    function getUserInfo(address _address) public view returns (uint256, uint256, uint256, uint256)
    {
        uint256 ogStake = getStakeCount(_address, 0);
        uint256 nftStake = getStakeCount(_address, 1);
        uint256 estimatedScore = getAllPendingProfit(_address);
        
        return (ogStake, nftStake, userStore[_address], estimatedScore);
    }

    function getStakeCount(address _address, uint256 _type) internal view returns (uint256)
    {   
        uint256 count = 0;

        for(uint256 i = 0; i < addressStakePendingRecords[_address].length; i++){
            if((_type == 0 && addressStakePendingRecords[_address][i].tokenId < 100001) || (_type == 1 && addressStakePendingRecords[_address][i].tokenId >= 100001) ){
                count ++;
            }
        }
        
        return count;
    }

    /* End */



    /* 活动设置模块 */
    struct eventInfo {
        uint256 period; //期数
        uint256 startTime;// 开始时间
        uint256 endTime; //结束时间
    }
    mapping (uint256 => eventInfo) public eventInfos;
    eventInfo[] public eventArray;

    function setEventsInfo(uint256 _period, uint256 _start, uint256 _end) public 
    {
        eventInfo memory e = eventInfo({
            period: _period,
            startTime: _start,
            endTime: _end
        });

        eventInfos[_period] = e;
        eventArray.push(e);
    }

    // 根据时间戳获取周期
    function getPeriod() public view returns (uint256) 
    {
        uint256 timestamp = getBlockTimestamp();
        uint256 period = 0;

        for(uint256 i = 0; i < eventArray.length; i++){
            if(timestamp > eventArray[i].startTime && timestamp <= eventArray[i].endTime){
                period = eventArray[i].period;
                break;
            }
        }
        
        return period;
    }
    /* End */




    /* 质押模块 */
    struct StakeInfo {
        uint256 id;// 质押id
        uint256 period; //质押活动的期数
        uint256 tokenId;// 质押数量
        uint256 week; //质押周期（周为单位）
        uint256 startTime;// 质押开始时间
        // uint256 endTime; //质押结束时间
        uint256 received; //已领取的积分数量
        uint256 status;// 状态
    }
    
    mapping (address => uint256) private addressIdMap; //按顺序生成记录Id
    address[] stakeAddressList; //质押过的用户列表
    mapping (address => StakeInfo[]) public addressStakeRecords; //根据(地址)获取质押的历史记录
    mapping (address => StakeInfo[]) public addressStakePendingRecords; //根据(地址)获取正在质押中的记录
    
    mapping (address => mapping(uint256 => StakeInfo[])) public addressTypeRecords; //根据(地址，币种类型)获取质押的历史记录



    mapping (address => mapping(uint256 => StakeInfo)) public addressStakeDetail; //根据(地址,记录ID)获取详细的质押记录
    mapping (uint256 => address) public tokenIds; //质押中的NFT列表

    //质押
    function stake(uint256 _tokenId, uint256 _week) payable public 
    {
        NFT.safeTransferFrom(_msgSender(), address(this), _tokenId);

        if (addressStakeRecords[_msgSender()].length == 0) {
            stakeAddressList.push(_msgSender());
        }

        uint256 period = getPeriod();
        uint256 sid = addressIdMap[_msgSender()];

        StakeInfo memory o = StakeInfo({
            id: sid,
            period: period,
            tokenId: _tokenId,
            week: _week,
            startTime: block.timestamp, //12
            received: 0,
            status: STAKE_STATUS_STAKING
        });
        addressStakeRecords[_msgSender()].push(o);
        addressStakePendingRecords[_msgSender()].push(o);
        addressStakeDetail[_msgSender()][sid] = o;
        addressIdMap[_msgSender()] = sid + 1;
        tokenIds[_tokenId] = _msgSender();
    }
    
    // 单笔赎回
    function takeBack(uint256 _id) public
    {
        // 判断订单是否质押中
        require(addressStakeDetail[_msgSender()][_id].status == STAKE_STATUS_STAKING, "Redeemed");

        uint256 income = getPendingProfit(_msgSender(), _id, 1);

        for (uint256 i = 0; i < addressStakeRecords[_msgSender()].length; i++) {
            if (addressStakeRecords[_msgSender()][i].id == _id) {
                addressStakeRecords[_msgSender()][i].status = STAKE_STATUS_CANCELED;
                addressStakeRecords[_msgSender()][i].received += income;

                addressStakeDetail[_msgSender()][_id].status = STAKE_STATUS_CANCELED;
                addressStakeDetail[_msgSender()][_id].received += income;

                uint256 tokenId = addressStakeRecords[_msgSender()][i].tokenId; 
                NFT.safeTransferFrom(address(this), tokenIds[tokenId], tokenId);
                delete tokenIds[tokenId];

                userStore[_msgSender()] += income;
                break;
            }
        }

        for (uint256 i = 0; i < addressStakePendingRecords[_msgSender()].length; i++) {
            if (addressStakePendingRecords[_msgSender()][i].id == _id) {
                delete addressStakePendingRecords[_msgSender()][i];
                break;
            }
        }
        
        // 
    }
    
    // 领取全部收益
    function receiveBenefits() public 
    {
        uint256 e = 0;

        for(uint256 i = 0; i < addressStakePendingRecords[_msgSender()].length; i++){
            uint256 income = getPendingProfit(_msgSender(), addressStakePendingRecords[_msgSender()][i].id, 1);
            e += (income - addressStakePendingRecords[_msgSender()][i].received);

            addressStakeRecords[_msgSender()][i].received += income;
            addressStakePendingRecords[_msgSender()][i].received += income;
            addressStakeDetail[_msgSender()][i].received += income;
        }
        
        userStore[_msgSender()] += e;
    }

    // 获取地址所有质押历史记录
    function getAddressStakeRecords(address _address) public view returns (StakeInfo[] memory) 
    {
        return addressStakeRecords[_address];
    }
    
    // 查询所有质押记录汇总的预估积分收益
    function getAllPendingProfit(address _address) public view returns (uint256) 
    {
        uint256 e;

        for(uint256 i = 0; i < addressStakePendingRecords[_address].length; i++){
            if(addressStakePendingRecords[_address][i].tokenId < 100001){
                if((block.timestamp - addressStakeDetail[_address][i].startTime) >= addressStakeDetail[_address][i].week * WEEK_TIMESTAMP){
                    // 判断是否满足质押整个周期
                    e += calcFreeProfit(addressStakePendingRecords[_address][i].startTime, addressStakePendingRecords[_address][i].startTime + addressStakePendingRecords[_address][i].week * WEEK_TIMESTAMP);
                }else{
                    for(uint256 j = 0; j < eventArray.length; j++){
                        if(block.timestamp > eventArray[j].endTime && eventArray[j].period >= addressStakeDetail[_address][i].period){
                            if(addressStakePendingRecords[_address][i].period == eventArray[j].period){
                                e += calcFreeProfit(addressStakePendingRecords[_address][i].startTime, eventArray[j].endTime);
                            }else{
                                e += calcFreeProfit(eventArray[j].startTime, eventArray[j].endTime);
                            }
                        }else if(block.timestamp > eventArray[j].startTime && block.timestamp < eventArray[j].endTime){
                            e += calcFreeProfit(addressStakeDetail[_address][i].startTime, block.timestamp);
                        }
                    }
                }
            }else{
               if((block.timestamp - addressStakeDetail[_address][i].startTime) >= addressStakeDetail[_address][i].week * WEEK_TIMESTAMP){
                    // 判断是否满足质押整个周期
                    e += calcTollProfit(addressStakePendingRecords[_address][i].startTime, addressStakePendingRecords[_address][i].startTime + addressStakePendingRecords[_address][i].week * WEEK_TIMESTAMP);
                }else{
                    for(uint256 j = 0; j < eventArray.length; j++){
                        if(block.timestamp > eventArray[j].endTime && eventArray[j].period >= addressStakeDetail[_address][i].period){
                            if(addressStakePendingRecords[_address][i].period == eventArray[j].period){
                                e += calcTollProfit(addressStakePendingRecords[_address][i].startTime, eventArray[j].endTime);
                            }else{
                                e += calcTollProfit(eventArray[j].startTime, eventArray[j].endTime);
                            }
                        }else if(block.timestamp > eventArray[j].startTime && block.timestamp < eventArray[j].endTime){
                            e += calcTollProfit(addressStakeDetail[_address][i].startTime, block.timestamp);
                        }
                    }
                }
            }
            // 扣除已领取收益
            e -= addressStakePendingRecords[_address][i].received;
        }

        return e;
    }

    // 查询单笔质押收益（预估）
    function getPendingProfit(address _address, uint256 _id, uint256 _type) public view returns (uint256) 
    {
        //_address 用户地址
        //_id 记录ID
        //_type 类别，0为统计预估收益 1为统计实际可获取收益


        uint256 e = 0;

        if(addressStakeDetail[_address][_id].tokenId < 100001){
            // Free
            if((block.timestamp - addressStakeDetail[_address][_id].startTime) >= addressStakeDetail[_address][_id].week * WEEK_TIMESTAMP){
                // 判断是否满足质押整个周期
                e += calcFreeProfit(addressStakeDetail[_address][_id].startTime, addressStakeDetail[_address][_id].startTime + addressStakeDetail[_address][_id].week * WEEK_TIMESTAMP);
            }else{
                for(uint256 i = 0; i < eventArray.length; i++){
                    if(block.timestamp > eventArray[i].endTime && eventArray[i].period >= addressStakeDetail[_address][_id].period){
                        if(addressStakeDetail[_address][_id].period == eventArray[i].period){
                            e += calcFreeProfit(addressStakeDetail[_address][_id].startTime, eventArray[i].endTime);
                            break;
                        }else{
                            e += calcFreeProfit(eventArray[i].startTime, eventArray[i].endTime);
                            break;
                        }
                    }else if(block.timestamp > eventArray[i].startTime && block.timestamp < eventArray[i].endTime){
                        if(_type == 0){
                            e += calcFreeProfit(addressStakeDetail[_address][_id].startTime, block.timestamp);
                            break;
                        }
                    }
                }   
            }
        }else{
            // Toll
            if((block.timestamp - addressStakeDetail[_address][_id].startTime) >= addressStakeDetail[_address][_id].week * WEEK_TIMESTAMP){
                // 判断是否满足质押整个周期
                e += calcTollProfit(addressStakeDetail[_address][_id].startTime, addressStakeDetail[_address][_id].startTime + addressStakeDetail[_address][_id].week * WEEK_TIMESTAMP);
            }else{
                for(uint256 i = 0; i < eventArray.length; i++){
                    if(block.timestamp > eventArray[i].endTime && eventArray[i].period >= addressStakeDetail[_address][_id].period){
                        if(addressStakeDetail[_address][_id].period == eventArray[i].period){
                            e += calcTollProfit(addressStakeDetail[_address][_id].startTime, eventArray[i].endTime);
                        }else{
                            e += calcTollProfit(eventArray[i].startTime, eventArray[i].endTime);
                        }
                    }else if(block.timestamp > eventArray[i].startTime && block.timestamp < eventArray[i].endTime){
                        if(_type == 0){
                            e += calcTollProfit(addressStakeDetail[_address][_id].startTime, block.timestamp);
                        }
                    }
                }   
            }
        }

        // 扣除已领取收益
        e -= addressStakeDetail[_address][_id].received;

        return e;
    }

    // 计算收益（FREE）
    function calcFreeProfit(uint256 _start, uint256 _end) internal view returns (uint256)
    {
        if (_start > _end) {
            return 0;
        }
        return (_end - _start) / DAY_TIMESTAMP * DAY_FREE_REWARD;
    }
    // 计算收益（TOLL）
    function calcTollProfit(uint256 _start, uint256 _end) internal view returns (uint256)
    {
        if (_start > _end) {
            return 0;
        }
        return (_end - _start) / DAY_TIMESTAMP * DAY_TOLL_REWARD;
    }

    function firstAdd() public 
    {
        eventInfo memory o = eventInfo({
            period: 1,
            startTime: 1668009600, //10
            endTime: 1668268800 //13
        });
        eventArray.push(o);
    }

    function secAdd() public 
    {
        eventInfo memory o = eventInfo({
            period: 2,
            startTime: 1668268800, //13
            endTime: 1668873600 //20
        });
        eventArray.push(o);
    }

    function thAdd() public 
    {
        eventInfo memory o = eventInfo({
            period: 3,
            startTime: 1668873600, //20
            endTime: 1669478400 //27
        });
        eventArray.push(o);
    }

    function getBlockTimestamp() public view returns (uint256) 
    {
        return block.timestamp;
    }

     function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override pure returns (bytes4) {
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
                /// @solidity memory-safe-assembly
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