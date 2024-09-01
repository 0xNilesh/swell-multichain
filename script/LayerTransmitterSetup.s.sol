// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import "../src/LayerTransmitter.sol";
import "../src/interfaces/wormhole/INttManager.sol";
import "../src/interfaces/wormhole/IWormholeTransceiver.sol";
import "../src/interfaces/wormhole/IWormholeRelayer.sol";
import "../src/libraries/wormhole-lib/TransceiverStructs.sol";

contract LayerTransmitterSetup is Script {
    LayerTransmitter public layerTransmitter;
    address public sourceSentinel = 0xbb84536BA7B0370018c96b84b65fB039216f9789;
    address _wethNTT = 0x972c872e8d3a8B47601024E00EC0847B1Aee0097;
    address _nttManager = 0x03637F25f403d5e427A678c88DD089cF61ec06F9;
    IWormholeTransceiver _wormholeTransceiver =
        IWormholeTransceiver(0xdB0533D2eCbe54cC3D151BD4c3CdE973F52584A2);
    IWormholeRelayer _wormholeRelayerAddress =
        IWormholeRelayer(0x80aC94316391752A193C1c47E27D382b507c93F3);
    uint16 _recipientChain = 6;

    function run() public {
        vm.startBroadcast();

        layerTransmitter = new LayerTransmitter(sourceSentinel);

        layerTransmitter.setBridgeConfig(
            _wethNTT,
            _nttManager,
            _wormholeTransceiver,
            _wormholeRelayerAddress,
            _recipientChain
        );

        vm.stopBroadcast();
    }
}
