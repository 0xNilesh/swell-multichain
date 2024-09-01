// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/wormhole/INttManager.sol";
import "./interfaces/wormhole/IWormholeTransceiver.sol";
import "./interfaces/wormhole/IWormholeRelayer.sol";
import "./libraries/wormhole-lib/TransceiverStructs.sol";

interface ISwEth is IERC20 {
    function deposit(uint256 amount) external;
}

contract SourceSentinel is Ownable {
    // ERC20 token for SWETH
    ISwEth public swEth;

    // Wormhole relayer contract
    address public wormholeRelayer;

    // Wormhole Transceiver and NTT Manager contracts
    IWormholeTransceiver public wormholeTransceiver;
    INttManager public nttManager;

    error CallerNotWormholeRelayer();

    event CrossChainDeposit(address indexed sender, uint256 amount, uint16 targetChain);

    /**
     * @notice Initializes the contract with the swEth ERC20 contract, Wormhole relayer, Transceiver, and NTT Manager
     * @param _swEth The address of the swEth ERC20 contract
     * @param _wormholeRelayer The address of the Wormhole relayer contract
     * @param _wormholeTransceiver The address of the Wormhole Transceiver contract
     * @param _nttManager The address of the NTT Manager contract
     */
    constructor(
        address _swEth,
        address _wormholeRelayer,
        address _wormholeTransceiver,
        address _nttManager
    ) Ownable() {
        swEth = ISwEth(_swEth);
        wormholeRelayer = _wormholeRelayer;
        wormholeTransceiver = IWormholeTransceiver(_wormholeTransceiver);
        nttManager = INttManager(_nttManager);
    }

    /**
     * @notice Restricts access to the Wormhole relayer
     * @dev Reverts if the caller is not the Wormhole relayer
     */
    function onlyWormholeRelayer() private view {
        if (msg.sender != wormholeRelayer) {
            revert CallerNotWormholeRelayer();
        }
    }

    /**
     * @notice Receives and processes cross-chain messages
     * @dev This function handles the received message and performs necessary actions
     * @param payload The payload of the message received from Wormhole
     * @param sourceAddress The source address of the message sender
     * @param sourceChain The ID of the source chain
     * @param deliveryHash The unique hash of the delivery
     */
    function receiveWormholeMessages(
        bytes memory payload,
        bytes[] memory, // additionalVaas
        bytes32 sourceAddress,
        uint16 sourceChain,
        bytes32 deliveryHash
    )
        public
        payable
    {
        onlyWormholeRelayer();

        // Decode the payload to get the amount and sender address
        (uint256 amount, address sender) = abi.decode(payload, (uint256, address));

        // Deposit the amount into SWETH
        swEth.approve(address(swEth), amount);
        swEth.deposit(amount);

        // Emit an event for the cross-chain deposit
        emit CrossChainDeposit(sender, amount, sourceChain);

        // Fetch the cost of bridging tokens
        uint256 tokenBridgeCost = wormholeTransceiver.quoteDeliveryPrice(sourceChain, TransceiverStructs.TransceiverInstruction({ index: 0, payload: abi.encodePacked(false) }));

        // Transfer tokens to NTT Manager
        swEth.approve(address(nttManager), amount);
        nttManager.transfer{value: tokenBridgeCost}(
            amount,
            sourceChain,
            _addressToBytes32(sender),
            _addressToBytes32(sender),
            false,
            new bytes(1)
        );
    }

    /**
     * @notice Sets a new swEth contract address
     * @dev Only the owner can call this function
     * @param _swEth The new address of the swEth ERC20 contract
     */
    function setSwEthAddress(address _swEth) external onlyOwner {
        swEth = ISwEth(_swEth);
    }

    /**
     * @notice Sets a new Wormhole relayer address
     * @dev Only the owner can call this function
     * @param _wormholeRelayer The new address of the Wormhole relayer contract
     */
    function setWormholeRelayerAddress(address _wormholeRelayer) external onlyOwner {
        wormholeRelayer = _wormholeRelayer;
    }

    /**
     * @notice Sets a new Wormhole Transceiver address
     * @dev Only the owner can call this function
     * @param _transceiver The new address of the Wormhole Transceiver contract
     */
    function setWormholeTransceiver(address _transceiver) external onlyOwner {
        wormholeTransceiver = IWormholeTransceiver(_transceiver);
    }

    /**
     * @notice Sets a new NTT Manager address
     * @dev Only the owner can call this function
     * @param _nttManager The new address of the NTT Manager contract
     */
    function setNttManager(address _nttManager) external onlyOwner {
        nttManager = INttManager(_nttManager);
    }

    /**
     * @notice Converts an address to a bytes32 value
     * @dev Performs type casting to convert an address to a bytes32.
     *      First converts the address to a uint160, then to a uint256, and finally to a bytes32.
     * @param _addr The EVM address to be converted to bytes32
     * @return bytes32 The bytes32 representation of the address
     */
    function _addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }
}
