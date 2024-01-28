// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import {ChainlinkPriceFeed} from "./ChainlinkPriceFeed.sol";
import {IterableMapping} from "./IterableMapping.sol";

contract BulletproofMultiNFTVideo is
    ERC2981,
    ERC1155Supply,
    ERC1155URIStorage,
    ReentrancyGuard,
    Ownable
{
    using Counters for Counters.Counter;
    using ChainlinkPriceFeed for uint256;
    using IterableMapping for IterableMapping.Map;

    //Token Ids
    Counters.Counter private tokenIds;
    //track owner earnings address => balance
    IterableMapping.Map private addressBalances;
    //Token URI mapping for Token Ids => uri
    mapping(uint256 => string) private tokenURIs;
    //mapping owners to Token Ids => ownerAddress
    mapping(uint256 => address) private tokenOwners;
    //track mint stats _tokenId => timesUsed
    mapping(uint256 => uint256) private timesTokenUsed;
    //total royalties amount
    uint256 private _outstandingRoyalties;
    //Mint Price in WEI
    uint256 public mintPrice;
    //LockedContebt Mint Price in WEI
    uint256 public lockedContentMintPrice;
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
    }

    //events
    error InvalidAddress();
    error InvalidToken(uint256 _id);
    event LogMint(address _address, uint256 _id);
    event RoyaltiesClaimed(address _address, uint256 _amount);

    /**
     * @dev     Contract constructor
     * @param   _uri for nft base uri containing default track.
     * @param   _mintPrice mint price in WEI.
     * @param   _lockedContentMintPrice mint price in WEI.
     */
    constructor(
        string memory _uri,
        uint256 _mintPrice,
        uint256 _lockedContentMintPrice
    ) ERC1155(_uri) {
        name = "Bulletproof Productions Video";
        symbol = "BPV";
        mintPrice = _mintPrice; //1 USDC 18 0's
        lockedContentMintPrice = _lockedContentMintPrice;
        sharePerMint = 50; //percent
        _outstandingRoyalties = 0;
        _setDefaultRoyalty(msg.sender, (100 * sharePerMint)); //basis points
    }

    /**
     * @dev     Getter for contract address
     * @return  contract address.
     */
    function contractAddress() public view returns (address) {
        return address(this);
    }

    /**
     * @notice  Sets mint price for NFTs with existing backing track
     * @dev     Sets mint price for NFTs with existing backing track
     * @param   _mintPrice in wei.
     * @return  uint256 current mint price.
     */
    function setMintPrice(
        uint256 _mintPrice
    ) public onlyOwner returns (uint256) {
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
     * @notice  Displays current mint price converted using Chainlink.
     * @param   _aggregatorInterfaceAddress Chainlink. AggregatorInterfaceV3 contract address
     * @param   _mintPrice the price in wei to convert.
     * @dev     Get method for current mint price.
     * @return  uint256 mint price in wei.
     */
    function getConvertedMintPrice(
        address _aggregatorInterfaceAddress,
        uint256 _mintPrice
    ) public view virtual returns (uint256) {
        return _mintPrice.getFiatConversionRate(_aggregatorInterfaceAddress);
    }

    /**
     * @notice  Set the locked content track mint price.
     * @dev     Set the locked content track mint price.
     * @param   _lockedContentMintPrice the locked content track mint price in wei.
     * @return  uint256 the locked content track mint price in wei.
     */
    function setLockedContentTrackMintPrice(
        uint256 _lockedContentMintPrice
    ) public onlyOwner returns (uint256) {
        lockedContentMintPrice = _lockedContentMintPrice;
        return lockedContentMintPrice;
    }

    /**
     * @notice  Returns the locked content track mint price.
     * @dev     Getter for the locked content track mint price.
     * @return  uint256 the locked content track mint price in wei.
     */
    function getLockedContentMintPrice() public view virtual returns (uint256) {
        return lockedContentMintPrice;
    }

    /**
     * @notice  Sets the share per mint in percentage to the mint price
     *          used to calculate royalties for the creator.
     * @dev     Sets the share per mint in percentage to the mint price
     *          used to calculate royalties for the creator..
     * @param   _sharePercentage  in percentage points.
     * @return  uint96  the current share per mint percentage points.
     */
    function setSharePerMint(
        uint96 _sharePercentage
    ) public onlyOwner returns (uint96) {
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
    function setTokenURI(
        uint256 tokenId,
        string memory _tokenURI
    ) public onlyOwner {
        if (!exists(tokenId)) {
            revert InvalidToken(tokenId);
        }
        tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @notice  The NFTs metadata URI..
     * @dev     Getter for the NFTs metadata URI..
     * @param   tokenId id of the NFT token.
     * @return  string the IPFS metadata URI.
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual returns (string memory) {
        if (!exists(tokenId)) {
            revert InvalidToken(tokenId);
        }
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
        if (!exists(tokenId)) {
            revert InvalidToken(tokenId);
        }
        address _ownerAddress = tokenOwners[tokenId];
        return _ownerAddress;
    }

    /**
     * @notice  Returns token Id's owned by an owner.
     * @dev     Returns an array of token Ids owned by the supplied address or an empty array.
     * @param   _ownerAddress the owner address.
     * @return  int256[] the token Ids owner by supplied address and -1 for unowned tokens.
     */
    function getTokensByOwner(
        address _ownerAddress
    ) public view virtual returns (int256[] memory) {
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
    function getRoyaltyBalanceByOwner(
        address _ownerAddress
    ) public view virtual returns (uint256) {
        if (_ownerAddress == address(0)) revert InvalidAddress();
        uint256 ownerBalance = addressBalances.get(_ownerAddress);
        return ownerBalance;
    }

    /**
     * @dev     Set the royalties amount in wei for an owner.
     * @param   _ownerAddress address of an owner.
     * @param   amount of royalties to set in wei for _ownerAddress.
     * @return  uint256 the blance of current royalties owed to the supplied _ownerAddress.
     */
    function setRoyaltyBalanceByOwner(
        address _ownerAddress,
        uint256 amount
    ) internal virtual nonReentrant returns (uint256) {
        if (_ownerAddress == address(0)) revert InvalidAddress();
        addressBalances.set(_ownerAddress, amount);
        return amount;
    }

    /**
     * @dev     Function used for checking total royalty amount owed to owners by the contract.
     * @return  uint256  the blance of current royalties held by the contract.
     */
    function getTotalRoyaltiesBalance() public view virtual returns (uint256) {
        uint256 totalRoyaltyAmount = 0;
        for (uint256 index = 0; index < addressBalances.size(); index++) {
            address trackOwner = addressBalances.getKeyAtIndex(index);
            totalRoyaltyAmount += addressBalances.get(trackOwner);
        }
        return totalRoyaltyAmount;
    }

    /**
     * @dev     Getter for single token.
     * @param   tokenId an existing token Id.
     * @return  RenderToken[] returns token details with tokenID for rendering.
     */
    function getToken(
        uint256 tokenId
    ) public view returns (RenderToken[] memory) {
        if (!exists(tokenId)) {
            revert InvalidToken(tokenId);
        }
        RenderToken[] memory res = new RenderToken[](1);
        string memory toknURI = uri(tokenId);
        address trackOwner = getOwner(tokenId);
        uint256 trackUsage = timesTokenUsed[tokenId];
        res[0] = RenderToken(tokenId, trackUsage, toknURI, trackOwner);
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
                uint256 trackUsage = timesTokenUsed[counter];

                res[counter] = RenderToken(
                    counter,
                    trackUsage,
                    toknURI,
                    trackOwner
                );
            }
            counter++;
        }
        return res;
    }

    /**
     * @notice  Mint function for an NFT with an existing track.
     * @dev     Mints an NFT with using Native Chain Token.
     *          Checks if trackId exists and updates royalties accordingly.
     * @param   recipient reciepient of the NFT.
     * @param   toknURI metadata URI of the NFT.
     * @param   amount of NFTs to mint hardcoded to 1.
     * @param   trackId the token Id of their backing track.
     * @return  uint256 token Id of minted NFT.
     */
    function mint(
        address recipient,
        string memory toknURI,
        uint256 amount,
        uint256 trackId,
        bool hasLockedContent
    ) public payable virtual nonReentrant returns (uint256) {
        uint256 _mintPrice = mintPrice;
        if (hasLockedContent) {
            _mintPrice = lockedContentMintPrice;
        }
        amount = 1;
        if (msg.sender == address(0)) revert InvalidAddress();

        if (msg.sender != owner()) {
            require(msg.value >= (_mintPrice * amount), "Insufficient funds");
        }
        uint256 newId = tokenIds.current();
        bytes memory data;

        _setTokenURI(newId, toknURI);
        _setTokenOwner(newId, recipient);

        if (exists(trackId) && trackId != newId) {
            //add to owner balance
            //check if they are re-minting one of their own tracks
            //only pay if they are minting someone elses track and
            //they are minting it to their own wallet
            if (msg.sender != tokenOwners[trackId]) {
                uint256 curreentUserBalance = addressBalances.get(
                    tokenOwners[trackId]
                );
                addressBalances.set(
                    tokenOwners[trackId],
                    curreentUserBalance + _calcPayment(_mintPrice * amount)
                );
                //increase trackId usage
                uint256 timesUsed = timesTokenUsed[trackId];
                timesTokenUsed[trackId] = timesUsed + 1;
                //add to total royalties
                _outstandingRoyalties += _calcPayment(_mintPrice * amount);
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
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev     Returns Token URI.
     * @param   tokenId for uri.
     * @return  string ipfs url for tokenId.
     */
    function uri(
        uint256 tokenId
    )
        public
        view
        virtual
        override(ERC1155URIStorage, ERC1155)
        returns (string memory)
    {
        if (!exists(tokenId)) {
            revert InvalidToken(tokenId);
        }
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
    function withdrawRoyalty(
        address _ownerAddress
    ) public payable nonReentrant returns (uint256) {
        require(address(this).balance > 0, "No ETH in contract");
        require(
            addressBalances.get(_ownerAddress) > 0,
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
        addressBalances.set(_ownerAddress, 0);
        (bool success, ) = payable(_ownerAddress).call{value: amountToPay}("");
        require(success);
        _outstandingRoyalties -= amountToPay;
        emit RoyaltiesClaimed(_ownerAddress, amountToPay);
        return addressBalances.get(_ownerAddress);
    }

    /**
     * @dev     Returns contract total balance.
     * @return  uint256 total contract balance.
     */
    function bpBalance() public view virtual onlyOwner returns (uint256) {
        return address(this).balance;
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
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
