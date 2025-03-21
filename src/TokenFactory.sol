// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Multicall} from "@openzeppelin/contracts/utils/Multicall.sol";

contract TokenFactory is Ownable, Multicall {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(address => EnumerableSet.AddressSet) private userTokens;

    struct TokenInfo {
        string name;
        string symbol;
        address token;
        uint256 totalSupply;
        uint256 decimals;
    }

    constructor() Ownable(msg.sender) {}

    function createToken(string memory name_, string memory symbol_, uint8 decimals_) external returns (Token) {
        Token token = new Token(msg.sender, name_, symbol_, decimals_);
        userTokens[msg.sender].add(address(token));
        return token;
    }

    function removeToken(address token) external {
        userTokens[msg.sender].remove(token);
    }

    function getTokens(address user) external view returns (TokenInfo[] memory) {
        TokenInfo[] memory tokens = new TokenInfo[](userTokens[user].length());
        ERC20 token;
        for (uint256 i = 0; i < userTokens[user].length(); i++) {
            token = ERC20(userTokens[user].at(i));
            tokens[i] = TokenInfo({
                name: token.name(),
                symbol: token.symbol(),
                token: address(token),
                totalSupply: token.totalSupply(),
                decimals: token.decimals()
            });
        }
        return tokens;
    }
}

contract Token is ERC20, Ownable {
    uint8 private immutable _decimals;

    constructor(address owner, string memory name_, string memory symbol_, uint8 decimals_)
        ERC20(name_, symbol_)
        Ownable(owner)
    {
        _decimals = decimals_;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }
}
