// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {TokenFactory} from "../src/TokenFactory.sol";
import {Token} from "../src/TokenFactory.sol";

contract Deploy is Script {
    uint256 privateKey = vm.envUint(string.concat("PRIVATE_KEY_", vm.toString(block.chainid)));
    address deployer = vm.addr(privateKey);

    function run() public {
        vm.startBroadcast(deployer);
        TokenFactory tokenFactory = new TokenFactory();
        Token aUSDC = (tokenFactory.createToken("aUSDC", "aUSDC", 6));
        Token aUSDT = (tokenFactory.createToken("aUSDT", "aUSDT", 18));
        Token aBTC = (tokenFactory.createToken("aBTC", "aBTC", 8));

        aUSDC.mint(deployer, 200000 * 10 ** aUSDC.decimals());
        aUSDT.mint(deployer, 200000 * 10 ** aUSDT.decimals());
        aBTC.mint(deployer, 2 * 10 ** aBTC.decimals());

        vm.stopBroadcast();
    }
}
