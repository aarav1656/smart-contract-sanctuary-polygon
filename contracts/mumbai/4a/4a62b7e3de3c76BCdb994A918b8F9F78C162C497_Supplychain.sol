// SPDX-License-Identifier: GPL-3.0
pragma solidity >= 0.8.9;
contract Supplychain {
    address owner;
   constructor() {
      owner = msg.sender;
   }
uint256 product_id=0;
struct Product{
    uint256 id;
    string name;
    string price;
    string description;
    string reqtemp;
    string manufacturing;
    uint256 timestamp;
}
struct Status{
    string location;
    uint256 timestamp;
    string temp;
    string humidity;
    string heatindex;
    uint256 p_id;
    uint256 total_quantity;
    bool flag;
}
struct Data {
    uint256 temp;
    uint256 humidity;
    uint256 hindex;
    uint256 pid;
}
modifier onlyOwner {
      require(msg.sender == owner);
      _;
   }
Product[] public products_list;
Product private productInfo;
Status[] public productStatus;
Status private statusInfo;
Data[] public Data_list;
Data private DataInfo;
mapping(uint256 => Status[]) public product_Status;
mapping (uint256 => Product) public products;
mapping (uint256 => Data[]) public data;
mapping(uint256 => address)private proowner;
mapping(uint256 => address)private inter;
function AddProduct(
    string memory name,
    string memory price,
    string memory description,
    string memory reqtemp,
    string memory manufacturing,
    address intermediate) public payable
{
    productInfo=Product(product_id,name,price,description,reqtemp,manufacturing,block.timestamp);
    products[product_id]=(productInfo);
    products_list.push(productInfo);
    proowner[product_id]=msg.sender;
    inter[product_id]=intermediate;
    product_id++;
}
function AddStatus( string memory location,
    string  memory temp,
    string  memory humidity,
    string  memory heatindex,
    uint256 pid,
    uint256 total_quantity,
    bool flag
) public payable {
    require(proowner[pid]==msg.sender || inter[pid]==msg.sender,'differnet user');
    statusInfo= Status(location,block.timestamp,temp,humidity,heatindex,pid,total_quantity,flag);
    product_Status[pid].push(statusInfo);
    productStatus.push(statusInfo);
}
function AddData( uint256 temp,
    uint256 humidity,
    uint256 hindex,uint256 pid) public payable{
    require(proowner[pid]==msg.sender || inter[pid]==msg.sender,'differnet user');
        DataInfo = Data(temp,humidity,hindex,pid);
        data[pid].push(DataInfo);
        Data_list.push(DataInfo);
        }
function getProductStatus(uint256 id) public view returns(Status[] memory){
    return product_Status[id];
}
function getProductData(uint256 id) public view returns(Data[] memory){
    return data[id];
}
function getProducts() public view returns(Product[] memory){
    return products_list ;
}
}