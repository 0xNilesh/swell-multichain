// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import "../src/SourceSentinel.sol";
import "../src/interfaces/wormhole/INttManager.sol";
import "../src/interfaces/wormhole/IWormholeTransceiver.sol";
import "../src/interfaces/wormhole/IWormholeRelayer.sol";
import "../src/libraries/wormhole-lib/TransceiverStructs.sol";

contract SourceSentinelSetup is Script {
    SourceSentinel public sourceSentinel;
    address public swEth = 0xA218e581A7692395C2aBCC2A2c8F51f6056fDEb3;
    address public wormholeRelayer = 0xA3cF45939bD6260bcFe3D66bc73d60f19e49a8BB;
    
    address public nttManager = 0x17aDe3eba711cB68dA8Ff8a47a90F1b23F5fe641;
    address public wormholeTransceiver = 0xc397768651B920730eE5d2ce0dCF92d418Cb39C9;
    uint16 public sourceChain = 4;

    function run() public {
        vm.startBroadcast();

        sourceSentinel = new SourceSentinel(swEth, wormholeRelayer, wormholeTransceiver, nttManager);

        vm.stopBroadcast();
    }
}
