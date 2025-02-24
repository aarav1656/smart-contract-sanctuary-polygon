//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./MaticPrice.sol";

contract Buidl is Ownable, MaticPrice {

    struct Course {
        address owner;
        string name;
        uint256 id;
        uint256 price;
        uint256 amountGenerated;
        address[] buyers;
    }

    mapping(uint256 => Course) public courses;
    mapping(address => uint256[]) public ownerToCourses;
    mapping(address => uint256[]) public buyerToCourses;
    mapping(address => bool) public whiteListCourseCreators;
    uint256 public courseCounter;

    function createCourse(string memory _name, uint256 _price) external {
        
        require(
            whiteListCourseCreators[_msgSender()] == true,
            "You are not whitelisted to create courses"
        );

        courseCounter++;

        Course memory newCourse = Course({
            owner: _msgSender(),
            name: _name,
            id: courseCounter,
            price: _price,
            amountGenerated: 0,
            buyers: new address[](0)
        });

        courses[courseCounter] = newCourse;
        ownerToCourses[_msgSender()].push(courseCounter);
    }

    function editCourse(uint256 _courseId, string memory _name, uint256 _price) external {
        
        require(courses[_courseId].id != 0, "Course does not exist");

        require(
            _msgSender() == courses[_courseId].owner,
            "You are not the owner of the course"
        );

        courses[_courseId].name  = _name;
        courses[_courseId].price = _price;
    }

    function deleteCourse(uint256 _courseId) external {

        require(courses[_courseId].id != 0, "Course does not exist");
        
        require(
            _msgSender() == courses[_courseId].owner,
            "You are not the owner of the course"
        );

        require(courses[_courseId].id != 0, "Courses does not exist");

        delete courses[_courseId];
        
        // uint256[] storage coursesOfOwner = ownerToCourses[_msgSender()];
        // for(uint256 i = 0; i < coursesOfOwner.length; i ++) {
        //     if(coursesOfOwner[i] == _id) {
        //         coursesOfOwner[i] = coursesOfOwner[coursesOfOwner.length - 1];
        //         coursesOfOwner.pop();
        //         break;
        //     }
        // }
    }

    function transferCourseOwnership(uint256 _courseId, address _newOwner) external {

        require(courses[_courseId].id != 0, "Course does not exist");

        require(
            _msgSender() == courses[_courseId].owner,
            "You are not the owner of the course"
        );

        delete ownerToCourses[courses[_courseId].owner];
        
        courses[_courseId].owner = _newOwner;
        ownerToCourses[_newOwner].push(_courseId);
    }

    function buyCourseWithMatic(uint256 _courseId) external payable {

        require(courses[_courseId].id != 0, "Course does not exist");

        require (
            _msgSender() != courses[_courseId].owner,
            "You are the owner of the course"
        );

        // require(
        //     courses[_id].price == msg.value,
        //     "The price of the course is not equal to the msg.value"
        // );

        uint256 amountForOwner = (msg.value * 90) / 100;
        buyerToCourses[_msgSender()].push(_courseId);
        courses[_courseId].buyers.push(_msgSender());
        courses[_courseId].amountGenerated += amountForOwner;

        payable(courses[_courseId].owner).transfer(amountForOwner);
    }

    function buyCourseWithUSDT(uint256 _id) external {
        //////////////////////////////////
    }

    function buyCourseWithUSDC(uint256 _id) external {
        //////////////////////////////////
    }

    function addCreatorToWhitelist(address _courseCreator) external onlyOwner {
        whiteListCourseCreators[_courseCreator] = true;
    }

    function removeCreatorFromWhitelist(address _courseCreator) external onlyOwner {
        whiteListCourseCreators[_courseCreator] = false;
    }

    function isCreatorWhitelisted(address _courseCreator) external view returns(bool) {
        return whiteListCourseCreators[_courseCreator];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract MaticPrice {
    AggregatorV3Interface internal priceFeed;

    /**
     * Network: Mumbai
     * Aggregator: MATIC/USD
     * Address: 0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada
     */
    constructor() {
        priceFeed = AggregatorV3Interface(
            0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada
        );
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int) {
        (
            ,
            /*uint80 roundID*/ int price /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/,
            ,
            ,

        ) = priceFeed.latestRoundData();
        return price;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}