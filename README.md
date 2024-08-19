# defi-stake

## Deployment Instructions

### 1. Prepare you Sui account

1.1 Verifying Sui Installation

Check that Sui is installed successfully on your system:

    sui --version

1.2 Configuring Sui for Testnet/Mainnet

Configure the Sui client to use the testnet/mainnet RPC:

    sui client new-env --alias testnet --rpc https://fullnode.testnet.sui.io:443

1.3 Switching to the desired Environment

Change your Sui client to the testnet/mainnet environment:

    sui client switch --env testnet
    sui client active-env

1.4 Creating a New Sui Address with your keypair

Create a new account and save the recoveryPhrase for later use:

    sui client new-address ed25519

1.5 Switch to you new Address

Make your active address to be the newly created:

    sui client switch --address {alias}

1.6 Verify your Sui token balance:

    sui client gas

### 2. Deploy Your Smart Contracts on Testnet/Mainnet

2.1 Preparing the Publish Script

Navigate to the /setup directory and grant execute permissions to the publish_e4c.sh and publish_e4c_staking.sh scripts:

    chmod +x publish.sh
    chmod +x publish_staking.sh

2.2 Installing Dependencies

Install necessary library dependencies:

    npm install

2.3 Deploying Contracts

Deploy your contracts to testnet to populate the .env and .env.staking files in the setup/src folder:

    ./publish.sh testnet
    ./publish_staking.sh testnet

### 3. Test Move Call functions by using Typescript calls

3.1 Configure the .env and .env.staking Files according to the template `.template` files

Open the `src/.env` file and fill in the `ADMIN_MNEMOMIC_PHRASE` with the recoveryPhrase from your Sui account creation and the `src/.env.staking` file with a `PLAYER_MNEMOMIC_PHRASE` to test transactions signed by a player.

3.2 Run Typesctipt code to invoke your module functions

       ts-node moveCalls.ts {command}
