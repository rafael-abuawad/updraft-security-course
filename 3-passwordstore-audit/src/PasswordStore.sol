// SPDX-License-Identifier: MIT
/// @custom:question Is this the correct compiler version?
pragma solidity 0.8.18;

/*
 * @author not-so-secure-dev
 * @title PasswordStore
 * @notice This contract allows you to store a private password that others won't be able to see. 
 * You can update your password at any time.
 */
contract PasswordStore {
    error PasswordStore__NotOwner();

    /// @custom:audit [INFORMATIONAL] Since there is no way to change `PasswordStore::s_owner` can we cosider
    /// using an `immutable` instead of a regular variable?
    address private s_owner;
    string private s_password;

    /// @custom:audit [INFORMATIONAL] Typo in the event
    /// @custom:audit [INFORMATIONAL] A better name convention should be used `PasswordStore__SetNewPassword`
    event SetNetPassword();

    constructor() {
        s_owner = msg.sender;
    }

    /*
     * @notice This function allows only the owner to set a new password.
     * @param newPassword The new password to set.
     */
    /// @custom:audit [HIGH] There is no access control set in this external function
    /// this means that anyone can set a new password.
    function setPassword(string memory newPassword) external {
        s_password = newPassword;
        /// @custom:audit [INFORMATIONAL] Typo in the event
        emit SetNetPassword();
    }

    /// @custom:audit [INFORMATIONAL] `newPassword` param is not used here 
    /*
     * @notice This allows only the owner to retrieve the password.
     * @param newPassword The new password to set.
     */
    function getPassword() external view returns (string memory) {
        /// @custom:audit [HIGH] All data stored in a blockchain is public, this means that if
        /// the password is store in plain text anyone is going to be able to read it. It may not be
        /// so easy to access but it can be read using some tooling.
        if (msg.sender != s_owner) {
            revert PasswordStore__NotOwner();
        }
        return s_password;
    }
}
