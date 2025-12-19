// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Counter} from "../src/Counter.sol";

contract CounterTest is Test {
    Counter public counter;

    // Cette fonction s'exécute avant chaque test.
    function setUp() public {
        counter = new Counter(); // Déploie une nouvelle instance du contrat Counter
        counter.setNumber(0); // Initialise le nombre à 0
    }

    // Test pour vérifier la fonction setNumber
    function test_SetNumber() public {
        uint256 newNumber = 10;
        counter.setNumber(newNumber);
        // assertEq vérifie si les deux valeurs sont égales.
        assertEq(counter.number(), newNumber, "The number should be 10");
    }

    // Test pour vérifier la fonction increment
    function test_Increment() public {
        // L'état initial est 0 grâce à setUp()
        counter.increment();
        assertEq(counter.number(), 1, "The number should be 1 after incrementing");
    }
}