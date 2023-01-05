// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

struct OrderType {
        address strategy;
        address seller;
        address nft;
        address payment;
        uint tokenId;
        uint amount;
        uint price;
        uint endAt;
}