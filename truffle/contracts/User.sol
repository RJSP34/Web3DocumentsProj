// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./Role.sol"; 

contract User {
    struct UserData {
        address publicAddress;
        string name;
        Role.UserRole role; 
        uint256 createdDate;
        uint256 lastChangedDate;
    }

    mapping(address => UserData) private users;
    uint256 private numberOfUsers;

    Role private roleContract;

    event UserCreated(address indexed userAddress, string name, uint256 createdDate, Role.UserRole role);
    event UserUpdated(address indexed userAddress, uint256 lastChangedDate);

    constructor(address _roleContractAddress) {
        roleContract = Role(_roleContractAddress);
    }

    function createUser(string memory _name, Role.UserRole _role) external {
        require(users[msg.sender].publicAddress == address(0), "User already exists");

        if (_role == Role.UserRole.Patient){
            roleContract.grantPatientRole(msg.sender);
        } else if (_role == Role.UserRole.MedicalPersonal){
            roleContract.grantMedicalPersonalRole(msg.sender);
        } else if (_role == Role.UserRole.None){
            roleContract.grantNoneRole(msg.sender);
        } else {
            revert("Invalid role");
        }

        UserData storage newUser = users[msg.sender];
        newUser.publicAddress = msg.sender;
        newUser.name = _name;
        newUser.createdDate = block.timestamp;
        newUser.role = _role;
        numberOfUsers++;

        emit UserCreated(msg.sender, newUser.name, newUser.createdDate, newUser.role);
    }

    function updateUser(string memory _newUserName) external {
        require(bytes(_newUserName).length > 0, "New user name must not be empty");
        require(bytes(_newUserName).length <= 255, "New user name is too long");

        require(users[msg.sender].publicAddress != address(0), "User does not exist");

        UserData storage existingUser = users[msg.sender];

        require(keccak256(bytes(existingUser.name)) != keccak256(bytes(_newUserName)), "New user name is the same as the current name");

        existingUser.name = _newUserName;
        existingUser.lastChangedDate = block.timestamp;

        emit UserUpdated(msg.sender, existingUser.lastChangedDate);
    }

    function getUser() external view returns (
        address publicAddress,
        string memory name,
        Role.UserRole role,
        uint256 createdDate,
        uint256 lastChangedDate) {
        require(userExists(msg.sender), "User does not exist");

        UserData storage existingUser = users[msg.sender];

        return (
            existingUser.publicAddress,
            existingUser.name,
            existingUser.role,
            existingUser.createdDate,
            existingUser.lastChangedDate
        );
    }

    function userExists(address _userAddress) internal view returns (bool) {
        return users[_userAddress].publicAddress != address(0);
    }

    function hasMedicalPersonalRole() external view returns (bool) {
        return roleContract.getPacientRole(msg.sender) == Role.UserRole.MedicalPersonal;
    }

    function hasPatientRole() external view returns (bool) {
        return roleContract.getPacientRole(msg.sender) == Role.UserRole.Patient;
    }
}
