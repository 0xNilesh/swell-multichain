// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./interfaces/wormhole/INttManager.sol";
import "./interfaces/wormhole/IWormholeTransceiver.sol";
import "./interfaces/wormhole/IWormholeRelayer.sol";
import "./libraries/wormhole-lib/TransceiverStructs.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LayerTransmitter is Ownable {
    IERC20 public WETH_NTT;
    INttManager public NTT_MANAGER;
    IWormholeTransceiver public WORMHOLE_TRANSCEIVER;
    IWormholeRelayer public WORMHOLE_RELAYER;
    uint16 public WORMHOLE_RECIPIENT_CHAIN;
    address public sourceSentinel;

    address public pushChannelAdmin;

    /**
     * @notice Initializes the contract by setting the source sentinel address
     * @dev Sets the `sourceSentinel` and initializes `Ownable`
     * @param _sourceSentinel The address of the SourceSentinel contract on the source chain
     */
    constructor(address _sourceSentinel) Ownable() {
        sourceSentinel = _sourceSentinel;
    }

    /**
     * @notice Sets the bridge configuration parameters
     * @dev This function can only be called by the owner
     * @param _wethNTT The address of the WETH_NTT ERC20 token contract
     * @param _nttManager The address of the NTT manager contract
     * @param _wormholeTransceiver The address of the Wormhole transceiver contract
     * @param _wormholeRelayerAddress The address of the Wormhole relayer contract
     * @param _recipientChain The ID of the recipient chain in the Wormhole network
     */
    function setBridgeConfig(
        address _wethNTT,
        address _nttManager,
        IWormholeTransceiver _wormholeTransceiver,
        IWormholeRelayer _wormholeRelayerAddress,
        uint16 _recipientChain
    ) external onlyOwner {
        WETH_NTT = IERC20(_wethNTT);
        NTT_MANAGER = INttManager(_nttManager);
        WORMHOLE_TRANSCEIVER = IWormholeTransceiver(_wormholeTransceiver);
        WORMHOLE_RELAYER = IWormholeRelayer(_wormholeRelayerAddress);
        WORMHOLE_RECIPIENT_CHAIN = _recipientChain;
    }

    /**
     * @notice Deposits tokens and initiates a cross-chain transfer and message relay
     * @dev Transfers WETH_NTT tokens to the contract, quotes the costs for bridging and relaying,
     *      and initiates the cross-chain transfer via Wormhole
     * @param amount The amount of WETH_NTT tokens to be transferred
     * @param gasLimit The gas limit for the message relay on the recipient chain
     */
    function deposit(uint256 amount, uint256 gasLimit) external {
        // Transfer WETH_NTT tokens from the sender to this contract
        require(
            WETH_NTT.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );

        uint16 recipientChain = WORMHOLE_RECIPIENT_CHAIN;

        uint256 messageBridgeCost = quoteMsgRelayCost(recipientChain, gasLimit);
        uint256 tokenBridgeCost = quoteTokenBridgingCost();

        INttManager NttManager = NTT_MANAGER;

        WETH_NTT.approve(address(NttManager), amount);
        NttManager.transfer{value: tokenBridgeCost}(
            amount,
            recipientChain,
            addressToBytes32(sourceSentinel),
            addressToBytes32(msg.sender),
            false,
            new bytes(1)
        );

        // Encode amount and msg.sender into the requestPayload
        bytes memory requestPayload = abi.encode(amount, msg.sender);

        // Relay the RequestData Payload
        WORMHOLE_RELAYER.sendPayloadToEvm{value: messageBridgeCost}(
            recipientChain,
            sourceSentinel,
            requestPayload,
            0, // no receiver value needed since we're just passing a message
            gasLimit,
            recipientChain,
            msg.sender // Refund address is of the sender
        );
    }

    /**
     * @notice Quotes the cost of bridging tokens to the recipient chain
     * @dev Calls the Wormhole Transceiver to get the delivery price
     * @return cost The cost of bridging tokens
     */
    function quoteTokenBridgingCost() public view returns (uint256 cost) {
        TransceiverStructs.TransceiverInstruction
            memory transceiverInstruction = TransceiverStructs
                .TransceiverInstruction({
                    index: 0,
                    payload: abi.encodePacked(false)
                });
        cost = WORMHOLE_TRANSCEIVER.quoteDeliveryPrice(
            WORMHOLE_RECIPIENT_CHAIN,
            transceiverInstruction
        );
    }

    /**
     * @notice Quotes the cost of relaying a message to the target chain with the specified gas limit
     * @dev Calls the Wormhole Relayer to get the EVM delivery price
     * @param targetChain The chain to which the message is being relayed
     * @param gasLimit The gas limit for the message relay
     * @return cost The cost of relaying the message
     */
    function quoteMsgRelayCost(
        uint16 targetChain,
        uint256 gasLimit
    ) public view returns (uint256 cost) {
        (cost, ) = WORMHOLE_RELAYER.quoteEVMDeliveryPrice(
            targetChain,
            0,
            gasLimit
        );
    }

    /**
     * @notice Converts an address to a bytes32 value
     * @dev Performs type casting to convert an address to a bytes32.
     *      First converts the address to a uint160, then to a uint256, and finally to a bytes32.
     * @param _addr The EVM address to be converted to bytes32
     * @return bytes32 The bytes32 representation of the address
     */
    function addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }
}
