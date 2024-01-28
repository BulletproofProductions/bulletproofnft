// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/// @title Artist / creator verification and preferences used by Bulletproof Productions.
/// @author @BulletproofProductions
/// @notice Manages artist / creator verification and Bulletproof Productions preferences.
/// @dev Manages artist / creator verification and Bulletproof Productions preferences.
/// Only callable by Bulletproof Productions creator address.
contract ArtistVerification {
    struct User {
        bool verified;
        string settingsIPFSURL;
    }

    /// owner of contract
    address public owner;

    //user address => User struct
    mapping(address => User) private users;

    constructor(string memory _settingsURL) {
        owner = msg.sender;
        User memory user = User(true, _settingsURL);
        users[msg.sender] = user;
    }

    /**
     * @dev     Getter for contract address
     * @return  contract address.
     */
    function contractAddress() public view returns (address) {
        return address(this);
    }

    /**
     * @dev     Getter for user
     * @param   _userAddress users wallet address.
     * @return  User struct.
     */
    function getUser(
        address _userAddress
    ) public view virtual returns (User memory) {
        require(users[_userAddress].verified == true, "User Not Verified");
        return users[_userAddress];
    }

    function setUser(
        address _userAddress,
        bool _verified,
        string memory _settingsURL
    ) public returns (User memory) {
        require(msg.sender == owner, "Only owner has access");
        User memory user = User(_verified, _settingsURL);
        users[_userAddress] = user;
        return users[_userAddress];
    }

    /**
     * @dev     Getter for user verification.
     * @param   _userAddress users wallet address.
     * @return  users verification status boolean.
     */
    function isUserVerified(
        address _userAddress
    ) public view virtual returns (bool) {
        bool verified = false;
        verified = users[_userAddress].verified;
        return verified;
    }

    /**
     * @dev     Sets user verification status. Only contract owner can use this function.
     * @param   _userAddress user wallet address.
     * @param   _verified boolean verification status.
     */
    function setVerified(address _userAddress, bool _verified) public {
        require(msg.sender == owner, "Only owner has access");
        users[_userAddress].verified = _verified;
    }

    /**
     * @dev     Getter for user IPFS settings URL.
     * @param   _userAddress users wallet address.
     * @return  users IPFS settings URL.
     */
    function getUserSettingsIPFSURL(
        address _userAddress
    ) public view virtual returns (string memory) {
        require(users[_userAddress].verified == true, "User Not Verified");
        return users[_userAddress].settingsIPFSURL;
    }

    /**
     * @dev     Sets user settings url.
     * @param   _userAddress user wallet address.
     * @param   _settingsURL users IPFS settings URL.
     */
    function setUserSettingsIPFSURL(
        address _userAddress,
        string memory _settingsURL
    ) public {
        require(users[_userAddress].verified == true, "User Not Verified");
        users[_userAddress].settingsIPFSURL = _settingsURL;
    }
}
