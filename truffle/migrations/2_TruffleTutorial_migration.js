// Help Truffle find `TruffleTutorial.sol` in the `/contracts` directory
const DocumentState = artifacts.require("DocumentState");

const UserState = artifacts.require("User");

const RoleState = artifacts.require("Role");

module.exports = function (deployer) {
    // Command Truffle to deploy the Smart Contract
    // Deploy RoleState first
    deployer.deploy(RoleState).then(function () {
        // Deploy UserState, passing RoleState.address as a parameter
        return deployer.deploy(UserState, RoleState.address);
    }).then(function () {
        // Deploy DocumentState, passing UserState.address as a parameter
        return deployer.deploy(DocumentState, UserState.address);
    });

};