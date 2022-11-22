# Arcana(ARC) 🌐
Gas optimized, royalty enforcing version of the ERC-721 NFT standard. Bootstrapped using, [**ERC721A**](https://github.com/chiru-labs/ERC721A), [**ClosedSea**](https://github.com/Vectorized/closedsea) & [**Foundry**](https://github.com/gakonst/foundry). 


## Arcana Custom Features

- Start or pause contract at will

- Set a next start time to provide real time countdown to UI

- Set the current phase to ensure real time updates to UI

- Modify hidden URI at will before reveal

- Set whitelists for 3 of the mint phases (Arcana/Aspirant/Alliance) 

- Modify token baseURI at will after reveal

- Costless mint of Arcana Treasury reserves into a wallet of choice.

- Gas optimised, payable & secure minting for each phase (Arcana, Aspirant, Alliance, Public)

- Hard cap on total mintable by each wallet for each phase

- Function to retrieve current number minted for each state


## Getting started

1. Install [**Foundry**](https://book.getfoundry.sh/getting-started/installation)

2. Clone arcana-nft-solidity repository 

```bash
  git clone https://github.com/Prominence-Games/arcana-nft-solidity.git
```

3. Change directory into the root of project

```bash
 cd /arcana-nft-solidity
```

4. Install Solidity dependencies 

```bash
  forge install
```

5. Install npm dependencies

```bash
  yarn
```
OR
```bash
  npm i 
```

## Contracts

```ml
src
 └─ ArcanaPrime.sol — "ARCANA (ARC) Smart Contract"
``` 

## Tests

```ml
test
├─ ArcanaPrime.t.sol — "ARCANA (ARC) Smart Contract Tests"
└─ helpers
   ├─ Merkle.sol — "Mock merkle root hash generation in smart contract"
   └─ MurkyBase.sol — "Verify merkle root and leaf hashes"
``` 

To run tests: 

```bash
  forge test -vvvvv
```

## TYPE DECLARATIONS

### Phases
```solidity
   enum Phases{ CLOSED, ARCANA, ASPIRANT, ALLIANCE, PUBLIC }
```
The Phases enum declares the different phases of minting of the ARC NFTs. 

## CONSTANTS
Constants are set once during initiation and cannot be changed after.

### WAR_CHEST_SUPPLY
```solidity
    uint256 public constant WAR_CHEST_SUPPLY = 512;
```
This constant represents the community reserves of Arcana which will be minted into a community wallet during the CLOSED phase.

### MAX_ENTITLEMENTS_ALLOWED
```solidity
  uint256 public constant MAX_ENTITLEMENTS_ALLOWED = 2;
```
This constant represents the maximum allowed ARCs per wallet cumulated across the whitelist phases (ARCANA, ASPIRANT, ALLIANCE). 

### MAX_QUANTITY_ALLOWED
```solidity
  uint256 public constant MAX_QUANTITY_ALLOWED = 3;
```
This constant represents the maximum allowed ARCs per wallet minted during the PUBLIC phase. 

### MAX_SUPPLY
```solidity
   uint256 public constant MAX_SUPPLY = 10_000;
```
This constant represents the maximum allowed quantity to be minted. Once the totalSupply() reaches the MAX_SUPPLY, mint functions will revert. 

### MINT_PRICE
```solidity
  uint256 public constant MINT_PRICE = 0.08 ether;
```
This constant represents the value of the transaction to be set when the mint functions are called from the client. 


## VARIABLES

### currentPhase
```solidity
  uint public currentPhase;
```
This public variable allows the client to retrieve the current phase of the mint.

### notRevealedUri
```solidity
  string public notRevealedUri;
```
This public variable allows the client to retrieve the metadata of ARCANAs before the art is revealed.

### baseTokenUri
```solidity
  string public baseTokenURI;
```
This public variable allows the client to retrieve the metadata of ARCANAs after the art is revealed

### nextStartTime
```solidity
  uint256 public nextStartTime;
```
This public variable is the UNIX timestamp of next start time which is reflected on the mint site UI. 

### paused
```solidity
  bool public paused = true;
```
This public variable is the boolean flag to toggle the smart contract mintability on and off after the start and end of each phase. 

### arcanaListMerkleRoot
```solidity
  bytes32 public arcanaListMerkleRoot;
```
This public variable holds the merkle root hash of the whitelisted addresses of the ARCANA phase.

### aspirantListMerkleRoot
```solidity
  bytes32 public aspirantListMerkleRoot;
```
This public variable holds the merkle root hash of the whitelisted addresses of the ASPIRANT phase.

### allianceListMerkleRoot
```solidity
  bytes32 public allianceListMerkleRoot;
```
This public variable holds the merkle root hash of the whitelisted addresses of the ALLIANCE phase.

### isTransfused
```solidity
  bool public isTransfused = false;
```
This public variable is the boolean flag to indicate the state of the art reveal. True means revealed and the metadata retrieved by the client will reflect that. Default is false.

### scheduledTransfusionTime
```solidity
    uint256 public scheduledTransfusionTime;
```
This public variable indicates a future block number for the sequence offset to take place.

### sequenceOffset
```solidity
  uint256 public sequenceOffset;
```
The sequence offset is used to randomly assign metadata to each ARCANA in a provably fair manner. There is no favouristism in the Promisphere.

### dna
```solidity
  string public dna;
```
The dna is a public attestation of the sequence in which the metadata were generated. With the same input and sequence, this value should always compute to be the same. 

### nonceRegistry
```solidity
  mapping(bytes32 => bool) public nonceRegistry;
```
The nonce registry is introduced as a security feature used in the PUBLIC phase to prevent bad actors from replaying transactions. 


## METHODS

### `registerCustomBlacklist`
```solidity 
function registerCustomBlacklist(address subscriptionOrRegistrantToCopy, bool subscribe) public onlyOwner {
````
This function allows us to use a custom version of the filter registry in case OpenSea has any monopolistic tendencies.

The [default OpenSea curated block list](https://github.com/ProjectOpenSea/operator-filter-registry/#deployments), `_registerForOperatorFiltering()`, is invoked without arguments.

### `setArcanaListMerkleRoot`
```solidity
  function setArcanaListMerkleRoot(bytes32 _merkleRootHash) external onlyOwner
```  
Method used to update the merkle root hash `arcanaListMerkleRoot` generated from a list of addresses in the ARCANA phase. 

### `setAspirantListMerkleRoot`
```solidity
  function setArcanaListMerkleRoot(bytes32 _merkleRootHash) external onlyOwner
```  
Method used to update the merkle root hash `aspirantListMerkleRoot` generated from a list of addresses in the ASPIRANT phase. 

### `setAllianceListMerkleRoot`
```solidity
  function setAllianceListMerkleRoot(bytes32 _merkleRootHash) external onlyOwner
```  
Method used to update the merkle root hash `allianceListMerkleRoot` generated from a list of addresses in the ALLIANCE phase. 

### `setNotRevealedBaseURI`
```solidity
  function setNotRevealedBaseURI(string memory _baseURI) external onlyOwner
```  
Method used to update the pointer (`notRevealedUri`) to the metadata file before art is revealed.

### `togglePause`
```solidity
  function togglePause(bool _state) external payable onlyOwner
```  
Method used to start or stop mint functionality (`pause`) of the smart contract at the end of each phase to prevent front-running. 

### `setNextStartTime`
```solidity
  function setNextStartTime(uint256 _timestamp) external payable onlyOwner
```  
Method used to update the `nextStartTime`. The UNIX value retrieved is used to display a countdown timer on the client. 

### `setCurrentPhase`
```solidity
  function setCurrentPhase(uint index) external payable onlyOwner
```  
Method used to set the current phase. The state of each phase (`currentPhase`) is displayed clearly in the UI to users. 

### `setBaseTokenURI`
```solidity
  function setBaseTokenURI(string memory _baseURI) external onlyOwner 
```  
Method used to set the pointer (`baseTokenURI`) of the metadata JSON post reveal. 

### `commitDNASequence`
```solidity
  function commitDNASequence(string calldata _dna) external payable onlyOwner
```  
Method used to set the `scheduledTransfusionTime` and the `dna` sequence. Can only be called once to prevent foul play by contract owner. 

### `transfuse`
```solidity
  function transfuse() external payable onlyOwner
```  
Method used to randomly assign metadata to each token id via the `sequenceOffset` variable. Can only be called once and after `commitDNASequence` is invoked.

### `mintWarChestReserve`
```solidity
  function mintWarChestReserve(address _communityWalletPublicKey) external payable isBelowMaxSupply(WAR_CHEST_SUPPLY) onlyOwner
```  
Method used to mint `WAR_CHEST_SUPPLY` pieces of ARCANAs into the community reserve into an address of our choosing by the contract owner. 

### `mintArcanaList`
```solidity
  function mintArcanaList(bytes32[] calldata _merkleProof, uint256 _quantity) external payable isBelowMaxSupply(_quantity) isWhitelisted(_merkleProof, arcanaListMerkleRoot) isNotPaused isMintOpen(Phases.ARCANA)
```  
Method invoked by the client during the ARCANA phase. Modifiers used to check that there is enough supply, address is whitelisted, contract is not paused and the current phase is correct. Internally that checks enough ETH is paid and that the entitlement restriction for the phase is not exceeded.

### `mintAspirantList`
```solidity
  function mintAspirantList(bytes32[] calldata _merkleProof, uint256 _quantity) external payable isBelowMaxSupply(_quantity) isWhitelisted(_merkleProof, aspirantListMerkleRoot) isNotPaused isMintOpen(Phases.ASPIRANT)
```  
Method invoked by the client during the ASPIRANT phase. Modifiers used to check that there is enough supply,  address is whitelisted, contract is not paused and the current phase is correct. Internally that checks enough ETH is paid and that the entitlement restriction for the phase is not exceeded.

### `mintAllianceList`
```solidity
  function mintAllianceList(bytes32[] calldata _merkleProof, uint256 _quantity) external payable isBelowMaxSupply(_quantity) isWhitelisted(_merkleProof, arcanaListMerkleRoot) isNotPaused isMintOpen(Phases.ARCANA)
```  
Method invoked by the client during the ALLIANCE phase. Modifiers used to check that there is enough supply,  address is whitelisted, contract is not paused and the current phase is correct. Internally that checks enough ETH is paid and that the entitlement restriction for the phase is not exceeded.

### `mintPublic`
```solidity
  function mintPublic(uint256 _quantity, bytes32 _nonce, bytes32 _hash, uint8 v, bytes32 r, bytes32 s) external payable isBelowMaxSupply(_quantity) isNotPaused isMintOpen(Phases.PUBLIC) 
```  
Method invoked by the client during the PUBLIC phase. Modifiers used to check that there is enough supply, contract is not paused and the current phase is correct. Internally checks that the signed nonce sent from the client as a function parameter is the same as the one that is generated on nthe fly. Farthermore, the nonce used must not be used before to prevent replay attacks. Also checks that value of transaction matches the quantity minted and that the quantity restriction for the PUBLIC phase is not exceeded.

### `tokenURI`
```solidity
  function tokenURI(uint256 _tokenId) public view override returns (string memory)
```  
Overrides the super function that is used by NFT marketplaces to retrieve metadata about the token. The contruct of this changes pre-reveal and post-reveal. 


### `getBits`
```solidity
  function getBits(uint256 _input, uint256 _startBit, uint256 _length) private pure returns (uint256)
```  
Gas optimised way to retrieve the total tokens minted by a wallet at each phase. 

### `getTotalEntitlements`
```solidity
   function getTotalEntitlements(address _minter) public view returns (uint256)
```  
Gas optimised way to retrieve the cumulative tokens minted across the whitelist phases (ARCANA, ASPIRANT, ALLIANCE) 

### `getPublicListMints`
```solidity
  function getPublicListMints(address _minter) public view returns (uint256)
```  
Gas optimised way to retrive the total tokens minted in the PUBLIC phase. 


## ERRORS

### `MaxQuantityAllowedExceeded`
```solidity
  error MaxQuantityAllowedExceeded();
```  
Error reverted when the max quantity allowed in the PUBLIC mint phase is exceeded. 

### `MaxEntitlementsExceeded`
```solidity
  error MaxEntitlementsExceeded();
```  
Error reverted when the cumulative mints exceeds the `MAX_ENTITLEMENTS_ALLOWED` value across the whitelist phases (ARCANA, ASPIRANT, ALLIANCE) 

### `MaxSupplyExceeded`
```solidity
  error MaxSupplyExceeded();
```  
Error reverted when the sum of the `totalSupply()` + `quantity` is more than or equals to the `MAX_SUPPLY` 

### `ContractIsPaused`
```solidity
  error ContractIsPaused();
```  
Error reverted when the smart contract is paused but any one of the four public phases mint methods are called. `mintArcanaList`, `mintAspirantList`, `mintAllianceList`, `publicMint`

### `PriceIncorrect`
```solidity
  error PriceIncorrect();
```  
Error reverted when value set for the transaction falls below the `quantity` X `MINT_PRICE`. 

### `ContractsNotAllowed`
```solidity
  error ContractsNotAllowed();
```  
Error reverted when a smart contract is used to mint the public phase. 

### `NonceConsumed`
```solidity
  error NonceConsumed();
```  
Error reverted when a used nonce that is found in the `nonceRegistry` is reused in the `publicMint` function. This is to prevent replay attacks. 

### `HashMismatched`
```solidity
  error HashMismatched();
```  
Error reverted when the hash calculated onchain is not the same as the one calculated by the client. 

### `MerkleProofInvalid`
```solidity
  error MerkleProofInvalid();
```  
Error reverted when merkle proof hash of the leaf node sent from the client is not part of the markle tree hash proof. This means that the invoker is not part of the whitelist. 

### `SignedHashMismatched`
```solidity
  error SignedHashMismatched();
```  
Error reverted when the signed hash calculated onchain is not the same as the one calculated by the client. This means that the invoker of the method is not the same as the once who signed it. 

### `MintIsNotOpen`
```solidity
  error MintIsNotOpen();
```  
Error reverted when the `pause` is false but any one of the four mint functions are invoked. `mintArcanaList`, `mintAspirantList`, `mintAllianceList`, `publicMint`

### `DNASequenceHaveBeenInitialised`
```solidity
  error DNASequenceHaveBeenInitialised();
```  
Error reverted when the `scheduledTransfusionTime` has already been set once. 

### `DNASequenceNotSubmitted`
```solidity
  error DNASequenceNotSubmitted();
```  
Error reverted when the `scheduledTransfusionTime` has not been set. `commitDNASequence` needs to be invoked first. 

### `NotReadyForTranfusion`
```solidity
  error NotReadyForTranfusion();
```  
Error reverted when the `block.number` < `scheduledTransfusionTime`. This value needs  `block.number` needs to be less than `256` blocks from `scheduledTransfusionTime` or transfusion will break. 

### `TransfusionSequenceCompleted`
```solidity
  error TransfusionSequenceCompleted();
```  
Error reverted when the  `isTransfused` flag is set to true. This means that the `transfuse` function has already been successfully invoked once. 


## MODIFIERS
### `isMintOpen`
```solidity
  modifier isMintOpen(Phases phase) 
```  
Modifier to guard a function and revert if `currentPhase` is not equal to the `unint(phase)`. This means that the wrong mint function is invoked in the wrong phase. 

### `isNotPaused`
```solidity
  modifier isNotPaused()
```  
Modifier to guard a function from minting when the contract is paused. 

### `isBelowMaxSupply`
```solidity
  modifier isBelowMaxSupply(uint256 _amount)
```  
Modifier to guard function from executing if the `totalSupply()` + `_amount` > `MAX_SUPPLY`. This is introduced to ensure that no more than `MAX_SUPPLY` is minted.

### `isWhitelisted`
```solidity
  modifier isWhitelisted(bytes32[] calldata _merkleProof, bytes32 _merkleRoot)
```  
Modifer checks the merkle proof of each node against the merkle tree root hash. If the node is not part of the tree, the mint function is prevented from executing and reverts with an error. 

## Acknowledgements

Special thanks to: 
- vectorized.eth (ClosedSea) - [@optimizoor](https://twitter.com/optimizoor)
- chiru-labs (ERC721A) - [@chiru-labs](https://github.com/chiru-labs)
- Paradigm (Foundry) - [@Foundry](https://github.com/foundry-rs/foundry)
