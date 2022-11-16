# Remote_Purchase_Contract

![Screenshot_207](https://user-images.githubusercontent.com/29931071/202180049-45b4f2b4-3d6e-4f24-8c48-3b065c5114b9.png)

![Screenshot_208](https://user-images.githubusercontent.com/29931071/202180284-6d2cc0f4-09fa-4b15-b24a-15ffa5a1cdc7.png)

![Screenshot_209](https://user-images.githubusercontent.com/29931071/202180452-4e4b2352-8340-4363-83d5-d98b168a3e26.png)


Now let's define our contract:

```
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

contract PurchaseAgreement {
    
}
```

Now we need to define our variables:

```
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

contract PurchaseAgreement {
    uint public value;
    address payable public seller;
    address payable public buyer;
}
```


Now we will use an enum to hold the state of our contract, and define a state variable for the enum:

```
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

contract PurchaseAgreement {
    uint public value;
    address payable public seller;
    address payable public buyer;

    enum State { Created, Locked, Release, Inactive }
    State public state;
}
```

Now let's define a constructor function,which will be a payable function.

```
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

contract PurchaseAgreement {
    uint public value;
    address payable public seller;
    address payable public buyer;

    enum State { Created, Locked, Release, Inactive }
    State public state;

    constructor() payable {
        seller = payable(msg.sender);
    }
}
```

Now let's create a function that allows a buyer be designated as a buyer,
then set the msg.sender to be the buyer,
then update the state
we need to make sure the buyer is sending the correct amount of money(twice the amount)
and check the state by creating a modifier(to revert the transaction if the condition isn't met).


```
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

contract PurchaseAgreement {
    uint public value;
    address payable public seller;
    address payable public buyer;

    enum State { Created, Locked, Release, Inactive }
    State public state;

    constructor() payable {
        seller = payable(msg.sender);
    }

    /// The function cannot be called at this state
    error InvalidState();

    modifier inState(State state_) {
        if(state != state_) {
            revert InvalidState();
        }
        _; //this executes the rest of the function
    }

    function confirmPurchase() external inState(State.Created) payable {
        require(msg.value == (2 * value), "Please send in 2x the purchase amount");
        buyer = payable(msg.sender);
        state = State.Locked;
    }
}
```



You can take your time to deploy and test the contract. 


Now let's set up a function that only a buyer can invoke once they've received the item.
Because of re-entrancy attacks,we'll update the state of the contract first.
This doesn't need to be payable because we're sending money not receiving.
We need to make sure only the buyer can invoke the function(set up a new modifier),and state is in Locked position(using state modifier).


```
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

contract PurchaseAgreement {
    uint public value;
    address payable public seller;
    address payable public buyer;

    enum State { Created, Locked, Release, Inactive }
    State public state;

    constructor() payable {
        seller = payable(msg.sender);
        value = msg.value / 2;
    }

    /// The function cannot be called at this state
    error InvalidState();

    modifier inState(State state_) {
        if(state != state_) {
            revert InvalidState();
        }
        _; //this executes the rest of the function
    }

    function confirmPurchase() external inState(State.Created) payable {
        require(msg.value == (2 * value), "Please send in 2x the purchase amount");
        buyer = payable(msg.sender);
        state = State.Locked;
    }

    ///Only a buyer can call this function
    error OnlyBuyer();

    modifier OnlyBuyerCan() {
        if (msg.sender != buyer) {
            revert OnlyBuyer();
        }
        _;
    }

    function confirmReceived() external OnlyBuyerCan inState(State.Locked) {
        state = State.Release;
        buyer.transfer(value);
    }
}
```

Now we will create a function to pay our seller once the conditions of the contract have been satisfied.
Only the seller is going to be able to invoke this function(so we'll need a modifier)
We'll check the state and make sure it's in release mode.
To prevent re-entrancy attacks, update state first.
