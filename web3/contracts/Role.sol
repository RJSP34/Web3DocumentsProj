// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract Role {
    enum UserRole { None, Patient, MedicalPersonal }

    mapping(address => UserRole) private userRoles;

    modifier onlyMedicalPersonal() {
        require(userRoles[msg.sender] == UserRole.MedicalPersonal, "Access denied. Requires Medical Personal role");
        _;
    }

    modifier onlyPatient() {
        require(userRoles[msg.sender] == UserRole.Patient, "Access denied. Requires Patient role");
        _;
    }

    struct RoleProperties {
        bool allowCreatePatientRecord;
        bool allowAccessPatientRecord;
        bool allowSignPatientRecord;
    }

    mapping(UserRole => RoleProperties) private rolePermissions;

    constructor() {
        rolePermissions[UserRole.None] = RoleProperties(false, false, false);
        rolePermissions[UserRole.Patient] = RoleProperties(false, false, true);
        rolePermissions[UserRole.MedicalPersonal] = RoleProperties(true, true, false);
    }

    function grantMedicalPersonalRole(address _userAddress) external  {
        userRoles[_userAddress] = UserRole.MedicalPersonal;
    }

    function grantPatientRole(address _userAddress) external  {
        userRoles[_userAddress] = UserRole.Patient;
    }

    function grantNoneRole(address _userAddress) external  {
        userRoles[_userAddress] = UserRole.None;
    }

    function getPacientRole(address _userAddress) external view returns (UserRole) {
        return userRoles[_userAddress];
    }

    function canCreatePatientRecord() external view returns (bool) {
        return rolePermissions[userRoles[msg.sender]].allowCreatePatientRecord;
    }

    function canAccessPatientRecord() external view returns (bool) {
        return rolePermissions[userRoles[msg.sender]].allowAccessPatientRecord;
    }
}
