// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./interfaces/wormhole/INttManager.sol";
import "./interfaces/wormhole/IWormholeTransceiver.sol";
import "./interfaces/wormhole/IWormholeRelayer.sol";
import "./libraries/wormhole-lib/TransceiverStructs.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LayerTransmitter is Ownable {
    IERC20 public WETH_NTT;
    INttManager public NTT_MANAGER;
    IWormholeTransceiver public WORMHOLE_TRANSCEIVER;
    IWormholeRelayer public WORMHOLE_RELAYER;
    uint16 public WORMHOLE_RECIPIENT_CHAIN;
    address public sourceSentinel;

    address public pushChannelAdmin;

    constructor(address _sourceSentinel) Ownable() {
        sourceSentinel = _sourceSentinel;
    }

    function setBridgeConfig(
        address _wethNTT,
        address _nttManager,
        IWormholeTransceiver _wormholeTransceiver,
        IWormholeRelayer _wormholeRelayerAddress,
        uint16 _recipientChain
    )
        external
        onlyOwner
    {
        WETH_NTT = IERC20(_wethNTT);
        NTT_MANAGER = INttManager(_nttManager);
        WORMHOLE_TRANSCEIVER = IWormholeTransceiver(_wormholeTransceiver);
        WORMHOLE_RELAYER = IWormholeRelayer(_wormholeRelayerAddress);
        WORMHOLE_RECIPIENT_CHAIN = _recipientChain;
    }

    /**
     * @notice Quotes the cost of bridging tokens to the recipient chain
     * @dev Calls the Wormhole Transceiver to get the delivery price
     * @return cost The cost of bridging tokens
     */
    function quoteTokenBridgingCost() public view returns (uint256 cost) {
        TransceiverStructs.TransceiverInstruction memory transceiverInstruction =
            TransceiverStructs.TransceiverInstruction({ index: 0, payload: abi.encodePacked(false) });
        cost = WORMHOLE_TRANSCEIVER.quoteDeliveryPrice(WORMHOLE_RECIPIENT_CHAIN, transceiverInstruction);
    }

    /**
     * @notice Quotes the cost of relaying a message to the target chain with the specified gas limit
     * @dev Calls the Wormhole Relayer to get the EVM delivery price
     * @param targetChain The chain to which the message is being relayed
     * @param gasLimit The gas limit for the message relay
     * @return cost The cost of relaying the message
     */
    function quoteMsgRelayCost(uint16 targetChain, uint256 gasLimit) public view returns (uint256 cost) {
        (cost,) = WORMHOLE_RELAYER.quoteEVMDeliveryPrice(targetChain, 0, gasLimit);
    }

    function deposit(uint256 amount, bytes32 recipient) external {
        // Transfer WETH_NTT tokens from the sender to this contract
        require(WETH_NTT.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        uint16 recipientChain = WORMHOLE_RECIPIENT_CHAIN;

        uint256 messageBridgeCost = quoteMsgRelayCost(recipientChain, gasLimit);
        uint256 tokenBridgeCost = quoteTokenBridgingCost();

        INttManager NttManager = NTT_MANAGER;

        WETH_NTT.approve(address(NttManager), amount);
        NttManager.transfer{ value: tokenBridgeCost }(
            amount,
            recipientChain,
            BaseHelper.addressToBytes32(sourceSentinel),
            BaseHelper.addressToBytes32(msg.sender),
            false,
            new bytes(1)
        );

        // Encode amount and msg.sender into the requestPayload
        bytes memory requestPayload = abi.encode(amount, msg.sender);

        // Relay the RequestData Payload
        WORMHOLE_RELAYER.sendPayloadToEvm{ value: messageBridgeCost }(
            recipientChain,
            sourceSentinel,
            requestPayload,
            0, // no receiver value needed since we're just passing a message
            gasLimit,
            recipientChain,
            msg.sender // Refund address is of the sender
        );
    }
}
