// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "./interfaces/IStrategyTrade.sol";
import "./interfaces/IStrategyConfig.sol";
interface IERC721 {
    function safeTransferFrom(
        address from,
        address to,
        uint tokenId
    ) external;

    function transferFrom(
        address,
        address,
        uint
    ) external;
}

abstract contract EnglishAuction is IStrategyTrade{

    IStrategyConfig StrategyConfig;

    uint public fee = StrategyConfig.getFee();
    address public vaultAddr = StrategyConfig.getVaultAddr();
    address public ordersAddr = StrategyConfig.getOrdersAddr();
    address public proxyAddr = StrategyConfig.getProxyAddr();

    modifier  onlyProxy {
        require(msg.sender == StrategyConfig.getProxyAddr());
        _;
    }

    //

    event Start();
    event Bid(address indexed sender, uint amount);
    event Withdraw(address indexed bidder, uint amount);
    event End(address winner, uint amount);

    IERC721 public nft;
    uint public nftId;

    address payable public seller;
    uint public endAt;
    bool public started;
    bool public ended;

    address public highestBidder;
    uint public highestBid;
    mapping(address => uint) public bids;

    mapping (uint=>mapping(address => uint)) buyerBid;//order id to buyer to buyer's bid $;


    address public owner = 0xaa8De4b0103b38e536Cac709BCFB1e1580B5B282;


    constructor(
        address _nft,
        uint _nftId,
        uint _startingBid,
        IStrategyConfig _StrategyConfig
    ) {
        nft = IERC721(_nft);
        nftId = _nftId;

        seller = payable(msg.sender);
         StrategyConfig = _StrategyConfig;
        highestBid = _startingBid;
    }

    function addOrder() external {
        require(!started, "started");
        require(msg.sender == seller, "not seller");

        nft.transferFrom(msg.sender, address(this), nftId);
        started = true;
        endAt = block.timestamp + 7 days;

        emit Start();
    }

    function bid() external payable {
        require(started, "not started");
        require(block.timestamp < endAt, "ended");
        require(msg.value > highestBid, "value < highest");

        if (highestBidder != address(0)) {
            bids[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;

        emit Bid(msg.sender, msg.value);

        //  OrderType memory _Order = IOrder(_strategy).getOrder(_orderId);
        // IVault(vaultAddr).receiver(_Order.payment,_amount);
        // buyerBid[_orderId][_msgSender()] += _amount;
    }

    function withdraw() external {
        uint bal = bids[msg.sender];
        bids[msg.sender] = 0;
        payable(msg.sender).transfer(bal);

        emit Withdraw(msg.sender, bal);
        
        // OrderType memory _Order = IOrder(_strategy).getOrder(_orderId);

        // uint balance = buyerBid[_orderId][_msgSender()];
        // IVault(vaultAddr).withdraw(_Order.payment,balance);
        // buyerBid[_orderId][_msgSender()] = 0;
    }

    function end() external {
        require(started, "not started");
        require(block.timestamp >= endAt, "not ended");
        require(!ended, "ended");

        ended = true;
        if (highestBidder != address(0)) {
            nft.safeTransferFrom(address(this), highestBidder, nftId);
            seller.transfer(highestBid);
        } else {
            nft.safeTransferFrom(address(this), seller, nftId);
        }

        emit End(highestBidder, highestBid);
    }

    function cancel()external{
        //check role if role is buyer. so this action is cancal order.else this action is cancel bid.
    }
}
