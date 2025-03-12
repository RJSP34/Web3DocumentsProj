const Web3 = require('web3');
const fs = require('fs');

// Connect to Ganache (replace 'http://localhost:7545' with your Ganache server URL)
const ganacheURL = 'http://localhost:7545';
const web3 = new Web3(ganacheURL);

// Read the contract ABI and address
const contractABI = JSON.parse(fs.readFileSync('DocumentState.json', 'utf-8'));
const contractAddress = '0xb139302585dF6445545b3D724f1011F1dB79220D'; // Replace with your contract address

// Create a contract instance
const contract = new web3.eth.Contract(contractABI, contractAddress);

// Example function to interact with the contract
async function interactWithContract() {
    try {
        // Replace 'Alice' and 'Doctor' with the desired username and role
        const userName = 'Alice';
        const userRole = 'Doctor';

        // Get the default account (replace with your desired account)
        const accounts = await web3.eth.getAccounts();
        const defaultAccount = accounts[0];

        // Call the addUser function in the DocumentState contract
        const transaction = await documentStateContract.methods.addUser(userName, userRole).send({ from: defaultAccount });

        console.log('User added successfully. Transaction Hash:', transaction.transactionHash);
    } catch (error) {
        console.error('Error:', error);
    }
}

// Call the function
interactWithContract();