// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "November/crowdfund.sol";

contract tech4dev{

    event Launch(
        uint id,
        address indexed creator, 
        uint goal, 
        uint32 startAt, 
        uint32 endAt
        );

    event Cancel(
        uint id
        );

    event Pledge(
        uint indexed id,
        address indexed caller,
        uint amount
    );

    event Unpledge(
         uint indexed id,
         address indexed caller,
         uint amount
    );

    event Claim(
        uint indexed id
    );

    event Refund(
        uint id,
        address indexed caller,
        uint amount
    );

    struct Campaign{
       address creator;
       uint goal;
       uint pledged;
       uint32 startAt;
       uint32 endAt;
       bool claimed;
    }

    IERC20 public immutable token; //reference to the token

    uint public count;
 
    mapping(uint => Campaign) public campaigns;//mapping i.d to our struct
    mapping(uint => mapping(address => uint)) public PledgedAmount;//mapping the id of the campaign with the mapping of the person trying to pledge. i.e address and amount

    constructor(address _token){
        token = IERC20(_token);
    }

    function launch(uint _goal, uint32 startAt_, uint32 endAt_) external{
        require(startAt_ >= block.timestamp, "startAt < now");
        require(endAt_ >= startAt_, "endAt < startAt");
        require(endAt_ <= block.timestamp + 90 days, "endAt > max duration");

        count += 1;

        campaigns[count]= Campaign(msg.sender, _goal, 0, startAt_, endAt_, false );
    emit Launch(count, msg.sender, _goal, startAt_, endAt_);
    }

    function cancel(uint _id)external{
      Campaign memory campaign = campaigns[_id]; //this line of code gives access to the struct
      require(campaign.creator == msg.sender, "you are not the creator");
      require(block.timestamp < campaign.startAt , "The campaign has started");

      delete campaigns[_id];

      emit Cancel(_id);
    }

    function pledge (uint _id, uint _amount)external{
      Campaign storage campaign = campaigns[_id];
      require(block.timestamp >= campaign.startAt ,"Campaign has not started");
      require(block.timestamp <= campaign.endAt, "Campaign has ended");

      campaign.pledged += _amount;
      PledgedAmount[_id][msg.sender] += _amount;
      token.transferFrom(msg.sender,address(this), _amount);

      emit Pledge(_id, msg.sender, _amount);
}

    function unpledge(uint _id, uint _amount) external{
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp<= campaign.endAt, "Campaign has ended");
        campaign.pledged -= _amount;
        PledgedAmount[_id][msg.sender] -= _amount;
        token.transfer(msg.sender, _amount);

        emit Unpledge(_id, msg.sender, _amount);

    }

    function claim(uint _id) external{
        Campaign storage campaign = campaigns[_id];
        require(campaign.creator == msg.sender, "you are not the owner");
        require(block.timestamp > campaign.endAt, "Campaign has not ended");
        require(campaign.pledged >= campaign.goal, "Campaign is less than goal");
        require(!campaign.claimed, "Campaign has been claimed");

        campaign.claimed= true;
        token.transfer(campaign.creator, campaign.pledged);

        emit Claim(_id);
    }

    function refund(uint _id) external{
        Campaign memory campaign= campaigns[_id];
        require(block.timestamp > campaign.endAt, "Campaign has not ended");
        require(campaign.pledged < campaign.goal, "pledged is less than goal");

        uint bal = PledgedAmount[_id][msg.sender];
        PledgedAmount[_id][msg.sender]= 0;
        token.transfer(msg.sender,bal);

        emit Refund(_id, msg.sender, bal);
    }
}