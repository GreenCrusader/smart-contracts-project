// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/VestingWallet.sol";
import "../src/MockERC20.sol";

contract DeployVestingWallet is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // Déployer le MockERC20
        MockERC20 mockToken = new MockERC20("Mock Vesting Token", "MVT");
        console.log("MockERC20 deployed at:", address(mockToken));

        // Déployer le VestingWallet avec le MockERC20
        VestingWallet vestingWallet = new VestingWallet(address(mockToken));
        console.log("VestingWallet deployed at:", address(vestingWallet));

        // Minter des tokens pour le déployeur
        mockToken.mint(msg.sender, 10000 ether);
        console.log("Minted 10000 MVT to:", msg.sender);

        // Approuver le contrat VestingWallet
        mockToken.approve(address(vestingWallet), type(uint256).max);
        console.log("VestingWallet approved to spend tokens");

        vm.stopBroadcast();

        console.log("\n=== Déploiement Réussi ===");
        console.log("MockERC20 Address:", address(mockToken));
        console.log("VestingWallet Address:", address(vestingWallet));
    }
}
