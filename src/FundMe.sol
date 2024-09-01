// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

error FundMe_NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    address public immutable i_owner;
    uint256 public constant MINIMUM_USD = 5e18;
    AggregatorV3Interface private s_dataFeed;

    address[] public s_funders;
    mapping(address funder => uint256 amountFunded) private s_addressToAmountFunded;    

    constructor(address dataFeed){
        i_owner = msg.sender;
        s_dataFeed = AggregatorV3Interface(dataFeed);
    }

    function fund() public payable{
        require(msg.value.getConversionRate(s_dataFeed) >= MINIMUM_USD, "Didn't send enough ETH!!");
        
        s_addressToAmountFunded[msg.sender] += msg.value; // Use shorthand for clarity
        s_funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256){
         
         return s_dataFeed.version();
    }

    function cheaperWithdraw() public onlyOwner{
        uint256 fundersLength = s_funders.length;
        for(uint256 funderIndex = 0; funderIndex < fundersLength; funderIndex++){
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    function withdraw() public onlyOwner {
        
        for(uint256 funderIndex = 0; funderIndex < s_funders.length; funderIndex++){
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        // Reset the array
        s_funders = new address[](0) ;
        // Actually withdraw the funds

        // Transfer
        // payable(msg.sender).transfer(address(this).balance);
        // Send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");
        // Call
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }
    
    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Sender is not an owner");
        if(msg.sender != i_owner){
            revert FundMe_NotOwner();
        }
        _;
    }
    
    receive() external payable {
        fund();
    }
    
    fallback() external payable {
        fund();
    }

    function getAddressToAmountFunded(address fundingAddress) external view returns (uint256){
        return s_addressToAmountFunded[fundingAddress];
    }
    
    function getFunder(uint256 index) external view returns (address) {
        return s_funders[index]; // Fixed syntax for array access
    }
    function getOwner() public view returns (address) {
        return i_owner;
    }

}
