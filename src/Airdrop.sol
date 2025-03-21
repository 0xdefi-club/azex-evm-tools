// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Banker} from "./lib/Banker.sol";

contract AirDropper is Ownable {
    error InvalidArrayLength();
    error EmptyArray();

    constructor() Ownable(msg.sender) {}

    function airdrop(IERC20 _token, address[] calldata _recipients, uint256[] calldata _amounts, uint256 _total)
        external
    {
        uint256 length = _recipients.length;
        if (length == 0) revert EmptyArray();
        if (length != _amounts.length) revert InvalidArrayLength();

        // bytes selector for transferFrom(address,address,uint256)
        bytes4 transferFrom = 0x23b872dd;
        // bytes selector for transfer(address,uint256)
        bytes4 transfer = 0xa9059cbb;

        assembly {
            // store transferFrom selector
            let transferFromData := add(0x20, mload(0x40))
            mstore(transferFromData, transferFrom)
            // store caller address
            mstore(add(transferFromData, 0x04), caller())
            // store address
            mstore(add(transferFromData, 0x24), address())
            // store _total
            mstore(add(transferFromData, 0x44), _total)
            // call transferFrom for _total
            let successTransferFrom := call(gas(), _token, 0, transferFromData, 0x64, 0, 0)
            // revert if call fails
            if iszero(successTransferFrom) { revert(0, 0) }

            // store transfer selector
            let transferData := add(0x20, mload(0x40))
            mstore(transferData, transfer)

            // store length of _recipients
            let sz := _amounts.length

            // loop through _recipients
            for { let i := 0 } lt(i, sz) {
                // increment i
                i := add(i, 1)
            } {
                // store offset for _amounts[i]
                let offset := mul(i, 0x20)
                // store _amounts[i]
                let amt := calldataload(add(_amounts.offset, offset))
                // store _recipients[i]
                let recp := calldataload(add(_recipients.offset, offset))
                // store _recipients[i] in transferData
                mstore(add(transferData, 0x04), recp)
                // store _amounts[i] in transferData
                mstore(add(transferData, 0x24), amt)
                // call transfer for _amounts[i] to _recipients[i]
                let successTransfer := call(gas(), _token, 0, transferData, 0x44, 0, 0)
                // revert if call fails

                if iszero(successTransfer) { revert(0, 0) }
            }
        }
    }

    function batchTransferETH(address[] calldata _recipients, uint256[] calldata _amounts) external payable {
        // 基础检查
        uint256 length = _recipients.length;
        if (length == 0) revert EmptyArray();
        if (length != _amounts.length) revert InvalidArrayLength();

        assembly {
            let totalAmount := 0

            for { let i := 0 } lt(i, length) { i := add(i, 1) } {
                let amount := calldataload(add(_amounts.offset, mul(i, 0x20)))
                totalAmount := add(totalAmount, amount)
            }

            if lt(callvalue(), totalAmount) {
                mstore(0x00, 0xf4d678b8) // InsufficientBalance selector
                revert(0x00, 0x04)
            }

            for { let i := 0 } lt(i, length) { i := add(i, 1) } {
                let recipient := calldataload(add(_recipients.offset, mul(i, 0x20)))
                let amount := calldataload(add(_amounts.offset, mul(i, 0x20)))

                if iszero(recipient) {
                    mstore(0x00, 0x90b8ec18) // TransferFailed selector
                    revert(0x00, 0x04)
                }

                let success :=
                    call(
                        gas(), // gas
                        recipient, // to
                        amount, // value
                        0, // in data offset
                        0, // in data size
                        0, // out data offset
                        0 // out data size
                    )

                if iszero(success) {
                    mstore(0x00, 0x90b8ec18) // TransferFailed selector
                    revert(0x00, 0x04)
                }
            }
        }
    }

    receive() external payable {}

    function withdraw(address token, address receiver, uint256 amount) public onlyOwner {
        Banker.transferOut(token, receiver, amount);
    }
}
