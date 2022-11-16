// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

contract PurchaseAgreement {
    uint public value;
    address payable public seller;
    address payable public buyer;

    enum State { Created, Locked, Release, Inactive, Returned }
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

    ///Only a seller can call this function
    error OnlySeller();

    modifier OnlySellerCan() {
        if (msg.sender != seller) {
            revert OnlySeller();
        }
        _;
    }

    function paySeller() external OnlySellerCan inState(State.Release) {
        state = State.Inactive;

        seller.transfer(value);
    }

    function abort() external OnlySellerCan inState(State.Inactive) {
        state = State.Returned;
        seller.transfer(address(this).balance);
    }
}
