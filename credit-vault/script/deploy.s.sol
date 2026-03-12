// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/CreditVault.sol";

contract DeployScript is Script {
    function run() external {
        vm.startBroadcast();

        CreditVault vault = new CreditVault();

        vm.stopBroadcast();
    }
}