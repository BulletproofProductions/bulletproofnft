# Bulletproof Productiona NFT Site Setup
[ Bulletproof Productions ](https://bulletproof.ltd)

<img src="https://bulletproof.ltd/static/media/transparent-logo.5f2cc35b6dd1cca4beb4b902fff5ea98.svg" alt="Bulletproof Productions Logo" style="height: 300px; width:300px;"/>

## Setup:
### Node version 18.7.0
### `npm install ganache --global`
### `npm install -g truffle`
### `npm install -g  @truffle/hdwallet-provider --save-dev`

### `npm i react-app-rewired`

# Create config-overrides.js file and add this:

const webpack = require('webpack');
module.exports = function override(config, env) {

    config.resolve.fallback = {
        url: require.resolve('url'),
        util: require.resolve('util'),
        assert: require.resolve('assert'),
        crypto: require.resolve('crypto-browserify'),
        http: require.resolve('stream-http'),
        https: require.resolve('https-browserify'),
        os: require.resolve('os-browserify/browser'),
        buffer: require.resolve('buffer'),
        stream: require.resolve('stream-browserify'),
    };
    config.plugins.push(
        new webpack.ProvidePlugin({
            process: 'process/browser',
            Buffer: ['buffer', 'Buffer'],
        }),
    );

    return config;
}

Install all the packages from config-overrides.js.
### `npm install buffer`
### `npm install util`
### `npm install stream-browserify`
### `npm install assert`
### `npm install stream-http`
### `npm install url`
### `npm install https-browserify`
### `npm install os-browserify`
### `npm install crypto-browserify`

In package.json, replace the scripts:

"scripts": {
    "start": "react-app-rewired start",
    "build": "react-app-rewired build",
    "test": "react-app-rewired test",
    "eject": "react-app-rewired eject"
  },

# https setup for ganache
### `npm install -g ganache-http-proxy`
### `ganache-http-proxy`

### `ganache`
### `truffle migrate --reset`
### `npm start`




# Contract Deployment

## Set NODE OPTIONS re:digital envelope error
`NODE_OPTIONS = "--openssl-legacy-provider"`

## Create Truffle Project with testing env setup
### `truffle init nft-royalty`
### `cd nft-royalty`
### `truffle create contract Bulletproof`
### `truffle create test TestBulletproof`

## Install OpenZeppelin dependencies
`npm i "@openzeppelin/contracts"`

## WRITE SMART-CONTRACT

modify migrations/1_deploy_contracts.js like so:
const Bulletproof = artifacts.require("Bulletproof");

module.exports = function (deployer) {
  deployer.deploy(Bulletproof);
};

uncomment the development network in your truffle-config.js
and modify the port number to 7545 to match
development: {
  host: "127.0.0.1",     // Localhost (default: none)
  port: 7545,            // Standard Ethereum port (default: none)
  //port: 8545,            // ganache-cli default port
  network_id: "*",       // Any network (default: none)
}

### Start ganache gui
Open ganache gui or type
`ganache-cli`

### Build contracts
`truffle migrate`

### Deploy On Specific Network
Need MNUMONIC from METAMASK and Infura API KEYS
`truffle deploy --network NETWORK_NAME_FROM_truffle-config.js`
`truffle deploy --network matic`

### Test contracts
`truffle test`

## Install and use .env for private credential security
### `npm i --save-dev dotenv`
### `npm i --save-dev @truffle/hdwallet-provider`

### .env file contents
### MNEMONIC from Metamask account private key
MNEMONIC="YOUR SECRET KEY"
INFURA_API_KEY="YOUR INFURA_API_KEY"

### At the top of truffle-config.js, add this code to populate from .env
require('dotenv').config();
const mnemonic = process.env["MNEMONIC"];
const metamask_mnemonic = process.env["METAMASK_MNENONIC"];
const infuraApiKey = process.env["INFURA_API_KEY"];

const HDWalletProvider = require('@truffle/hdwallet-provider');

## Deploy contracts to testnet
### `truffle migrate --network goerli`
### `truffle migrate --network ropsten`

## Test using truffle console
### `truffle console --network goerli`
### `truffle console --network ropsten`

#### const contract = await Bulletproof.deployed()
#### await contract.mintNFT("0xFFc1E591B61F9ecBb9f8e9C421307Dec2f07970b", "ipfs://bafybeiffapvkruv2vwtomswqzxiaxdgm2dflet2cxmh6t4ixrgaezumbw4")

## Test using Truffle Dashboard
### `truffle dashboard`
### `truffle migrate --network dashboard`
### `truffle console --network dashboard`

# Getting Started

## Available Scripts

In the project directory, you can run:

### `npm start`

Runs the app in the development mode.\
Open [http://localhost:3000](http://localhost:3000) to view it in your browser.

The page will reload when you make changes.\
You may also see any lint errors in the console.

### `npm test`

Launches the test runner in the interactive watch mode.\
See the section about [running tests](https://facebook.github.io/create-react-app/docs/running-tests) for more information.

### `npm run build`

Builds the app for production to the `build` folder.\
It correctly bundles React in production mode and optimizes the build for the best performance.

The build is minified and the filenames include the hashes.\
Your app is ready to be deployed!

See the section about [deployment](https://facebook.github.io/create-react-app/docs/deployment) for more information.

### `npm run eject`

**Note: this is a one-way operation. Once you `eject`, you can't go back!**

If you aren't satisfied with the build tool and configuration choices, you can `eject` at any time. This command will remove the single build dependency from your project.

Instead, it will copy all the configuration files and the transitive dependencies (webpack, Babel, ESLint, etc) right into your project so you have full control over them. All of the commands except `eject` will still work, but they will point to the copied scripts so you can tweak them. At this point you're on your own.

You don't have to ever use `eject`. The curated feature set is suitable for small and middle deployments, and you shouldn't feel obligated to use this feature. However we understand that this tool wouldn't be useful if you couldn't customize it when you are ready for it.
