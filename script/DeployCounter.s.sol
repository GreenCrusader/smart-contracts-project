// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {Counter} from "../src/Counter.sol";

contract DeployCounter is Script {
    function run() external returns (Counter) {
        // vm.startBroadcast() indique à Foundry de commencer à envoyer des transactions réelles.
        vm.startBroadcast();

        // Déploie le contrat Counter.
        Counter counter = new Counter();

        // vm.stopBroadcast() arrête l'envoi de transactions.
        vm.stopBroadcast();

        return counter;
    }
}