// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;
interface IFactory {
    function admin() external view returns(address);
    function token(address _token) external view returns(uint256 trx_fee, uint256 aff_fee, uint256 arb_fee, bool status);
}

contract Escrow {
    address public super_admin;
    address public affiliation_address;
    address public arbitrator_address;
    address public fee_collector;
    address public  admin;
    address public factory_contract_address;
    uint64 public  withdrawal_period;
    uint64 public  delivery_period;
    uint64 public  inspection_period;
    uint64 public  extension_period;
    uint64 public  request_reply_period;
    uint64 public super_admin_claim_period = 3600;
    uint64 public order_number = 1;
    uint64 public fees_paid_by;
    bool public pause;
    bool internal lock = false;

    struct Order {
        bytes32 order_desc;
        address buyer_address;
        bytes32 order_id;
        address token_address;
        uint256 amount;
        uint256 fee;
        uint64 feepaidby;
        uint256 time;
        Status status;
    }
    struct Token {
        uint256 trx_fee;
        uint256 aff_fee;
        uint256 arb_fee;
        bool status;
    }
    struct Settlement {
        uint256 percentage;
        bool by;
        uint256 requestTime;
        uint8 status;
    }
    struct Extension {
        bool by;
        bool accepted;
    }
    mapping(uint64 => Order) public orders;
    mapping(uint64 => uint64) public extension_time;
    mapping(bytes32 => uint64) public order_ids;
    mapping(address => Token) public tokens;
    mapping(uint64 => Settlement) public settlements;
    mapping(uint64 => Extension) public extensionRequests;

    enum Status {
	    NA, 
        IN, 
        CA, 
        CO, 
        ER, 
        SD, 
        AR, 
        FC
    }
    event NewOrder(bytes32 orderId, uint64 indexed orderNumber);
    event CancelOrder(uint64 indexed orderNumber, address by);
    event CompleteOrder(uint64 indexed orderNumber);
    event SettlementRequest(uint64 indexed orderNumber);
    event SettlementRequestAccepted(uint64 indexed orderNumber, address by);
    event SettlementRequestRejected(uint64 indexed orderNumber, address by);
    event InspectionExtended(uint64 indexed orderNumber, address by);
    event InspectionRequestRejected(uint64 indexed orderNumber, address by);
    event DisputeCreated(uint64 indexed orderNumber, address by);
    event Claim(uint64[] orderNumbers);

    constructor(
        address _admin,
        address _fee_collector,
        address _arbitrator_address,
        address _affiliation_address,
        address[] memory _tokens,
        uint64[6] memory times
    ) {
        admin = _admin;
        arbitrator_address = _arbitrator_address;
        fee_collector = _fee_collector;
        withdrawal_period = times[0];   
        delivery_period = times[1];     
        inspection_period = times[2];   
        extension_period = times[3];    
        request_reply_period = times[4];
        fees_paid_by = times[5];
        affiliation_address = _affiliation_address;
        factory_contract_address = msg.sender;
        super_admin = IFactory(factory_contract_address).admin();
        addToken(_tokens);
    }


    modifier isPause() {
        require(pause==false, "P");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "OA");
        _;
    }

    modifier onlySuperAdmin() {
        require(msg.sender == super_admin, "OSA");
        _;
    }

    modifier validCaller(uint64 _order_num) {
        require(msg.sender == admin || orders[_order_num].buyer_address == msg.sender, "U");
        _;
    }

    function validStatus(uint64 _order_num) private view {
        require(orders[_order_num].status == Status.ER || orders[_order_num].status == Status.IN , "NVS");
    }

    modifier reentrencyGuard() {
        require(!lock, "R");
        lock = true;
        _;
        lock = false;
    }
    
    function validOrder(uint64 _order_num) private view{
        require(checkOrder(_order_num), "IO");
    }

    function validSettlement(uint64 _order_num) private view {
        require(settlements[_order_num].status == 0, "AS");
        require(block.timestamp < settlements[_order_num].requestTime + request_reply_period,"RTRE");
        require(msg.sender == orders[_order_num].buyer_address && settlements[_order_num].by == true
            || (msg.sender==admin && settlements[_order_num].by == false), "U1");
    }

    function checkOrder(uint64 _order_num) private view returns (bool) {
        if(orders[_order_num].buyer_address == address(0))
            return false;
        else
            return true;
    }

    function addToken(address[] memory _tokens) private {
        for(uint i; i < _tokens.length; i++){
            (uint256 trx_fee ,uint256 aff_fee, uint256 arb_fee, bool status)  = IFactory(factory_contract_address).token(_tokens[i]);
            tokens[_tokens[i]] = Token({
            trx_fee: trx_fee,
            aff_fee: aff_fee,
            arb_fee: arb_fee,
            status: status});
            
        }
    }
    
    function calculateFee(address _token, uint256 _amount) private view returns(uint256, uint256) {
        uint256 order_amount;
        uint256 order_fee;
        if(fees_paid_by == 0) {
            order_amount = (_amount*10000) / (tokens[_token].trx_fee+10000);
            order_fee = _amount - order_amount;
        } else {
            order_amount = _amount;
            order_fee = (_amount * tokens[_token].trx_fee) / 10000;
        }
        return (order_amount, order_fee);
    }

    function changeSuperAdmin(address _address) external onlySuperAdmin {
        super_admin = _address;
    }

    function changeArbitrator(address _address) external onlySuperAdmin {
        arbitrator_address = _address;
    }

    function changeAffiliate(address _address) external onlySuperAdmin {
        affiliation_address = _address;
    }

    function changeFeeCollector(address _address) external onlySuperAdmin {
        fee_collector = _address;
    }

    function changeSuperAdminClaimPeriod(uint64 _time) external onlySuperAdmin {
        super_admin_claim_period = _time;
    }

    function changeConfig(address[] memory _tokens, bool[] memory _status, uint64 _fee_paid_by) external onlyAdmin {
        for(uint256 i; i<_tokens.length; i++) {
            if(tokens[_tokens[i]].trx_fee != 0){
                tokens[_tokens[i]].status = _status[i];
            }else{
                (uint256 trx_fee ,uint256 aff_fee, uint256 arb_fee,bool status)  = IFactory(factory_contract_address).token(_tokens[i]);
                require(status, "TNA");
                tokens[_tokens[i]] = Token({
                trx_fee: trx_fee,
                aff_fee: aff_fee,
                arb_fee: arb_fee,
                status: true});
            }
    	}
        fees_paid_by = _fee_paid_by;
    }
    
    function addOrderByToken(address _token, bytes32 _orderId, uint256 _orderAmount, bytes32 _description) 
    external isPause {
        require(!checkOrder(order_ids[_orderId]), "ONE");
        require (tokens[_token].status, "IT");
        (bool success,) = _token.call(abi.encodeWithSignature("transferFrom(address,address,uint256)",msg.sender, address(this), _orderAmount));
	    require(success ,"TFF");
        order_ids[_orderId] = order_number;
        (uint256 odr_amt , uint256 odr_fee ) = calculateFee(_token, _orderAmount);
        orders[order_number] = Order({
            order_desc: _description,
            buyer_address: msg.sender,
            token_address: _token,
            order_id: _orderId,
            amount: odr_amt,
            fee: odr_fee,
            time: block.timestamp,
            feepaidby: fees_paid_by,
            status: Status.IN
        });
        emit NewOrder(_orderId, order_number);
        order_number++;
    }

    function addOrder(bytes32 _orderId, bytes32 _description) external isPause payable {
        require(tokens[address(0)].status, "IT");
        require(!checkOrder(order_ids[_orderId]), "IO");
        
        (uint256 odr_amt , uint256 odr_fee ) = calculateFee(address(0), msg.value);

        order_ids[_orderId] = order_number;
        orders[order_number] = Order({
            order_desc: _description,
            buyer_address: msg.sender,
            token_address: address(0),
            order_id: _orderId,
            amount: odr_amt,
            fee: odr_fee,
            time: block.timestamp,
            feepaidby: fees_paid_by,
            status: Status.IN
        });
        emit NewOrder(_orderId, order_number);
        order_number++;
    }

    function getOrder(bytes32 _orderId) external view returns(uint256 orderNumber, Order memory) {
        return (order_ids[_orderId], orders[order_ids[_orderId]]);
    }

    function cancelOrder(uint64 _order_num) external isPause validCaller(_order_num) reentrencyGuard {
        validOrder(_order_num);
        validStatus(_order_num);
        if(orders[_order_num].buyer_address == msg.sender){
            require(orders[_order_num].time + withdrawal_period > block.timestamp ,"CTP");
        }else {
            require(orders[_order_num].time + withdrawal_period + delivery_period + inspection_period + extension_time[_order_num]
            > block.timestamp, "CTP");
        }
        uint256 amount = orders[_order_num].amount;
        if(orders[_order_num].feepaidby == 0){
            amount = orders[_order_num].amount + orders[_order_num].fee;
        }
        orders[_order_num].status = Status.CA;       
        if(orders[_order_num].token_address == address(0)) {
            payable(orders[_order_num].buyer_address).transfer(amount);
        } else {
            (bool success,) = orders[_order_num].token_address.call(abi.encodeWithSignature("transfer(address,uint256)",orders[_order_num].buyer_address, amount));
            require(success ,"TF");
        }
        emit CancelOrder(_order_num, msg.sender);
    }

    function completeOrder(uint64 _order_num) external isPause reentrencyGuard {
        require(orders[_order_num].buyer_address == msg.sender, "U");
        validStatus(_order_num);
        require(block.timestamp < orders[_order_num].time + withdrawal_period + delivery_period + inspection_period + extension_time[_order_num], "COTP");
        orders[_order_num].status = Status.CO;
        uint256  amt = orders[_order_num].amount;
        uint256  fee = orders[_order_num].fee;
        if(orders[_order_num].feepaidby ==1){
            amt = amt - fee;
        }
        if (orders[_order_num].token_address == address(0)) {
            if(affiliation_address != address(0)){
                uint256 affiliation = (fee * (tokens[orders[_order_num].token_address].aff_fee/100)) / 100;
                fee = fee - affiliation;
                payable(affiliation_address).transfer(affiliation);
            }
            payable(admin).transfer(amt);
            payable(fee_collector).transfer(fee);
        }else{
            if(affiliation_address != address(0)){
                uint256 affiliation = ((orders[_order_num].fee * (tokens[orders[_order_num].token_address].aff_fee/100)) / 100);
                fee = orders[_order_num].fee - affiliation;
                (bool success1,) = orders[_order_num].token_address.call(abi.encodeWithSignature("transfer(address,uint256)",affiliation_address, affiliation));
                require(success1 ,"TF");
            }
            (bool success2,) = orders[_order_num].token_address.call(abi.encodeWithSignature("transfer(address,uint256)",admin, amt));
            require(success2 ,"TF");
            
            (bool success3,) = orders[_order_num].token_address.call(abi.encodeWithSignature("transfer(address,uint256)",fee_collector, fee));
            require(success3 ,"TF");
        }
        emit CompleteOrder(_order_num);
    }

    function settlementRequest(uint64 _order_num, uint256 _percentage) external isPause {
        validStatus(_order_num);
        validOrder(_order_num);
        require((block.timestamp > orders[_order_num].time + withdrawal_period)
            && (block.timestamp < orders[_order_num].time + withdrawal_period + delivery_period + inspection_period + extension_time[_order_num]), "ST");
        require(settlements[_order_num].percentage == 0 || settlements[_order_num].status == 2, "SP");
        if (msg.sender == admin) {
            settlements[_order_num] = Settlement({
                percentage: _percentage,
                by: true,
                requestTime: block.timestamp,
                status: 0
            });
        } else if (orders[_order_num].buyer_address == msg.sender) {
            settlements[_order_num] = Settlement({
                percentage: _percentage,
                by: false,
                requestTime: block.timestamp,
                status: 0
            });
        } else {
            revert("forbidden");
        }
        emit SettlementRequest(_order_num);
    }
    function acceptSettlementRequest(uint64 _order_num) external isPause reentrencyGuard {
        validSettlement(_order_num);
        validStatus(_order_num);
        uint256 amt = orders[_order_num].amount;
        uint256 fee = orders[_order_num].fee;
        if(orders[_order_num].feepaidby == 1){
            amt = amt-fee;
        }
        uint256 refund = (amt * settlements[_order_num].percentage) / 100;
        uint256 remain = amt - refund;
        orders[_order_num].status = Status.SD;
        settlements[_order_num].status = 1;
        if(orders[_order_num].token_address == address(0)) {
            if(affiliation_address != address(0)){
                uint256 affiliation = (fee * (tokens[orders[_order_num].token_address].aff_fee/100)) / 100;
                fee = fee - affiliation;
                payable(affiliation_address).transfer(affiliation);
            }
            payable(orders[_order_num].buyer_address).transfer(refund);
            payable(admin).transfer(remain);
            payable(fee_collector).transfer(fee);
        } else {
            address token_address = orders[_order_num].token_address;
            if(affiliation_address != address(0)){
                uint256 affiliation = (fee * (tokens[token_address].aff_fee)) / 10000;
                fee = fee - affiliation;
                (bool success1,) = token_address.call(abi.encodeWithSignature("transfer(address,uint256)",affiliation_address, affiliation));
                require(success1 ,"TF");
            }
            (bool success2,) = token_address.call(abi.encodeWithSignature("transfer(address,uint256)",orders[_order_num].buyer_address, refund));
            require(success2 ,"TF");
            
            (bool success3,) = token_address.call(abi.encodeWithSignature("transfer(address,uint256)",admin, remain));
            require(success3 ,"TF");

            (bool success4,) = token_address.call(abi.encodeWithSignature("transfer(address,uint256)",fee_collector, fee));
            require(success4 ,"TF");
        }
        emit SettlementRequestAccepted(_order_num, msg.sender);
    }
    function rejectSettlementRequest(uint64 _order_num) external isPause {
        validSettlement(_order_num);
        settlements[_order_num].status = 2;
        emit SettlementRequestRejected(_order_num, msg.sender);
    }
    
    function extendInspectionRequest(uint64 _order_num) external isPause validCaller(_order_num) {
        require(orders[_order_num].status == Status.IN, "IN");
        validOrder(_order_num);
        require((block.timestamp > orders[_order_num].time + withdrawal_period + delivery_period)
            && (block.timestamp < orders[_order_num].time + withdrawal_period + delivery_period + inspection_period), "DTP");

        if(msg.sender == admin) {
            extensionRequests[_order_num] = Extension({
                by: true,
                accepted: true
            });
        } else {
            extensionRequests[_order_num] = Extension({
                by: false,
                accepted: true
            });
        }
        extension_time[_order_num] = extension_period;
        orders[_order_num].status = Status.ER;
        emit InspectionExtended(_order_num, msg.sender);
    }
    function rejectInspectionRequest(uint64 _order_num) external isPause onlyAdmin{
        require(orders[_order_num].status == Status.ER 
        && block.timestamp < orders[_order_num].time + withdrawal_period + delivery_period + inspection_period + extension_time[_order_num],"ER");
        validOrder(_order_num);
        extension_time[_order_num] = 0;
        extensionRequests[_order_num].accepted = false;
        orders[_order_num].status = Status.IN;
        emit InspectionRequestRejected(_order_num, msg.sender);
    }

    function addDispute(uint64 _order_num) external payable isPause validCaller(_order_num)  reentrencyGuard {
        validOrder(_order_num);
        validStatus(_order_num);
        require(msg.value >= tokens[orders[_order_num].token_address].arb_fee, "ARF");
        require((block.timestamp > orders[_order_num].time + withdrawal_period + delivery_period)
            && (block.timestamp < orders[_order_num].time + withdrawal_period + delivery_period + inspection_period), "DTP");

        payable(arbitrator_address).transfer(orders[_order_num].amount + msg.value);
        orders[_order_num].status = Status.AR;
        emit DisputeCreated(_order_num, msg.sender);
    }
    function addDisputeByToken(uint64 _order_num) external isPause validCaller(_order_num) reentrencyGuard {
        validOrder(_order_num);
        validStatus(_order_num);
        require((block.timestamp > orders[_order_num].time + withdrawal_period + delivery_period)
            && (block.timestamp < orders[_order_num].time + withdrawal_period + delivery_period + inspection_period), "DTP");

        (bool success1,) = orders[_order_num].token_address.call(abi.encodeWithSignature("transfer(address,uint256)",arbitrator_address, orders[_order_num].amount));
        require(success1 ,"TF");
        
        (bool success2,) = orders[_order_num].token_address.call(abi.encodeWithSignature("transferFrom(address,address,uint256)",
        msg.sender, arbitrator_address, tokens[orders[_order_num].token_address].arb_fee));
	    require(success2 ,"TFF");

        orders[_order_num].status = Status.AR;
        emit DisputeCreated(_order_num, msg.sender);
    }

    function claim(uint64[] memory _order_nums) external isPause onlyAdmin reentrencyGuard{
        for(uint64 i; i<_order_nums.length; i++) {
            uint64  _order_num = _order_nums[i];

            require(orders[_order_num].status == Status.ER || orders[_order_num].status == Status.IN, "INER"); 
            require(settlements[_order_num].percentage == 0, "NST");
            require(((block.timestamp > orders[_order_num].time
                        + withdrawal_period + delivery_period +inspection_period + extension_time[_order_num])
                        && (block.timestamp < orders[_order_num].time
                        + withdrawal_period + delivery_period +inspection_period + extension_time[_order_num]
                        +  super_admin_claim_period))
                    ,"CTP");
            orders[_order_num].status = Status.CO;
            uint256  amt = orders[_order_num].amount;
            uint256  fee = orders[_order_num].fee;
            if(orders[_order_num].feepaidby==1){
                amt = orders[_order_num].amount - fee;
            }
            if (orders[_order_num].token_address == address(0)) {
                if(affiliation_address != address(0)){
                    uint256 affiliation = (fee * (tokens[orders[_order_num].token_address].aff_fee/100)) / 100;
                    fee = fee - affiliation;
                    payable(fee_collector).transfer(affiliation);
                }
                payable(admin).transfer(amt);
                payable(fee_collector).transfer(fee);
            }else{
                if(affiliation_address != address(0)){
                    uint256 affiliation = ((orders[_order_num].fee * (tokens[orders[_order_num].token_address].aff_fee/100)) / 100);
                    fee = orders[_order_num].fee - affiliation;
                    (bool success1,) = orders[_order_num].token_address.call(abi.encodeWithSignature("transfer(address,uint256)",affiliation_address, affiliation));
                    require(success1 ,"TF");
                }
                (bool success2,) = orders[_order_num].token_address.call(abi.encodeWithSignature("transfer(address,uint256)",admin, amt));
                require(success2 ,"TF");
                
                (bool success3,) = orders[_order_num].token_address.call(abi.encodeWithSignature("transfer(address,uint256)",fee_collector, fee));
                require(success3 ,"TF");
            }
        }
        emit Claim(_order_nums);
    }

    function superClaim(uint64[] memory _order_nums) external onlySuperAdmin reentrencyGuard{
        for(uint64 i; i<_order_nums.length; i++) {
            uint64  _order_num = _order_nums[i];
            
            require(orders[_order_num].status == Status.ER || orders[_order_num].status == Status.IN, "INER"); 
            require(block.timestamp >= orders[_order_num].time
                        + withdrawal_period + delivery_period +inspection_period 
                        + extension_time[_order_num]
                        +  super_admin_claim_period
                    ,"SCT");
            orders[_order_num].status = Status.FC;
            uint256 amt = orders[_order_num].amount;
            if(orders[_order_num].feepaidby == 0){
                amt = orders[_order_num].amount + orders[_order_num].fee;
            }
            if (orders[_order_num].token_address == address(0)) {
                payable(admin).transfer(amt);
            } else {
                (bool success1,) = orders[_order_num].token_address.call(abi.encodeWithSignature("transfer(address,uint256)",super_admin, amt));
                require(success1 ,"TF");
            }
        }
        emit Claim(_order_nums);
    }


}