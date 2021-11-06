// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "./NFT.sol";

contract NFT_Auction{

    //拍卖体结构
    struct auctionbody{
        address payable beneficiary;
        uint256 auctionID;
        uint256 tokenID;
        // 时间是unix的绝对时间戳（自1970-01-01以来的秒数）
        // 或以秒为单位的时间段。
        uint auctionEnd;
        
        uint firstprice; /* 起拍价格*/
        
        //拍卖的状态
        address highestBidder; /*截止时间*/
        uint highestBid;

        bool ended;
        bool bidded;
    }

    //可以取回的之前的出价
    mapping(address => uint) pendingreturns;

    auctionbody[] public auctionList;
    mapping(uint256 => bool) public activeitems;

    //拍卖变更触发的事件
    event AuctionAdded(uint256 id, uint256 tokenid,uint auctionend,uint firstprice);
    event HighestBidIncreased(uint256 id, address bidder, uint amount);
    event AuctionEnded(uint256 id, address winner, uint amount);

    constructor(nft _nftset) {
        nftset = _nftset;
    }

    modifier UniqueOwner(uint256 tokenid){
        require(nftset.ownerOf(tokenid) == msg.sender, 
        "Invalid NFT item owner.");
        _;
    }
    modifier BeTransferApproved(uint256 tokenid) {
        require(nftset.getApproved(tokenid) == msg.sender,
        "Not approved NFT auction.");
        _;
    }
    modifier ItemExist(uint256 id){
        require(id < auctionList.length, 
        "Fail to find NFT item.");
        _;
    }
    modifier BeActive(uint256 id){
        require(block.timestamp <= auctionList[id].auctionEnd,
        "NFT auction already finished.");
        _;
    }
    modifier BeNotFinished(uint256 id){
        require(!auctionList[id].ended, 
        "NFT auction already finished.");
        _;
    }
    modifier CanClaim(uint256 id){
        require(auctionList[id].bidded && auctionList[id].ended && auctionList[id].highestbidder == msg.sender, 
        "Invalid NFT item claimer.");
        _;
    }
    //创建拍卖
    function CreateAuction(uint256 Tokenid, uint Biddingspan, uint Firstprice)
        UniqueOwner(Tokenid)
        external
        returns (uint256){
            require(!activeitems[Tokenid],
            "Auctioned NFT item.");
            uint256 newid = auctionList.length;
            auctionList.push(auctionbody({
                auctionID:newid,
                beneficiary:payable(msg.sender),
                tokenID:Tokenid,
                auctionEnd:block.timestamp + Biddingspan,
                firstprice:Firstprice,
                highestbidder:msg.sender,
                highestprice:0,
                ended:false,
                bidded:false
            }));
            activeitems[Tokenid] = true;

            assert(auctionList[newid].auctionID == newid);
            emit AuctionAdded(newid,Tokenid,block.timestamp + Biddingspan, Firstprice);
            return newid;
        }
    //参与拍卖
    function bid(uint256 id)
        ItemExist(id)
        BeNotFinished(id)
        BeActive(id)
        payable
        external
        {
            require(msg.value >= auctionList[id].firstprice,
            "Insufficient balance to join the auction.");
            require(msg.value > auctionList[id].highestprice, 
            "Insufficient balance to get highest bid.");
            require(msg.sender != auctionList[id].beneficiary, 
            "Can not bid in your own auction.");

            if (auctionList[id].highestprice != 0 )
            {
                pendingreturns[auctionList[id].highestbidder] += auctionList[id].highestprice;
            }
            auctionList[id].highestbidder = msg.sender;
            auctionList[id].highestprice = msg.value;
            if (!auctionList[id].bidded)
            {
                auctionList[id].bidded = true;
            }
            emit HighestBidIncreased(id, msg.sender, msg.value);
        }

        function withdraw()
        external
        returns (bool){
            require(pendingreturns[msg.sender] > 0, 
            "No bid to withdraw.");
            uint amount = pendingreturns[msg.sender];

            pendingreturns[msg.sender] = 0;

            if (!msg.sender.send(amount))
            {
                pendingreturns[msg.sender] = amount;
                return false;
            }
            return true;
        }
    function EndAuction(uint256 id)
    ItemExist(id)
    BeNotFinished(id)
    external{
        require(block.timestamp >= auctionList[id].auctionEnd, 
        "No ending time.");
        auctionList[id].ended = true;
        activeitems[auctionitem[id].tokenID] = false;
        nftset.approve(auctionList[id].highestbidder, id);
    }
    function claim(uint256 id)
    ItemExist(id)
    CanClaim(id)
    BeTransferApproved(auctionitem[id].tokenid)
    external{
        auctionList[id].bidded = false;
        nftset.safeTransferFrom(auctionList[id].beneficiary, msg.sender, auctionList[id].tokenID);
        emit AuctionEnded(id, auctionList[id].highestbidder, auctionitem[id].highestprice); 
    }
    function totalAuction() external view returns(uint256){
        return auctionList.length;
    }
}