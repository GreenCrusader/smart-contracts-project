// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/VestingWallet.sol";
import "../src/MockERC20.sol";

contract VestingWalletTest is Test {
    VestingWallet public vestingWallet;
    MockERC20 public mockToken;
    address public owner;
    address public beneficiary1;
    address public beneficiary2;

    function setUp() public {
        owner = address(this);
        beneficiary1 = address(0x123);
        beneficiary2 = address(0x456);

        // Déployer le MockERC20
        mockToken = new MockERC20("Mock Token", "MOCK");
        
        // Déployer le VestingWallet avec le MockERC20
        vestingWallet = new VestingWallet(address(mockToken));

        // Minter des tokens pour l'owner
        mockToken.mint(owner, 1000 ether);
        
        // Approuver le contrat VestingWallet
        mockToken.approve(address(vestingWallet), 10000 ether);
    }

    // Test 1 : Vérifier que la création d'un calendrier de vesting fonctionne correctement
    function testCreateVestingSchedule() public {
        uint256 totalAmount = 100 ether;
        uint256 cliff = block.timestamp + 1 days;
        uint256 duration = 365 days;

        vestingWallet.createVestingSchedule(beneficiary1, totalAmount, cliff, duration);

        (
            address beneficiary,
            uint256 storedCliff,
            uint256 storedDuration,
            uint256 storedTotal,
            uint256 releasedAmount
        ) = vestingWallet.vestingSchedules(beneficiary1);

        assertEq(beneficiary, beneficiary1);
        assertEq(storedCliff, cliff);
        assertEq(storedDuration, duration);
        assertEq(storedTotal, totalAmount);
        assertEq(releasedAmount, 0);
        assertEq(mockToken.balanceOf(address(vestingWallet)), totalAmount);
    }

    // Test 2 : Tenter de réclamer des jetons avant la date de cliff (devrait échouer)
    function testClaimBeforeCliff() public {
        uint256 totalAmount = 100 ether;
        uint256 cliff = block.timestamp + 30 days;
        uint256 duration = 365 days;

        vestingWallet.createVestingSchedule(beneficiary1, totalAmount, cliff, duration);

        vm.prank(beneficiary1);
        vm.expectRevert("Nothing to claim");
        vestingWallet.claimVestedTokens();
    }

    // Test 3 : Réclamer des jetons pendant la période de vesting (devrait transférer une partie)
    function testClaimDuringVesting() public {
        uint256 totalAmount = 100 ether;
        uint256 cliff = block.timestamp;
        uint256 duration = 365 days;

        vestingWallet.createVestingSchedule(beneficiary1, totalAmount, cliff, duration);

        // Avancer le temps de 182.5 jours (mi-chemin)
        vm.warp(block.timestamp + 182.5 days);

        uint256 vestedAmount = vestingWallet.getVestedAmount(beneficiary1);
        assertGe(vestedAmount, 49 ether); // ~50 ether
        assertLe(vestedAmount, 51 ether);

        vm.prank(beneficiary1);
        vestingWallet.claimVestedTokens();

        assertEq(mockToken.balanceOf(beneficiary1), vestedAmount);
    }

    // Test 4 : Réclamer tous les jetons après la fin de la période de vesting
    function testClaimAfterVesting() public {
        uint256 totalAmount = 100 ether;
        uint256 cliff = block.timestamp;
        uint256 duration = 365 days;

        vestingWallet.createVestingSchedule(beneficiary1, totalAmount, cliff, duration);

        // Avancer le temps au-delà de la durée
        vm.warp(block.timestamp + 366 days);

        uint256 vestedAmount = vestingWallet.getVestedAmount(beneficiary1);
        assertEq(vestedAmount, totalAmount);

        vm.prank(beneficiary1);
        vestingWallet.claimVestedTokens();

        assertEq(mockToken.balanceOf(beneficiary1), totalAmount);
        assertEq(mockToken.balanceOf(address(vestingWallet)), 0);
    }

    // Test 5 : Vérifier que plusieurs appels de claim ne dépassent pas le total
    function testMultipleClaims() public {
        uint256 totalAmount = 100 ether;
        uint256 cliff = block.timestamp;
        uint256 duration = 365 days;

        vestingWallet.createVestingSchedule(beneficiary1, totalAmount, cliff, duration);

        // Premier claim après 100 jours
        vm.warp(block.timestamp + 100 days);
        vm.prank(beneficiary1);
        vestingWallet.claimVestedTokens();

        // Deuxième claim après 200 jours au total
        vm.warp(block.timestamp + 100 days);
        vm.prank(beneficiary1);
        vestingWallet.claimVestedTokens();
        uint256 claimed2 = mockToken.balanceOf(beneficiary1);

        assertEq(claimed2, totalAmount * 200 / 365);
    }

    // Test 6 : Vérifier la sécurité contre les attaques de réentrance
    function testReentrancyProtection() public {
        uint256 totalAmount = 100 ether;
        uint256 cliff = block.timestamp;
        uint256 duration = 365 days;

        vestingWallet.createVestingSchedule(beneficiary1, totalAmount, cliff, duration);

        vm.warp(block.timestamp + 366 days);

        vm.prank(beneficiary1);
        vestingWallet.claimVestedTokens();
        assertEq(mockToken.balanceOf(beneficiary1), totalAmount);
    }

    // Test 7 : Seul l'owner peut créer un vesting
    function testOnlyOwnerCanCreate() public {
        uint256 totalAmount = 100 ether;
        uint256 cliff = block.timestamp + 1 days;
        uint256 duration = 365 days;

        vm.prank(beneficiary1);
        vm.expectRevert();
        vestingWallet.createVestingSchedule(beneficiary2, totalAmount, cliff, duration);
    }

    // Test 8 : Vérifier que les bénéficiaires différents ont des vestings indépendants
    function testMultipleBeneficiaries() public {
        uint256 totalAmount = 100 ether;
        uint256 cliff = block.timestamp;
        uint256 duration = 365 days;

        vestingWallet.createVestingSchedule(beneficiary1, totalAmount, cliff, duration);
        vestingWallet.createVestingSchedule(beneficiary2, totalAmount, cliff, duration);

        vm.warp(block.timestamp + 366 days);

        vm.prank(beneficiary1);
        vestingWallet.claimVestedTokens();

        vm.prank(beneficiary2);
        vestingWallet.claimVestedTokens();

        assertEq(mockToken.balanceOf(beneficiary1), totalAmount);
        assertEq(mockToken.balanceOf(beneficiary2), totalAmount);
    }
}
