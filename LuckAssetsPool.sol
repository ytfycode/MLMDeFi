pragma solidity >=0.5.0 <0.6.0;

import "./InternalModule.sol";
import "./interface/luckassetspool/LuckAssetsPoolInterface.sol";

contract LuckAssetsPool is LuckAssetsPoolInterface, InternalModule {

    struct Invest {

        address who;

        uint256 when;

        uint256 amount;

        bool rewardable;
    }

    // Distribution ratio (%)
    uint256 public _inPoolProp = 10;

    // Invest history
    Invest[] public _investList;

    uint256 public rewardsCount = 500;

    // Default reward base
    uint256 public defualtProp = 3;

    // Reward for special rankings, using the last digit x, subscript 0 is the first reciprocal multiple
    mapping(uint256 => uint256) public specialRewardsDescMapping;

    // Record the number of ether that can be extracted from the corresponding address
    mapping(address => uint256) public rewardsAmountMapping;

    constructor() public {
        specialRewardsDescMapping[0] = 10;
        specialRewardsDescMapping[1] = 5;
        specialRewardsDescMapping[2] = 5;
        specialRewardsDescMapping[3] = 5;
        specialRewardsDescMapping[4] = 5;
        specialRewardsDescMapping[5] = 5;
    }

    /// get my reward prices
    function RewardsAmount() external view returns (uint256) {
        return rewardsAmountMapping[msg.sender];
    }

    /// withdraw my all rewards
    function WithdrawRewards() external returns (uint256) {

        require( rewardsAmountMapping[msg.sender] > 0, "No Rewards" );

        uint256 size;
        address payable safeAddr = msg.sender;
        assembly { size := extcodesize(safeAddr) }
        require( size == 0, "DAO_Warning" );

        uint256 amount = rewardsAmountMapping[msg.sender];
        rewardsAmountMapping[msg.sender] = 0;
        safeAddr.transfer( amount );

        return amount;
    }

    function InPoolProp() external view returns (uint256) {
        return _inPoolProp;
    }

    function API_AddLatestAddress( address owner, uint256 amount ) external APIMethod {
        _investList.push( Invest(owner, now, amount, false) );
    }

    function API_WinningThePrize() external APIMethod {

        uint256 contractBalance = address(this).balance;

        for ( uint256 i = (_investList.length - 1); !( i <= 1 || i <= (_investList.length - rewardsCount) ); i = (i - 1) ) {

            uint256 descIndex = (_investList.length - i) - 1;

            Invest storage invest = _investList[i];

            if ( invest.rewardable ) {
                continue;
            }

            invest.rewardable = true;

            uint256 rewardMul = specialRewardsDescMapping[descIndex];
            if ( rewardMul == 0 ) {
                rewardMul = defualtProp;
            }

            uint256 rewardAmount = invest.amount * rewardMul;

            if ( rewardAmount < contractBalance ) {

                rewardsAmountMapping[ invest.who ] = rewardAmount;
                contractBalance -= rewardAmount;

            } else {

                rewardsAmountMapping[ invest.who ] = contractBalance;
                break;

            }
        }

    }

    function () payable external {

    }
}
