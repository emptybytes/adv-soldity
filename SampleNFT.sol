// SPDX-License-Identifier: MIT
// Edited By Mahendra

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


contract SampleNFT is ERC721, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private supply;

  string public uriPrefix = "";
  string public uriSuffix = ".json";
  string public hiddenMetadataUri;

  bytes32 public merkleROOT = 0xc501564b13c1bfaf644df26a6f61d5f5ab8fb6039a872c56bd3382cd7b0b20aa;     // Whitelisted user 
  
  uint256 public cost = 0.1 ether;
  uint256 public maxSupply = 10;
  uint256 public maxMintAmountPerTx = 2;

  bool public paused = true;
  bool public revealed = false;

  bool public presale = true; 
  mapping(address => bool) public whitelisted;
  uint256 public maxPresaleMintAmount = 5;

  constructor() ERC721("SAMPLE", "SAMPLE") {
    setHiddenMetadataUri("ipfs://__XYZ_CID__/hidden.json");
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
    require(supply.current() + _mintAmount <= maxSupply, "Max supply exceeded!");
    _;
  }

  function totalSupply() public view returns (uint256) {
    return supply.current();
  }

 function changeMerkleROOT(bytes32 _merkleRoot) public onlyOwner {
     merkleROOT = _merkleRoot;
 }

  function mint(bytes32[] calldata _merkleHASHes, uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
    require(!paused, "The contract is paused!");
    require(msg.value >= cost * _mintAmount, "Insufficient funds!");

     //Don't allow minting if presale is set and buyer is not in whitelisted map
    if (presale) {
        if ( !isInWhiteList(_merkleHASHes, msg.sender))  {
            revert("Buyer is not in Whitelist for Pre-Sale");
        }
        // //Check if already bought 
        if ( balanceOf(msg.sender)+_mintAmount > maxPresaleMintAmount)
            revert("Buyer has already pre-sale minted max tokens");
    } 

    _mintLoop(msg.sender, _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _mintLoop(_receiver, _mintAmount);
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 1;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      address currentTokenOwner = ownerOf(currentTokenId);

      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

    function setPresale(bool _state) public onlyOwner {
      presale = _state;
  }

  function setMaxPresaleMintAmount(uint256 _max) public onlyOwner {
      maxPresaleMintAmount = _max;
  }

  function addToWhiteList(address _addr) public onlyOwner {
      whitelisted[_addr] = true;
  }

  function addArrayToWhiteList(address[] memory _addrs) public onlyOwner {
      for (uint256 i=0;i< _addrs.length;i++)
          whitelisted[_addrs[i]] = true; 
  }

  function removeFromWhiteList(address _addr) public onlyOwner {
      whitelisted[_addr] = false;
  }

  function isInWhiteList(bytes32[] calldata merkleHash, address _addr) private view returns (bool) {
      // Verify the provided _merkleProof, given to us through the API call on our website
        bytes32 leaf = keccak256(abi.encodePacked(_addr));

        return MerkleProof.verify(merkleHash, merkleROOT, leaf);
      // return whitelisted[_addr]  || _addr == owner();
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function withdraw() public onlyOwner {

    // This will transfer the remaining contract balance to the owner.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
    // =============================================================================
  }

  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      supply.increment();
      _safeMint(_receiver, supply.current());
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}
