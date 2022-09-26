// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Rentals {

    struct User {
        address addr;
        uint balance;
        bytes32 uId;
        bool exists;
    }

    struct Estate {
        uint price;
        User landlord;
        User tenant;
        bytes32 eId;
        string description;
        bool exists;
    }
    event registrated(bytes32 uId);
    event deposited(bytes32 id, uint value);
    event added(uint, bytes32, string);
    event rented(bytes32, bytes32);
    address public owner;
    uint public commission;

    constructor () {
        owner = msg.sender;
    }

    modifier ownerOnly() {
        require(owner == msg.sender, "You are not an owner");
        _;
    }

    mapping(bytes32 => User) users;
    mapping(bytes32 => Estate) rentals;
    bytes32[] ids;

    function registrate() external {
        bytes32 id = generateUserId(msg.sender);
        require (users[id].exists != true, "Already registered");
        users[id] = User({
            addr: msg.sender,
            balance: 0,
            uId: id,
            exists: true
        });

        emit registrated(users[id].uId);
    }

    function deposit() external payable {
        bytes32 id = generateUserId(msg.sender);

        require (users[id].exists == true, "Registrate firstly");

        users[id].balance = msg.value * 9 / 10;
        commission = msg.value * 1 / 10;
        emit deposited(id, msg.value);
    }

    function balance() external view returns (uint) {
        bytes32 id = generateUserId(msg.sender);
        return(users[id].balance);
    }

    function addEstate(
        uint _price,
        string calldata _description
    )
    external {
        bytes32 id = generatePropertyId(_price, _description, msg.sender);
        bytes32 uId = generateUserId(msg.sender);
        require (rentals[id].exists != true, "Already added");

        rentals[id] = Estate({
            price: _price,
            landlord: users[uId],
            tenant: users[uId],
            eId: id,
            description: _description,
            exists: true
        });
        
        emit added(_price, id, _description);

    }

    function rent(bytes32 _id) external {
        bytes32 uId = generateUserId(msg.sender);

        require(users[uId].balance >= rentals[_id].price, "Not enough funds to rent");
        users[uId].balance -= rentals[_id].price;
        rentals[_id].landlord.balance += rentals[_id].price;
        rentals[_id].tenant = users[uId];

        emit rented(uId, _id);
    }

    function withdraw(uint _amount) external payable {
        bytes32 uId = generateUserId(msg.sender);
        require(users[uId].balance >= _amount);
        payable(msg.sender).transfer(_amount);
        users[uId].balance -= _amount;
    }

    function withdrawComission(address _to) external payable ownerOnly{
        payable(_to).transfer(commission);
        commission=0;
    }
    function generateUserId(address _addr) internal pure returns(bytes32)
    {
        return(keccak256(abi.encode(_addr)));
    }

    function generatePropertyId(uint _price,
        string calldata _description, address _addr) internal pure returns(bytes32)
    {
        return(keccak256(abi.encode(_price, _description, _addr)));
    }
}