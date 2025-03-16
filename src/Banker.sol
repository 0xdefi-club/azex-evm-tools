// TODO: update to use assembly
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library Banker {
    using SafeERC20 for IERC20;

    event ReceiveETH(address indexed from, uint256 amount);
    event TransferETH(address indexed to, uint256 amount);
    event ReceiveERC20(address indexed token, address indexed from, uint256 amount);
    event TransferERC20(address indexed token, address indexed to, uint256 amount);

    error InvalidTransferIn(address token, address from, address to, uint256 amount, uint256 value);
    error ZeroAmount();
    error ZeroAddress();
    error InsufficientBalance();
    error TransferFailed();
    error NoTokensTransferred(uint256 amount);

    function _transferETH(address payable _to, uint256 _amount) public {
        if (_amount == 0) revert ZeroAmount();
        if (_to == address(0)) revert ZeroAddress();
        if (address(this).balance < _amount) revert InsufficientBalance();

        (bool success,) = _to.call{value: _amount}("");
        if (!success) revert TransferFailed();

        emit TransferETH(_to, _amount);
    }

    function receiveERC20(address _token, address _from, uint256 _amount) public returns (uint256 actualAmount) {
        if (_amount == 0) revert ZeroAmount();
        if (_token == address(0)) revert ZeroAddress();
        if (_from == address(0)) revert ZeroAddress();

        uint256 balanceBefore = IERC20(_token).balanceOf(address(this));

        IERC20(_token).safeTransferFrom(_from, address(this), _amount);

        uint256 balanceAfter = IERC20(_token).balanceOf(address(this));
        actualAmount = balanceAfter - balanceBefore;

        if (actualAmount == 0) revert NoTokensTransferred(_amount);
        emit ReceiveERC20(_token, _from, actualAmount);
        return actualAmount;
    }

    function _transferERC20(address _token, address _to, uint256 _amount) internal returns (uint256 actualAmount) {
        require(_amount > 0, "Amount must be greater than 0");
        require(_token != address(0), "Invalid token address");
        require(_to != address(0), "Invalid recipient address");

        uint256 balanceBefore = IERC20(_token).balanceOf(address(this));
        require(balanceBefore >= _amount, "Insufficient token balance");

        IERC20(_token).safeTransfer(_to, _amount);

        uint256 balanceAfter = IERC20(_token).balanceOf(address(this));
        actualAmount = balanceBefore - balanceAfter;

        require(actualAmount > 0, "No tokens transferred");

        emit TransferERC20(_token, _to, actualAmount);
        return actualAmount;
    }

    function _safeERC20TransferFrom(address _token, address _from, address _to, uint256 _amount)
        internal
        returns (uint256 actualAmount)
    {
        require(_amount > 0, "Amount must be greater than 0");
        require(_token != address(0), "Invalid token address");
        require(_from != address(0), "Invalid sender address");
        require(_to != address(0), "Invalid recipient address");

        uint256 balanceBefore = IERC20(_token).balanceOf(_to);

        IERC20(_token).safeTransferFrom(_from, _to, _amount);

        uint256 balanceAfter = IERC20(_token).balanceOf(_to);
        actualAmount = balanceAfter - balanceBefore;

        require(actualAmount > 0, "No tokens transferred");
        return actualAmount;
    }

    function transferIn(address _token, address _from, address _to, uint256 _amount) public {
        if (_amount == 0) return;
        if (_to == address(0)) revert ZeroAddress();

        if (isNative(_token)) {
            (bool success,) = payable(_to).call{value: _amount}("");
            if (!success) revert TransferFailed();
            emit ReceiveETH(_from, _amount);
        } else {
            _safeERC20TransferFrom(_token, _from, _to, _amount);
        }
    }

    function transferOut(address _token, address _to, uint256 _amount) public {
        if (_amount == 0) return;
        if (isNative(_token)) _transferETH(payable(_to), _amount);
        else _transferERC20(_token, _to, _amount);
    }

    function balanceOf(address target, address asset) public view returns (uint256 balance) {
        if (isNative(asset)) balance = address(target).balance;
        else balance = IERC20(asset).balanceOf(target);
    }

    function isNative(address token) public pure returns (bool) {
        return token == address(0);
    }
}
