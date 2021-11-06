// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Counters.sol";

contract nft is ERC721Enumerable {
    using Counters for Counters.Counter;
    Counters.Counter private TokenIds;
    
    address public PlaceforAuction;

    struct nftBody{
        uint256 id;
        address creator;
        address owner;
        uint256 hash256;
    }
    mapping(uint256 => nftBody) public nftList;

    constructor() ERC721("nft","NFT") {}
    
    function mint(uint256 hash256) public returns (uint256){
        TokenIds.increment();
        uint256 newId = TokenIds.current();
        _safeMint(msg.sender,newId);

        nftList[newId] = nftbody({//构造
            id:newId,
            creator:msg.sender,
            owner:msg.sender,
            hash256:hash256
        });

        return newId;
    }

    function gethash(uint256 id) public view returns (uint256){
        require(_exists(id),"Id does not exit!");
        return nftList[id].hash256;
    }

    function initializeauction(address auction) public {
        PlaceforAuction = auction;
    }
}
