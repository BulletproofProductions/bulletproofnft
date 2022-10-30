# Bulletproof Productiona NFT Site Setup
[ Bulletproof Productions ](https://bulletproof.ltd)

<img src="https://bulletproof.ltd/static/media/transparent-logo.5f2cc35b6dd1cca4beb4b902fff5ea98.svg" alt="Bulletproof Productions Logo" style="height: 300px; width:300px;"/>

# What is Bulletproof Productions mission?

Bulletproof Productions mission statement is simple "Turning cents into Dollars 💰' for Artists with Killer Beats.".

Bulletproof Productions gives the power back in the hands of the artist and the fans so they both benefit from creating and enjoying the music they love. Basically, an artist doesn't need millions of fans to keep creating music to be a financially viable activity. All the artists need is 500 – 1000 fans that really want to see them succeed and can support the artist directly. This is where Bulletproof Productions puts the artist and fans in direct contact to create this relationship.

A fan can personalize a track by recording onto an existing track from the artist and own that unique copy, at the same time the artist receives royalties because the fan used the artist's track. Now the fan can also get royalties if anyone uses the fan's unique copy.

# What is a Music NFT?

A music NFT, which stands for music non-fungible token, is a unique digital asset that can be traded on the blockchain which represents an audio-visual composition which can verify digital ownership.

# Why we need music audio NFTs?

Music / Audio NFTs turn the created art back into a commodity that can be owned like an old vinyl record, CD, cassette tape with a visual. The creator / producer of the music / audio can financially benefit from each sale of their creation.

Music NFTs allow fans to invest in artists that they enjoy and believe in, while receiving financial gains in return. Conversely, they allow artists to fund their music projects directly through the support of their fans. A win-win situation for both artists and fans. As opposed to the current dynamic where the artist receives pennies for thousands of streams, and the fans don't get to participate in the direct growth and support of their favorite artist.

One of the inherent benefits of a blockchain is the transparency of data ownership and data creation along with its accessibility not being able to be censored or discriminated or blocked. Anyone with an internet connection and digital funds can participate. This also solves the most part of the problems with Digital Rights Management (DRM).

# How to use Bulletproof Productions to raise funds from your community?

1. Mint a Blank Track with any audio content. Upload a file or use your microphone on your device.
2. Share your new NFT with your community.
3. Every time someone mints an NFT using your shared NFT you make royalties.
4. Connect with the same wallet in step 1 and click on Royalties to claim community royalties.

# Can I sell my Music NFT?

Yes! You can sell your Music NFT on any NFT marketplace or exchange.

Music NFTs can become a very lucrative investment as the track you minted gets more popular alongside the artists popularity and the fanbase increase.

Once you sell your Music NFT you can no longer claim royalties from it.

# Bulletproof Productions Roadmap

## Q1 2023

### Messaging for users (fans, artists, creators) with their wallet address

### Create NFT marketplace

### Completed - Allow minting functionality on mobile devices

## Q2 2023

### Integrate with DistroKid and or APRA for track copyright and royalties

### Integrate with Spotify

### Integrate with Audius

## Q3 2023

### Exclusive locked content offerings by artists, creators

## Q4 2023

### Implement NFT ordering system

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
`const Bulletproof = artifacts.require("Bulletproof");`

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
#### await contract.mintNFT(OWNER_WALLET_ADDRESS, BASE_IPFS_URL)

## Test using Truffle Dashboard
### `truffle dashboard`
### `truffle migrate --network dashboard`
### `truffle console --network dashboard`

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