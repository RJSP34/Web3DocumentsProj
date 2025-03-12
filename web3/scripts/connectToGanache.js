require('dotenv').config();
const { ethers } = require('hardhat');
const Web3 = require('web3');

async function deployToGanache() {
    // Connect to the local Ganache blockchain via Hardhat
    const ganacheUrl = process.env.GANACHE_URL // Update with your Hardhat network URL
    let web3;

    // Handle different versions of web3
    if (Web3.providers.HttpProvider) {
        web3 = new Web3(new Web3.providers.HttpProvider(ganacheUrl));
    } else {
        web3 = new Web3(ganacheUrl);
    }
    // Check if the connection is successful
    const networkId = await web3.eth.net.getId();
    console.log('Connected to network with ID:', networkId);

    // Get the signer from Hardhat
    const [deployer] = await ethers.getSigners();

    // Get the contract factories
    const YourContract = await ethers.getContractFactory('DocumentState'); // Replace with your actual contract name

    // Deploy the contracts
    const yourContract = await YourContract.deploy();
    await yourContract.deployed();

    console.log('YourContract deployed to:', yourContract.address);
}

deployToGanache();
