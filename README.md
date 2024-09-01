# Swell Network Multichain - Hackathon Project

## Overview
Swell Network is renowned for delivering the best liquid staking and liquid restaking experience in DeFi. The Swell Network Multichain project takes this vision to the next level by enabling cross-chain liquid staking through the integration of Wormhole. This development opens up new DeFi opportunities for swEth (Swell's liquid staking asset) across multiple blockchain networks.

## Project Purpose
The primary goal of the Swell Network Multichain project is to extend the liquid staking paradigm of Swell Network to a multi-chain environment. By integrating Wormhole, this project facilitates seamless cross-chain staking and asset management, enabling users to participate in liquid staking on various Layer 2 (L2) chains while maintaining the security and liquidity of Ethereum.

## Key Features
- **Cross-Chain Liquid Staking:** Users can stake their WETH on any supported L2 chain and receive swEth, a liquid staking asset, on their native chain. This cross-chain capability is powered by Wormhole's NTT hub-and-spoke model.
  
- **Atomic Transactions:** The entire staking and bridging process happens within a single transaction, ensuring a smooth and efficient user experience without the need for multiple steps or interactions.

- **DeFi Integration:** With swEth available on multiple chains, users can explore new DeFi opportunities, such as yield farming, lending, and collateralization, all within the multi-chain ecosystem.

## Technical Architecture
The project consists of two primary smart contracts:

1. **LayerTransmitter Contract (L2 Chains):**
   - Resides on supported L2 chains.
   - Users interact with this contract to initiate the staking process.
   - Handles the cross-chain transfer of WETH to the Ethereum mainnet using Wormhole's NTT.
   - Bridges the WETH to the `SourceSentinel` contract on Ethereum, initiating the staking process.

2. **SourceSentinel Contract (Ethereum):**
   - Resides on the Ethereum mainnet.
   - Receives WETH from the `LayerTransmitter` contract via cross-chain messaging.
   - Deposits the WETH into Swell Network's staking contracts to mint swEth.
   - Sends the swEth back to the user’s native chain via Wormhole, completing the transaction.

## Deployed Contracts

### Avalanche Fuji
- **WETH.sol**: `0x69F6Db8B53370bFF222bD12E709aA0184662B199`
- **swEth.sol**: `0xA218e581A7692395C2aBCC2A2c8F51f6056fDEb3`
- **NttManager**: `0x66Ac6b94384BDe6ec5d668D6456469cE5e062903`
- **Transceiver**: `0x94B049cb72E2dDD660CE165F54580bA26f02F09B`

### BSC Testnet
- **WethNTT.sol**: `0x972c872e8d3a8B47601024E00EC0847B1Aee0097`
- **swEthNTT.sol**: `0xC4dfA45e2eE923A3907bb3A0AB5f07FB690D254a`
- **NttManager**: `0x03637F25f403d5e427A678c88DD089cF61ec06F9`
- **Transceiver**: `0xdB0533D2eCbe54cC3D151BD4c3CdE973F52584A2`

- **SourceSentinel**: `0xbb84536BA7B0370018c96b84b65fB039216f9789`
- **LayerTransmitter**: `0x2266C317a185f54A892F3fAC4330004feeAFeA29`

## How It Works
1. **Deposit WETH:** The user deposits WETH into the `LayerTransmitter` contract on their respective L2 chain.

2. **Cross-Chain Transfer:** The `LayerTransmitter` contract uses Wormhole's NTT to securely transfer the WETH to the `SourceSentinel` contract on Ethereum.

3. **Staking on Ethereum:** The `SourceSentinel` contract stakes the WETH into Swell Network's staking contracts, minting the corresponding swEth.

4. **Receive swEth:** The swEth is then sent back to the user’s L2 chain using Wormhole's cross-chain messaging, completing the entire process in one atomic transaction.

5. **Explore DeFi:** With swEth now available on the user’s chain, they can explore a variety of DeFi opportunities.

## Conclusion
The Swell Network Multichain project brings the power of liquid staking to a multi-chain environment, offering users unparalleled flexibility and access to DeFi opportunities across different blockchain networks. By leveraging Wormhole's robust cross-chain infrastructure, the project ensures that staking and asset management are as seamless and secure as possible. This innovation not only enhances the utility of swEth but also solidifies Swell Network’s position as a leader in the DeFi space.
