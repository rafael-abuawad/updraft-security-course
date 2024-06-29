## HIGHS

### [H-1] Storing the password onchain makes it visible to anyone, and not private

**Description:** All data stored onchain is visible to anyone and can be read directly from the blockchain. the `PasswordStore::s_password` is intended to be private and only accesible through ther `PasswordStore::getPassword()` function, which is intended to be only accesible to the owner. 

We show one such method of reading any data offchain bellow.

**Impact:** Anyone can read the private password, severly braking the functionality of the protocol.

**Proof of Concept:**

```bash
$ cast storage <contract address> <storage slot> --rpc-url <url>
$ cast parse-bytes32-string <above's command output>
```

**Recommended Mitigation:** Due to this, the overall architecture of the contract should be rethought. One could encrypt the password offchain, and the store the encrypted asword onchain. This woudl require the user to remember another password offchain to decrypt the password. However, you'd also likely want to remove the view function as you don't want the user to accidentally sends a transaction with the password that decrypts your password.

---

### [H-2] There is no access control set on the `PasswordStore::setPassword` function, allowing anyone to set a new password

**Description:** The `PasswordStore::setPassword` function is an `external` function that doesn't cehck if the caller is the owner, allowing any caller to set a new password.

The natspec of the function and the overall purpose of the smart contract is that `This function allows only the owner to set a new password.`.

```javascript
/// @custom:audit [HIGH] There is no access control set in this external function this means that anyone can set a new password.
function setPassword(string memory newPassword) external {
    s_password = newPassword;
    emit SetNetPassword();
}
```

**Impact:** Allows **anyone** to set a new password.

**Proof of Concept:** (Proof of Code)

Using Foundry fuzzing we can test that indeed multipple random addresses can set the new password.

```javascript
function test_non_owner_can_set_a_new_password(address anyone) public {
    vm.startPrank(anyone);
    string memory expectedPassword = "myNewPassword";
    passwordStore.setPassword(expectedPassword);

    vm.startPrank(owner);
    string memory actualPassword = passwordStore.getPassword();
    assertEq(actualPassword, expectedPassword);
}
```

**Recommended Mitigation:** Add access control conditional to the `PasswordStore::setPassword` function:

```diff
function setPassword(string memory newPassword) external {
+   if (msg.sender != s_owner) {
+       revert PasswordStore__NotOwner();
+   }    
    s_password = newPassword;
    emit SetNetPassword();
}
```

---

## INFORMATIONAL

### [I-1] Since the `PasswordStore:s_owner` doesn't have any way to change we can set it as an immutable, to save on gas when reading the variable.

**Description:** Since there is no way to change `PasswordStore::s_owner` we can use an `immutable` instead of a regular variable to save on gas.

**Impact:** Increased gas costs when reading the variable.

**Recommended Mitigation:** 

```diff
- address private s_owner;
+ address private immutable s_owner;
```

---

### [I-2] Typo on the event `PasswordStore::SetNetPassword`

**Description:** The event should be called `PasswordStore::SetNewPassword` instead of `PasswordStore::SetNetPassword`. This is to avoid confusion on what the event is about.

**Impact:** Possible confussion.

**Recommended Mitigation:** 

```diff
- event SetNetPassword();
+ event SetNewPassword();
```

---


### [I-3] Parameter Natspec not used in the function `PasswordStore::getPassword`, could lead to confusion amongts developers

**Description:** `newPassword` parameter is not used in the `PasswordStore::getPassword` function.

**Impact:** Possible confussion.

**Recommended Mitigation:** 
```diff
/*
 * @notice This allows only the owner to retrieve the password.
- * @param newPassword The new password to set.
*/
function getPassword() external view returns (string memory) {
    if (msg.sender != s_owner) {
        revert PasswordStore__NotOwner();
    }
    return s_password;
}
```