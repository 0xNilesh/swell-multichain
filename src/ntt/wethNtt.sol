// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Weth is ERC20, Ownable {
    constructor() ERC20("Weth", "weth") Ownable() {}

    /// @notice address of the minter to ensure compatibility with NTT Hub-and-Spoke Method
    address public minter;

    /// @notice Emitted when a new minter is set.
    /// @param newMinter The address of the new minter.
    event NewMinter(address indexed newMinter);

    /// @notice Error when the caller is not the minter.
    /// @dev Selector 0x5fb5729e.
    /// @param caller The caller of the function.
    error CallerNotMinter(address caller);

    /// @notice Error when the minter is the zero address.
    /// @dev Selector 0x04a208c7.
    error InvalidMinterZeroAddress();

    modifier onlyMinter() {
        if (msg.sender != minter) {
            revert CallerNotMinter(msg.sender);
        }
        _;
    }

    /// NOTE: the `setMinter` method is added for INttToken Interface support.
    /// @notice Sets a new minter address, only callable by the contract owner.
    /// @param newMinter The address of the new minter.
    function setMinter(address newMinter) external onlyOwner {
        if (newMinter == address(0)) {
            revert InvalidMinterZeroAddress();
        }
        minter = newMinter;
        emit NewMinter(newMinter);
    }

    /// NOTE: the `mint` method is added for INttToken Interface support.
    /// @notice Mints `_amount` tokens to `account`, only callable by the minter.
    /// @param account The address to receive the minted tokens.
    /// @param amount The amount of tokens to mint.
    function mint(address account, uint256 amount) external onlyMinter {
        _mint(account, amount);
    }
}