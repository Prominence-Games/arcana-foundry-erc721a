// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "../src/ArcanaPrime.sol";
import "./helpers/Merkle.sol";

contract ArcanaPrimeTests is Test {
    using stdStorage for StdStorage;

    ArcanaPrime private nft;
    bytes32 private root;
    bytes32[] private proof;
    bytes32[] private lies;
    uint256 internal founderPrivateKey;
    address internal founder;
    string private notRevealedUri = "https://arcanahq.com/";
    string private baseTokenURI = "https://base.com/";
    address internal blacklistContractAddress = 0xFED24eC7E22f573c2e08AEF55aA6797Ca2b3A051;

    function setUp() public {
        nft = new ArcanaPrime(notRevealedUri);
        testPassSetupMerkle();
        founderPrivateKey = 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a;
        founder = vm.addr(founderPrivateKey);
        vm.deal(founder, 1000 ether);
    }

    function testPassSetupMerkle() public {
        Merkle m = new Merkle();
        bytes32[] memory data = new bytes32[](5);
        data[0] = keccak256(abi.encodePacked(address(0x101)));
        data[1] = keccak256(abi.encodePacked(address(this)));
        data[2] = keccak256(abi.encodePacked(address(0x103)));
        data[3] = keccak256(abi.encodePacked(address(0x104)));
        data[4] = keccak256(abi.encodePacked(address(0x105)));
        root = m.getRoot(data);
        proof = m.getProof(data, 1);
        lies = m.getProof(data, 2);
        bool verified = m.verifyProof(root, proof, data[1]);
        assertTrue(verified);
    }

    function testPassSetup() public {
        assertEq(nft.notRevealedUri(), "https://arcanahq.com/");
        assertEq(nft.name(), "ARCANA");
        assertEq(nft.symbol(), "ARC");
        assertEq(nft.MAX_SUPPLY(), 10000);
        assertEq(nft.mintSupply(), 5888);
        assertEq(nft.MINT_PRICE(), 100000000000000000);
        assertEq(nft.currentPhase(), 0);
        assertEq(nft.nextStartTime(), 0);
        assertEq(nft.isTransfused(), false);
        assertEq(nft.paused(), true);
        assertEq(nft.aspirantListMerkleRoot(), 0);
        assertEq(nft.arcanaListMerkleRoot(), 0);
        assertEq(nft.allianceListMerkleRoot(), 0);
        assertEq(nft.operatorFilteringEnabled(), true);
         ( , uint256 royaltyAmount) = nft.royaltyInfo(1, 1000);
        assertEq(royaltyAmount, 50);
    }

    function testPassCommunityWarChestMint() public {
        uint256 unlockTs =  block.timestamp + 10000;
        nft.mintWarChestReserve(address(1), 1088, unlockTs);
        assertEq(nft.totalSupply(), 1088);
        assertEq(nft.nextUnlockTs(), unlockTs);
    }

    function testPassRevertCommunityWarChestMint() public {
        testPassCommunityWarChestMint();
        uint256 newUnlockTs =  block.timestamp + 100000;
        vm.expectRevert(TreasuryNotUnlocked.selector);
        nft.mintWarChestReserve(address(1), 100, newUnlockTs);
    }

    function testPassCommunityWarChestMintLater() public {
        testPassCommunityWarChestMint();
        vm.warp(10000 + block.timestamp);
        uint256 newUnlockTs =  block.timestamp + 100000;
        nft.mintWarChestReserve(address(1), 100, newUnlockTs);
        assertEq(nft.totalSupply(), 1188);
    }

    //PRE-MINT CONFIGURATIONS
    function testPassSetNotRevealedUri() public {
        nft.setNotRevealedBaseURI("https://test.com/");
        assertEq(nft.notRevealedUri(), "https://test.com/");
    }

    function testPassSetArcanaListRoot() public {
        nft.setArcanaListMerkleRoot(root);
        assertEq(nft.arcanaListMerkleRoot(), root);
    }

    function testPassSetAspirantRoot() public {
        nft.setAspirantListMerkleRoot(root);
        assertEq(nft.aspirantListMerkleRoot(), root);
    }

    function testPassSetAllianceRoot() public {
        nft.setAllianceListMerkleRoot(root);
        assertEq(nft.allianceListMerkleRoot(), root);
    }

    function testPassSetBaseTokenUri() public {
        nft.setBaseTokenURI(baseTokenURI);
        assertEq(nft.baseTokenURI(), baseTokenURI);
    }

    function testPassSetPauseTrue() public {
        nft.togglePause(true);
        assertEq(nft.paused(), true);
    }

    function testPassSetPauseFalse() public {
        nft.togglePause(false);
        assertEq(nft.paused(), false);
    }

    function testPassSetNextStartTime() public {
        uint256 currentTime = block.timestamp + 100000;
        nft.setNextStartTime(currentTime);
        assertEq(currentTime, nft.nextStartTime());
    }

    function testPassSetCurrentMintPhase() public {
        nft.setCurrentPhase(1);
        assertEq(nft.currentPhase(), 1);
    }

    //ARCANA LIST MINT
    //HAPPY CASES
    function testPassArcanaListMint() public {
        nft.setCurrentPhase(1);
        nft.togglePause(false);
        nft.setArcanaListMerkleRoot(root);
        nft.mintArcanaList{value: 0.1 ether}(proof, 1);
        assertEq(nft.balanceOf(address(this)), 1);
    }
    //FAILURE CASES

    function testPassArcanaListMintWhenWrongCurrentPhase() public {
        nft.setCurrentPhase(2);
        nft.togglePause(false);
        nft.setArcanaListMerkleRoot(root);
        vm.expectRevert(MintIsNotOpen.selector);
        nft.mintArcanaList{value: 0.1 ether}(proof, 1);
    }

    function testPassArcanaListMintContractNotPaused() public {
        nft.setCurrentPhase(1);
        nft.togglePause(true);
        nft.setArcanaListMerkleRoot(root);
        vm.expectRevert(ContractIsPaused.selector);
        nft.mintArcanaList{value: 0.1 ether}(proof, 1);
    }

    function testPassArcanaListMintMoreThanTwo() public {
        nft.setCurrentPhase(1);
        nft.togglePause(false);
        nft.setArcanaListMerkleRoot(root);
        vm.expectRevert(MaxEntitlementsExceeded.selector);
        nft.mintArcanaList{value: 0.3 ether}(proof, 3);
    }

    function testPassArcanaListMintRandomAssPoorPerson() public {
        nft.setCurrentPhase(1);
        nft.togglePause(false);
        nft.setArcanaListMerkleRoot(root);
        vm.expectRevert(PriceIncorrect.selector);
        nft.mintArcanaList{value: 0.01 ether}(proof, 1);
    }

    function testPassArcanaListMintMoreThanMaxSupply() public {
        nft.setCurrentPhase(1);
        nft.togglePause(false);
        nft.setArcanaListMerkleRoot(root);
        vm.expectRevert(MintSupplyExceeded.selector);
        nft.mintArcanaList{value: 801 ether}(proof, 10001);
    }

    function testPassArcanaListMintAnon() public {
        nft.setCurrentPhase(1);
        nft.togglePause(false);
        nft.setArcanaListMerkleRoot(root);
        vm.expectRevert(MerkleProofInvalid.selector);
        nft.mintArcanaList{value: 0.1 ether}(lies, 1);
    }

    //ASPIRANT LIST MINT
    //HAPPY CASES
    function testPassAspirantListMint() public {
        nft.setCurrentPhase(2);
        nft.togglePause(false);
        nft.setAspirantListMerkleRoot(root);
        nft.mintAspirantList{value: 0.2 ether}(proof, 2);
        assertEq(nft.getTotalMints(address(this)), 2);
    }

    //FAILURE CASES
    function testPassAspirantListMintWhenWrongCurrentPhase() public {
        nft.setCurrentPhase(3);
        nft.togglePause(false);
        nft.setAspirantListMerkleRoot(root);
        vm.expectRevert(MintIsNotOpen.selector);
        nft.mintAspirantList{value: 0.2 ether}(proof, 2);
    }

    function testPassAspirantListMintContractNotPaused() public {
        nft.setCurrentPhase(2);
        nft.togglePause(true);
        nft.setAspirantListMerkleRoot(root);
        vm.expectRevert(ContractIsPaused.selector);
        nft.mintAspirantList{value: 0.2 ether}(proof, 2);
    }

    function testPassAspirantListMintMoreThanThree() public {
        nft.setCurrentPhase(2);
        nft.togglePause(false);
        nft.setAspirantListMerkleRoot(root);
        vm.expectRevert(MaxQuantityAllowedExceeded.selector);
        nft.mintAspirantList{value: 0.5 ether}(proof, 5);
    }

    function testPassAspirantListMintRandomAssPoorPerson() public {
        nft.setCurrentPhase(2);
        nft.togglePause(false);
        nft.setAspirantListMerkleRoot(root);
        vm.expectRevert(PriceIncorrect.selector);
        nft.mintAspirantList{value: 0.2 ether}(proof, 3);
    }

    function testPassAspirantListMintMoreThanMaxSupply() public {
        nft.setCurrentPhase(2);
        nft.togglePause(false);
        nft.setAspirantListMerkleRoot(root);
        vm.expectRevert(MintSupplyExceeded.selector);
        nft.mintAspirantList{value: 801 ether}(proof, 10001);
    }

    function testPassAspirantListMintAnon() public {
        nft.setCurrentPhase(2);
        nft.togglePause(false);
        nft.setAspirantListMerkleRoot(root);
        vm.expectRevert(MerkleProofInvalid.selector);
        nft.mintAspirantList{value: 0.2 ether}(lies, 2);
    }

    //ALLIANCE LIST MINT
    //HAPPY CASES
    function testPassAllianceListMint() public {
        nft.setCurrentPhase(3);
        nft.togglePause(false);
        nft.setAllianceListMerkleRoot(root);
        nft.mintAllianceList{value: 0.2 ether}(proof, 2);
        assertEq(nft.balanceOf(address(this)), 2);
    }
    //FAILURE CASES

    function testPassAllianceListMintWhenWrongCurrentPhase() public {
        nft.setCurrentPhase(4);
        nft.togglePause(false);
        nft.setAllianceListMerkleRoot(root);
        vm.expectRevert(MintIsNotOpen.selector);
        nft.mintAllianceList{value: 0.2 ether}(proof, 2);
    }


    function testPassOverMintInAlliancePhaseAfterAspirantMint() public {
        testPassAspirantListMint();
        nft.setCurrentPhase(3);
        nft.togglePause(false);
        nft.setAllianceListMerkleRoot(root);
        vm.expectRevert(MaxQuantityAllowedExceeded.selector);
        nft.mintAllianceList{value: 0.3 ether}(proof, 3);
    }

    function testPassAllianceListMintContractNotPaused() public {
        nft.setCurrentPhase(3);
        nft.togglePause(true);
        nft.setAllianceListMerkleRoot(root);
        vm.expectRevert(ContractIsPaused.selector);
        nft.mintAllianceList{value: 0.2 ether}(proof, 2);
    }

    function testPassAllianceListMintMoreThanThree() public {
        nft.setCurrentPhase(3);
        nft.togglePause(false);
        nft.setAllianceListMerkleRoot(root);
        vm.expectRevert(MaxQuantityAllowedExceeded.selector);
        nft.mintAllianceList{value: 0.5 ether}(proof, 5);
    }

    function testPassAllianceListMintRandomAssPoorPerson() public {
        nft.setCurrentPhase(3);
        nft.togglePause(false);
        nft.setAllianceListMerkleRoot(root);
        vm.expectRevert(PriceIncorrect.selector);
        nft.mintAllianceList{value: 0.2 ether}(proof, 3);
    }

    function testPassAllianceListMintMoreThanMaxSupply() public {
        nft.setCurrentPhase(3);
        nft.togglePause(false);
        nft.setAllianceListMerkleRoot(root);
        vm.expectRevert(MintSupplyExceeded.selector);
        nft.mintAllianceList{value: 801 ether}(proof, 10001);
    }

    function testPassAllianceListMintAnon() public {
        nft.setCurrentPhase(3);
        nft.togglePause(false);
        nft.setAllianceListMerkleRoot(root);
        vm.expectRevert(MerkleProofInvalid.selector);
        nft.mintAllianceList{value: 0.2 ether}(lies, 2);
    }

    //PUBLIC MINT
    //HAPPY CASES
    function testPassMintPublic() public {
        nft.setCurrentPhase(4);
        nft.togglePause(false);
        bytes32 nonce = 0x7465737400000000000000000000000000000000000000000000000000000000;
        uint256 quantity = 2;
        bytes32 hash = keccak256(abi.encodePacked(founder, quantity, nonce));
        bytes32 message = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(founderPrivateKey, message);
        vm.prank(founder, founder);
        nft.mintPublic{value: 0.2 ether}(quantity, nonce, hash, v, r, s);
        uint256 totalMintedForWallet = nft.getTotalMints(founder);
        assertEq(quantity, totalMintedForWallet);
    }
    //FAILURE CASES
    //Reverts on Public Mint Closed

    function testPassMintPublicClosed() public {
        nft.setCurrentPhase(3);
        nft.togglePause(false);
        bytes32 nonce = 0x7465737400000000000000000000000000000000000000000000000000000000;
        uint256 quantity = 2;
        bytes32 hash = keccak256(abi.encodePacked(founder, quantity, nonce));
        bytes32 message = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(founderPrivateKey, message);
        vm.expectRevert(MintIsNotOpen.selector);
        vm.prank(founder, founder);
        nft.mintPublic{value: 0.2 ether}(quantity, nonce, hash, v, r, s);
    }

    //Reverts on Contract Paused
    function testPassMintPublicPaused() public {
        nft.setCurrentPhase(4);
        nft.togglePause(true);
        bytes32 nonce = 0x7465737400000000000000000000000000000000000000000000000000000000;
        uint256 quantity = 2;
        bytes32 hash = keccak256(abi.encodePacked(founder, quantity, nonce));
        bytes32 message = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(founderPrivateKey, message);
        vm.expectRevert(ContractIsPaused.selector);
        vm.prank(founder, founder);
        nft.mintPublic{value: 0.2 ether}(quantity, nonce, hash, v, r, s);
    }
    //Reverts on Max Quantity Exceeded

    function testPassMintPublicMaxQtyExceeded() public {
        nft.setCurrentPhase(4);
        nft.togglePause(false);
        bytes32 nonce = 0x7465737400000000000000000000000000000000000000000000000000000000;
        uint256 quantity = 5;
        bytes32 hash = keccak256(abi.encodePacked(founder, quantity, nonce));
        bytes32 message = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(founderPrivateKey, message);
        vm.expectRevert(MaxQuantityAllowedExceeded.selector);
        vm.prank(founder, founder);
        nft.mintPublic{value: 0.5 ether}(quantity, nonce, hash, v, r, s);
    }
    //Reverts on Max Supply Exceeded

    function testPassMintPublicMaxSupplyExceeded() public {
        nft.setCurrentPhase(4);
        nft.togglePause(false);
        bytes32 nonce = 0x7465737400000000000000000000000000000000000000000000000000000000;
        uint256 quantity = 10001;
        bytes32 hash = keccak256(abi.encodePacked(founder, quantity, nonce));
        bytes32 message = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(founderPrivateKey, message);
        vm.expectRevert(MintSupplyExceeded.selector);
        vm.prank(founder, founder);
        nft.mintPublic{value: 801 ether}(quantity, nonce, hash, v, r, s);
    }
    //Reverts on under paid

    function testPassMintPublicPriceIncorrect() public {
        nft.setCurrentPhase(4);
        nft.togglePause(false);
        bytes32 nonce = 0x7465737400000000000000000000000000000000000000000000000000000000;
        uint256 quantity = 3;
        bytes32 hash = keccak256(abi.encodePacked(founder, quantity, nonce));
        bytes32 message = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(founderPrivateKey, message);
        vm.expectRevert(PriceIncorrect.selector);
        vm.prank(founder, founder);
        nft.mintPublic{value: 0.2 ether}(quantity, nonce, hash, v, r, s);
    }
    //Reverts on Contract Mint

    function testPassMintPublicUsingContractToMint() public {
        nft.setCurrentPhase(4);
        founder = address(this);
        nft.togglePause(false);
        bytes32 nonce = 0x7465737400000000000000000000000000000000000000000000000000000000;
        uint256 quantity = 3;
        bytes32 hash = keccak256(abi.encodePacked(founder, quantity, nonce));
        bytes32 message = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(founderPrivateKey, message);
        vm.expectRevert(ContractsNotAllowed.selector);
        nft.mintPublic{value: 0.2 ether}(quantity, nonce, hash, v, r, s);
    }
    //Reverts on Nonce Consumed

    function testPassMintPublicReuseNonce() public {
        nft.setCurrentPhase(4);
        nft.togglePause(false);
        bytes32 nonce = 0x7465737400000000000000000000000000000000000000000000000000000000;
        uint256 quantity = 2;
        bytes32 hash = keccak256(abi.encodePacked(founder, quantity, nonce));
        bytes32 message = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(founderPrivateKey, message);
        vm.prank(founder, founder);
        nft.mintPublic{value: 0.2 ether}(quantity, nonce, hash, v, r, s);
        vm.expectRevert(NonceConsumed.selector);
        vm.prank(founder, founder);
        nft.mintPublic{value: 0.2 ether}(quantity, nonce, hash, v, r, s);
    }
    //Reverts on Hash Mismatched

    function testPassMintPublicHashMismatched() public {
        nft.setCurrentPhase(4);
        nft.togglePause(false);
        bytes32 nonce = 0x7465737400000000000000000000000000000000000000000000000000000000;
        uint256 quantity = 2;
        bytes32 hash = keccak256(abi.encodePacked(founder, quantity, nonce));
        bytes32 message = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(founderPrivateKey, message);
        vm.prank(founder, founder);
        vm.expectRevert(HashMismatched.selector);
        nft.mintPublic{value: 0.2 ether}(1, nonce, hash, v, r, s);
    }
    //Reverts on Hash Mismatched

    function testPassMintPublicSignedHashMismatched() public {
        nft.setCurrentPhase(4);
        nft.togglePause(false);
        bytes32 nonce = 0x7465737400000000000000000000000000000000000000000000000000000000;
        uint256 quantity = 2;
        bytes32 hash = keccak256(abi.encodePacked(founder, quantity, nonce));
        bytes32 message = keccak256(abi.encodePacked("\x1Ethereum Signed Message:\n32", hash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(founderPrivateKey, message);
        vm.prank(founder, founder);
        vm.expectRevert(SignedHashMismatched.selector);
        nft.mintPublic{value: 0.2 ether}(quantity, nonce, hash, v, r, s);
    }

    //POST-MINT
    //SUCCESS
    //Retrieve notRevealedUri when isRevealed false
    function testPassNotRevealedGetTokenUri() public {
        testPassArcanaListMint();
        string memory tokenUri = nft.tokenURI(0);
        assertEq(tokenUri, notRevealedUri);
    }

    function testWithdrawETH() public {
        nft.setCurrentPhase(1);
        nft.togglePause(false);
        nft.setArcanaListMerkleRoot(root);
        
        uint256 contractBalanceBefore = address(nft).balance;
        nft.mintArcanaList{value: 0.1 ether}(proof, 1);
        uint256 contractBalanceAfter = address(nft).balance;
        assertEq(contractBalanceAfter - contractBalanceBefore, 0.1 ether);

        uint256 expectedWithdrawnAmount = contractBalanceAfter;
        uint256 ownerBalanceBefore = address(this).balance;
        nft.withdrawETH();
        assertEq(address(nft).balance, 0 ether);
        uint256 ownerBalanceAfter = address(this).balance;
        assertEq(ownerBalanceAfter - ownerBalanceBefore, expectedWithdrawnAmount);
    }

    //PRE-REVEAL
    //SUCCESS
    //Commit DNA Sequence Success
    function testPassCommitDNASequenceSuccessful() public {
        string memory dna = "3245678";
        nft.commitDNASequence(dna);
        assertEq(nft.dna(), dna);
    }

    //Revert when dna sequence has already been committed
    function testPassCommitDNASequenceFailed() public {
        testPassCommitDNASequenceSuccessful();
        string memory dna = "3245678";
        vm.expectRevert(DNASequenceHaveBeenInitialised.selector);
        nft.commitDNASequence(dna);
    }

    //Transfusion successful
    function testPassTransfusionSuccessful() public {
        testPassCommitDNASequenceSuccessful();
        vm.roll(block.number + 6);
        nft.transfuse();
        assertEq(nft.isTransfused(), true);
    }

    //FAILURE
    //Revert when transfused already completed
    function testPassTransfusionCompleted() public {
        testPassTransfusionSuccessful();
        vm.expectRevert(TransfusionSequenceCompleted.selector);
        nft.transfuse();
    }

    //Revert when scheduledTransfusionTime is not met
    function testPassNotReadyForTransfusion() public {
        testPassCommitDNASequenceSuccessful();
        vm.expectRevert(NotReadyForTranfusion.selector);
        nft.transfuse();
    }

    //Revert when DNA Sequence Not Submitted
    function testPassDNASequenceNotSubmitted() public {
        vm.expectRevert(DNASequenceNotSubmitted.selector);
        nft.transfuse();
    }

    //Retrieve baseURI after transfusion completed
    function testPassRevealedGetTokenUri() public {
        testPassArcanaListMint();
        testPassSetBaseTokenUri();
        testPassTransfusionSuccessful();
        uint256 tokenId = 1;
        uint256 assignedPFPId = tokenId + nft.sequenceOffset();
        string memory tokenUri = nft.tokenURI(tokenId);
        assertEq(tokenUri, string(abi.encodePacked(baseTokenURI, Strings.toString(assignedPFPId), ".json")));
    }

    // ROYALTY

    function testPassSupportsCorrectInterfaces() public {
        bytes4 erc721AInterfaceId = 0x80ac58cd;
        bytes4 erc2981InterfaceId = 0x2a55205a;
        bytes4 erc165InterfaceId = 0x01ffc9a7;
        bytes4 erc721MetadataInterfaceId = 0x5b5e139f;

        bool isERC721A = nft.supportsInterface(erc721AInterfaceId); 
        bool isER2981 = nft.supportsInterface(erc2981InterfaceId);
        bool isERC721Metdata = nft.supportsInterface(erc721MetadataInterfaceId); 
        bool isERC165 = nft.supportsInterface(erc165InterfaceId);
        
        assertEq(isERC721A, true);
        assertEq(isER2981, true);
        assertEq(isERC721Metdata, true);
        assertEq(isERC165, true);
    }

    //SET UP
    function setApprovalForAll(address owner, address proxy) public {
        vm.prank(owner, owner);
        nft.setApprovalForAll(proxy, true);
    }

    function setApprovalForOne(address owner, address proxy, uint256 id) public {
        vm.prank(owner, owner);
        nft.approve(proxy, id);
    }
    //TEST CONFIG METHODS
    //SUCCESS

    function testPassRegisterCustomBlackList() public {
        nft.registerCustomBlacklist(blacklistContractAddress, true);
    }

    function testPassRepeatRegistration() public {
        nft.repeatRegistration();
    }

    function testPassSetOperatorFilterDisabled() public {
        nft.setOperatorFilteringEnabled(false);
        assertEq(nft.operatorFilteringEnabled(), false);
    }

    function testPassSetOperatorFilterEnabled() public {
        testPassSetOperatorFilterDisabled();
        nft.setOperatorFilteringEnabled(true);
        assertEq(nft.operatorFilteringEnabled(), true);
    }

    //TRANSFER
    //SUCCESS
    function testPassCanTransferFromUsingDefaultRegistry() public {
        testPassCommunityWarChestMint();
        vm.prank(address(1), address(1));
        nft.transferFrom(address(1), founder, 0);
        assertEq(nft.balanceOf(founder), 1);
    }

    function testPassCanSafeTransferFromUsingDefaultRegistry() public {
        testPassCommunityWarChestMint();
        vm.prank(address(1), address(1));
        nft.safeTransferFrom(address(1), founder, 0);
        assertEq(nft.balanceOf(founder), 1);
    }

    function testPassCanSafeTransferFromWithDataUsingDefaultRegistry() public {
        testPassCommunityWarChestMint();
        vm.prank(address(1), address(1));
        nft.safeTransferFrom(address(1), founder, 0, "");
        assertEq(nft.balanceOf(founder), 1);
    }

    function testPassTransferFromAfterSetApprovalForAll() public {
        testPassCommunityWarChestMint();
        setApprovalForAll(address(1), address(0));
        vm.prank(address(0), address(0));
        nft.transferFrom(address(1), founder, 0);
        assertEq(nft.balanceOf(founder), 1);
    }

    function testPassTransferFromAfterSetApprovalForOne() public {
        testPassCommunityWarChestMint();
        setApprovalForOne(address(1), address(0), 0);
        vm.prank(address(0), address(0));
        nft.transferFrom(address(1), founder, 0);
        assertEq(nft.balanceOf(founder), 1);
    }

    function testPassSafeTransferAfterSetApprovalForAll() public {
        testPassCommunityWarChestMint();
        setApprovalForAll(address(1), address(0));
        vm.prank(address(0), address(0));
        nft.safeTransferFrom(address(1), founder, 0, "");
        assertEq(nft.balanceOf(founder), 1);
    }

    function testPassSafeTransferAfterSetApprovalForOne() public {
        testPassCommunityWarChestMint();
        setApprovalForOne(address(1), address(0), 0);
        vm.prank(address(0), address(0));
        nft.safeTransferFrom(address(1), founder, 0, "");
        assertEq(nft.balanceOf(founder), 1);
    }

    //FUTURE PROOFING
    function testPassIncreaseMintSupply() public {
        nft.setMintSupply(10000);
        assertEq(nft.mintSupply(), 10000);
    }

    function testPassIncreaseMintSupplyExceeded() public {
        vm.expectRevert(MaxSupplyExceeded.selector);
        nft.setMintSupply(10001);
    }

}
