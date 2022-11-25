// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract BulletproofMultiNFTGenesis is
    ERC2981,
    ERC1155Supply,
    ERC1155URIStorage,
    ERC1155Pausable,
    ReentrancyGuard,
    Ownable
{
    using Counters for Counters.Counter;
    using Strings for uint256;

    enum NftType {
        beat,
        blank,
        song,
        sfx,
        vocal,
        speech,
        stems,
        charity,
        soundkit,
        meme
    }

    //Token Ids
    Counters.Counter private tokenIds;
    //Token URI mapping for Token Ids => uri
    mapping(uint256 => string) private tokenURIs;
    //mapping owners to Token Ids => ownerAddress
    mapping(uint256 => address) private tokenOwners;
    //track owner earnings address => balance
    mapping(address => uint256) private addressBalances;
    //nft type id => type
    mapping(uint256 => NftType) private tokenType;
    //track mint stats _tokenId => timesUsed
    mapping(uint256 => uint256) private timesTrackUsed;
    //total royalties amount
    uint256 private _outstandingRoyalties;
    //Mint Price in WEI
    uint256 public mintPrice;
    //LockedContebt Track Mint Price in WEI
    uint256 public lockedContentTrackMintPrice;
    //percentage share per mint
    uint96 private sharePerMint;
    // Contract name
    string public name;
    // Contract symbol
    string public symbol;

    struct RenderToken {
        uint256 id;
        uint256 usage;
        string uri;
        address owner;
        NftType nftType;
    }

    //events
    error InvalidAddress();
    event LogMint(address _address, uint256 _id);
    event RoyaltiesClaimed(address _address, uint256 _amount);

    constructor(string memory _uri) ERC1155(_uri) {
        name = "Billetproof Productions";
        symbol = "BP";
        mintPrice = 1000000000000000000; //1 USDC 18 0's
        lockedContentTrackMintPrice = 2000000000000000000;
        sharePerMint = 50; //percent
        _outstandingRoyalties = 0;
        _setDefaultRoyalty(msg.sender, (100 * sharePerMint)); //basis points
    }

    /**
     * @notice  Sets mint price for NFTs with existing backing track
     * @dev     Sets mint price for NFTs with existing backing track
     * @param   _mintPrice in wei.
     * @return  uint256 current mint price.
     */
    function setMintPrice(uint256 _mintPrice)
        public
        onlyOwner
        returns (uint256)
    {
        mintPrice = _mintPrice;
        return mintPrice;
    }

    /**
     * @notice  Displays current mint price.
     * @dev     Get method for current mint price.
     * @return  uint256 mint price in wei.
     */
    function getMintPrice() public view virtual returns (uint256) {
        return mintPrice;
    }

    /**
     * @notice  Set the locked content track mint price.
     * @dev     Set the locked content track mint price.
     * @param   _lockedContentTrackMintPrice the locked content track mint price in wei.
     * @return  uint256 the locked content track mint price in wei.
     */
    function setLockedContentTrackMintPrice(
        uint256 _lockedContentTrackMintPrice
    ) public onlyOwner returns (uint256) {
        lockedContentTrackMintPrice = _lockedContentTrackMintPrice;
        return lockedContentTrackMintPrice;
    }

    /**
     * @notice  Returns the locked content track mint price.
     * @dev     Getter for the locked content track mint price.
     * @return  uint256 the locked content track mint price in wei.
     */
    function getLockedContentTrackMintPrice()
        public
        view
        virtual
        returns (uint256)
    {
        return lockedContentTrackMintPrice;
    }

    /**
     * @notice  Sets the share per mint in percentage to the mint price
     *          used to calculate royalties for the creator.
     * @dev     Sets the share per mint in percentage to the mint price
     *          used to calculate royalties for the creator..
     * @param   _sharePercentage  in percentage points.
     * @return  uint96  the current share per mint percentage points.
     */
    function setSharePerMint(uint96 _sharePercentage)
        public
        onlyOwner
        returns (uint96)
    {
        sharePerMint = _sharePercentage;
        return sharePerMint;
    }

    /**
     * @notice  Gets the share per mint in percentage to the mint price
     *          used to calculate royalties for the creator.
     * @dev     Gets the share per mint in percentage to the mint price
     *          used to calculate royalties for the creator.
     * @return  uint96  the current share per mint percentage points.
     */
    function getSharePerMint() public view virtual returns (uint96) {
        return sharePerMint;
    }

    /**
     * @notice  Sets the NFTs metadata URI.
     * @dev     Sets the NFTs metadata URI per token ID.
     * @param   tokenId  id of the NFT token.
     * @param   _tokenURI  the IPFS metadata URI.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal {
        tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @notice  Sets the NFTs metadata URI.
     * @dev     Sets the NFTs metadata URI per token ID.
     * @param   tokenId  id of the NFT token.
     * @param   _tokenURI  the IPFS metadata URI.
     */
    function setTokenURI(uint256 tokenId, string memory _tokenURI)
        public
        onlyOwner
    {
        require(exists(tokenId));
        tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @notice  The NFTs metadata URI..
     * @dev     Getter for the NFTs metadata URI..
     * @param   tokenId id of the NFT token.
     * @return  string the IPFS metadata URI.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        returns (string memory)
    {
        require(exists(tokenId));
        string memory _tokenURI = tokenURIs[tokenId];
        return _tokenURI;
    }

    /**
     * @notice  Sets the owner of an NFT.
     * @dev     Sets the owner of an NFT used for royalty calculations.
     * @param   tokenId id of the NFT.
     * @param   _tokenOwner address of the owner.
     */
    function _setTokenOwner(uint256 tokenId, address _tokenOwner) internal {
        tokenOwners[tokenId] = _tokenOwner;
    }

    /**
     * @notice  Returns the owner of an NFT.
     * @dev     Returns address of the owner for the supplied token Id.
     * @param   tokenId of an NFT.
     * @return  address of the owner of the NFT.
     */
    function getOwner(uint256 tokenId) public view virtual returns (address) {
        require(exists(tokenId));
        address _ownerAddress = tokenOwners[tokenId];
        return _ownerAddress;
    }

    /**
     * @notice  Returns token Id's owned by an owner.
     * @dev     Returns an array of token Ids owned by the supplied address or an empty array.
     * @param   _ownerAddress the owner address.
     * @return  int256[] the token Ids owner by supplied address and -1 for unowned tokens.
     */
    function getTokensByOwner(address _ownerAddress)
        public
        view
        virtual
        returns (int256[] memory)
    {
        uint256 lastestId = tokenIds.current();
        int256 counter = 0;
        int256[] memory ownedTokensIds = new int256[](lastestId);
        for (uint256 i = 0; i < lastestId; i++) {
            if (tokenOwners[i] == _ownerAddress) {
                ownedTokensIds[i] = counter;
            } else {
                ownedTokensIds[i] = -1;
            }
            counter++;
        }
        return ownedTokensIds;
    }

    /**
     * @dev     Gets the blance of current royalties owed to the supplied _ownerAddress.
     * @param   _ownerAddress address of wallet.
     * @return  uint256 the blance of current royalties owed to the supplied _ownerAddress.
     */
    function getRoyaltyBalanceByOwner(address _ownerAddress)
        public
        view
        virtual
        returns (uint256)
    {
        if (_ownerAddress == address(0)) revert InvalidAddress();
        uint256 ownerBalance = addressBalances[_ownerAddress];
        return ownerBalance;
    }

    /**
     * @dev     Set the royalties amount in wei for an owner.
     * @param   _ownerAddress address of an owner.
     * @param   amount of royalties to set in wei for _ownerAddress.
     * @return  uint256 the blance of current royalties owed to the supplied _ownerAddress.
     */
    function setRoyaltyBalanceByOwner(address _ownerAddress, uint256 amount)
        internal
        virtual
        nonReentrant
        returns (uint256)
    {
        if (_ownerAddress == address(0)) revert InvalidAddress();
        addressBalances[_ownerAddress] = amount;
        return amount;
    }

    /**
     * @dev     Internal function used for checking total royalty amount owed to owners by the contract.
     * @return  uint256  the blance of current royalties held by the contract.
     */
    function getTotalRoyaltiesBalance() internal virtual returns (uint256) {
        uint256 totalRoyaltyAmount = 0;
        uint256 tokenCount = tokenIds.current();
        for (uint256 index = 0; index < tokenCount; index++) {
            address trackOwner = tokenOwners[index];
            totalRoyaltyAmount += getRoyaltyBalanceByOwner(trackOwner);
        }
        return totalRoyaltyAmount;
    }

    /**
     * @dev     Getter for single token.
     * @param   tokenId an existing token Id.
     * @return  RenderToken[] returns token details with tokenID for rendering.
     */
    function getToken(uint256 tokenId)
        public
        view
        returns (RenderToken[] memory)
    {
        require(exists(tokenId));
        RenderToken[] memory res = new RenderToken[](1);
        string memory toknURI = uri(tokenId);
        address trackOwner = getOwner(tokenId);
        uint256 trackUsage = timesTrackUsed[tokenId];
        NftType nftType = tokenType[tokenId];
        res[0] = RenderToken(tokenId, trackUsage, toknURI, trackOwner, nftType);
        return res;
    }

    /**
     * @dev     Getter for all tokens held by the contract.
     * @return  RenderToken[] returns all token details for rendering.
     */
    function getAllTokens() public view returns (RenderToken[] memory) {
        uint256 lastestId = tokenIds.current();
        uint256 counter = 0;
        RenderToken[] memory res = new RenderToken[](lastestId);
        for (uint256 i = 0; i < lastestId; i++) {
            if (exists(counter)) {
                string memory toknURI = uri(counter);
                address trackOwner = getOwner(counter);
                uint256 trackUsage = timesTrackUsed[counter];
                NftType nftType = tokenType[counter];

                res[counter] = RenderToken(
                    counter,
                    trackUsage,
                    toknURI,
                    trackOwner,
                    nftType
                );
            }
            counter++;
        }
        return res;
    }

    /**
     * @dev     Set the token type of given tokenId.
     * @param   _tokenId of NFT.
     * @param   _tokenType of token.
     */
    function _setTokenType(uint256 _tokenId, uint256 _tokenType)
        internal
        virtual
    {
        tokenType[_tokenId] = getNftType(_tokenType);
    }

    /**
     * @dev     Return the token type given a uint256 value
     * @param   _tokenType of token.
     * @return  NftType nftType.
     */
    function getNftType(uint256 _tokenType) internal virtual returns (NftType) {
        require(_tokenType <= 9);
        NftType nftType;
        if (_tokenType == 0) nftType = NftType.beat;
        if (_tokenType == 1) nftType = NftType.blank;
        if (_tokenType == 2) nftType = NftType.song;
        if (_tokenType == 3) nftType = NftType.sfx;
        if (_tokenType == 4) nftType = NftType.vocal;
        if (_tokenType == 5) nftType = NftType.speech;
        if (_tokenType == 6) nftType = NftType.stems;
        if (_tokenType == 7) nftType = NftType.charity;
        if (_tokenType == 8) nftType = NftType.soundkit;
        if (_tokenType == 9) nftType = NftType.meme;
        return nftType;
    }

    /**
     * @dev     Return the token type given a tokenId
     * @param   _tokenId of token.
     * @return  NftType nftType.
     */
    function getTokenType(uint256 _tokenId) internal virtual returns (NftType) {
        require(exists(_tokenId));
        NftType nftType;
        nftType = tokenType[_tokenId];
        return nftType;
    }

    /**
     * @notice  Mint function for an NFT with an existing track.
     * @dev     Mints an NFT with using Native Chain Token.
     *          Checks if trackId exists and updates royalties accordingly.
     * @param   recipient reciepient of the NFT.
     * @param   toknURI metadata URI of the NFT.
     * @param   amount of NFTs to mint hardcoded to 1.
     * @param   trackId the token Id of their backing track.
     * @param   nftType of the token to mint.
     * @return  uint256 token Id of minted NFT.
     */
    function mint(
        address recipient,
        string memory toknURI,
        uint256 amount,
        uint256 trackId,
        uint256 nftType
    ) public payable virtual nonReentrant returns (uint256) {
        amount = 1;
        if (msg.sender == address(0)) revert InvalidAddress();

        if (msg.sender != owner()) {
            require(msg.value >= (mintPrice * amount), "Insufficient funds");
        }
        uint256 newId = tokenIds.current();
        bytes memory data;

        _setTokenURI(newId, toknURI);
        _setTokenOwner(newId, msg.sender);
        _setTokenType(newId, nftType);

        if (exists(trackId) && trackId != newId) {
            //add to owner balance
            //check if they are re-minting one of their own tracks
            //only pay if they are minting someone elses track
            if (msg.sender != tokenOwners[trackId]) {
                addressBalances[tokenOwners[trackId]] += _calcPayment(
                    mintPrice * amount
                );
                //increase trackId usage
                uint256 timesUsed = timesTrackUsed[trackId];
                timesTrackUsed[trackId] = timesUsed + 1;
                //add to total royalties
                _outstandingRoyalties += _calcPayment(mintPrice * amount);
                //royalty
                _setTokenRoyalty(
                    newId,
                    tokenOwners[trackId],
                    (100 * sharePerMint)
                );
            }
        }
        tokenIds.increment();
        _mint(recipient, newId, amount, data);
        emit LogMint(msg.sender, newId);
        return newId;
    }

    //overides
    /**
     * @dev     Default overide handles token ownership logic.
     * @param   operator  .
     * @param   from  .
     * @param   to  .
     * @param   ids  .
     * @param   amounts  .
     * @param   data  .
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply, ERC1155Pausable) whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev     Returns Token URI.
     * @param   tokenId for uri.
     * @return  string ipfs url for tokenId.
     */
    function uri(uint256 tokenId)
        public
        view
        virtual
        override(ERC1155URIStorage, ERC1155)
        returns (string memory)
    {
        require(exists(tokenId));
        string memory _tokenURI = tokenURIs[tokenId];
        return _tokenURI;
    }

    /**
     * @dev     Withdraw function for contract owner.
     * checks owed royalties and transfers remaing balance
     */
    function withdraw()
        public
        payable
        nonReentrant
        onlyOwner
        whenNotPaused
        returns (uint256)
    {
        require(
            (address(this).balance - _outstandingRoyalties) >= 0,
            "No ETH in contract"
        );
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance - _outstandingRoyalties
        }("");
        require(success);
        return address(this).balance;
    }

    /**
     * @dev    Transfers royalty funds to owner and emits RoyaltiesClaimed event.
     * @param   _ownerAddress address to withdraw royalties.
     * @return  uint256 address of withdrawl.
     */
    function withdrawRoyalty(address _ownerAddress)
        public
        payable
        nonReentrant
        whenNotPaused
        returns (uint256)
    {
        require(address(this).balance > 0, "No ETH in contract");
        require(
            addressBalances[_ownerAddress] > 0,
            "No royalties for user found"
        );
        require(
            (address(this).balance - _outstandingRoyalties) >= 0,
            "Not enough ETH in contract for royalties"
        );
        require(
            msg.sender == _ownerAddress,
            "Royalties claimable from account they are earned from."
        );
        uint256 amountToPay = getRoyaltyBalanceByOwner(_ownerAddress);
        //reset royalty balance to 0 upon successful withdrawl
        addressBalances[_ownerAddress] = 0;
        (bool success, ) = payable(_ownerAddress).call{value: amountToPay}("");
        require(success);
        _outstandingRoyalties -= amountToPay;
        emit RoyaltiesClaimed(_ownerAddress, amountToPay);
        return addressBalances[_ownerAddress];
    }

    /**
     * @dev     Returns contract total balance.
     * @return  uint256 total contract balance.
     */
    function bpBalance() public view virtual onlyOwner returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev    Pauses contract.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev    Unpause contract.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev     Calculates royalty amount per specified mintPrice.
     * @param   _mintPrice in wei.
     * @return  uint256 .
     */
    function _calcPayment(uint256 _mintPrice) internal view returns (uint256) {
        uint256 _amount = (_mintPrice * sharePerMint) / 100;
        return _amount;
    }

    /**
     * @dev     Default overide.
     * @param   interfaceId  .
     * @return  bool  .
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
