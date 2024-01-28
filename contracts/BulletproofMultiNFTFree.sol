// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract BulletproofMultiNFTFree is
    ERC1155Supply,
    ERC1155URIStorage,
    ReentrancyGuard,
    Ownable
{
    using Counters for Counters.Counter;

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
    //nft type id => type
    mapping(uint256 => NftType) private tokenType;
    // Contract name
    string public name;
    // Contract symbol
    string public symbol;
    //max number of tokens per holder
    uint256 public maxTokens;

    struct RenderToken {
        uint256 id;
        uint256 usage;
        string uri;
        address owner;
        NftType nftType;
    }

    //events
    error InvalidAddress();
    error MaxTokenAllowanceReached(address _address);
    error InvalidToken(uint256 _id);
    event LogMint(address _address, uint256 _id);

    /**
     * @dev     Contract constructor
     * @param   _uri for nft base uri containing default track.
     * @param   _maxTokens max number of tokens per holder
     */
    constructor(string memory _uri, uint256 _maxTokens) ERC1155(_uri) {
        name = "Bulletproof Productions";
        symbol = "BP";
        maxTokens = _maxTokens;
    }

    /**
     * @dev     Getter for contract address
     * @return  contract address.
     */
    function contractAddress() public view returns (address) {
        return address(this);
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
     * @notice  Sets the maximum amount of tokens per holder.
     * @dev     Sets the maximum amount of tokens per holder globally.
     * @param   _maxTokens numner of maximum tokens per wallet.
     */
    function setMaxTokens(uint256 _maxTokens) public onlyOwner {
        maxTokens = _maxTokens;
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
     * @notice  Returns the number of tokens owned for supplied address.
     * @dev     Returns the number of tokens owned by the supplied address.
     * @param   _ownerAddress the owner address.
     * @return  uint256 the number of tokens owned by the supplied address.
     */
    function getNumberTokensOwned(
        address _ownerAddress
    ) public view virtual returns (uint256) {
        uint256 lastestId = tokenIds.current();
        uint256 counter = 0;
        for (uint256 i = 0; i < lastestId; i++) {
            if (tokenOwners[i] == _ownerAddress) {
                counter++;
            }
        }
        return counter;
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
        uint256 usage = 0;
        RenderToken[] memory res = new RenderToken[](1);
        string memory toknURI = uri(tokenId);
        address trackOwner = getOwner(tokenId);
        NftType nftType = tokenType[tokenId];
        res[0] = RenderToken(tokenId, usage, toknURI, trackOwner, nftType);
        return res;
    }

    /**
     * @dev     Getter for all tokens held by the contract.
     * @return  RenderToken[] returns all token details for rendering.
     */
    function getAllTokens() public view returns (RenderToken[] memory) {
        uint256 lastestId = tokenIds.current();
        uint256 counter = 0;
        uint256 usage = 0;
        RenderToken[] memory res = new RenderToken[](lastestId);
        for (uint256 i = 0; i < lastestId; i++) {
            if (exists(counter)) {
                string memory toknURI = uri(counter);
                address trackOwner = getOwner(counter);
                NftType nftType = tokenType[counter];

                res[counter] = RenderToken(
                    counter,
                    usage,
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
     * @dev     Getter for all tokens held by the contract.
     * @param   _ownerAddress the owner address.
     * @return  RenderToken[] returns all token details for rendering.
     */
    function getAllOwnerTokensRender(
        address _ownerAddress
    ) public view returns (RenderToken[] memory) {
        uint256 lastestId = tokenIds.current();
        uint256 counter = 0;
        uint256 usage = 0;
        RenderToken[] memory res = new RenderToken[](lastestId);
        for (uint256 i = 0; i < lastestId; i++) {
            if (exists(counter)) {
                if (tokenOwners[i] == _ownerAddress) {
                    string memory toknURI = uri(counter);
                    address trackOwner = getOwner(counter);
                    NftType nftType = tokenType[counter];

                    res[counter] = RenderToken(
                        counter,
                        usage,
                        toknURI,
                        trackOwner,
                        nftType
                    );
                }
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
    function _setTokenType(
        uint256 _tokenId,
        uint256 _tokenType
    ) internal virtual {
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
        if (!exists(_tokenId)) {
            revert InvalidToken(_tokenId);
        }
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
     * @param   nftType of the token to mint.
     * @return  uint256 token Id of minted NFT.
     */
    function mint(
        address recipient,
        string memory toknURI,
        uint256 amount,
        uint256 nftType
    ) public payable virtual nonReentrant returns (uint256) {
        amount = 1;
        if (getNumberTokensOwned(recipient) >= maxTokens)
            revert MaxTokenAllowanceReached(recipient);
        if (msg.sender == address(0)) revert InvalidAddress();

        uint256 newId = tokenIds.current();
        bytes memory data;

        _setTokenURI(newId, toknURI);
        _setTokenOwner(newId, recipient);
        _setTokenType(newId, nftType);

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
     * @dev     Default overide.
     * @param   interfaceId  .
     * @return  bool  .
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
