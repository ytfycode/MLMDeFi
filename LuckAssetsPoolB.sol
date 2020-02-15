pragma solidity >=0.5.0 <0.6.0;

import "./InternalModule.sol";
import "./interface/luckassetspool/LuckAssetsPoolInterface.sol";
import "./interface/lib_math.sol";

contract LuckAssetsPoolB is LuckAssetsPoolInterface, InternalModule {

    struct Invest {

        address who;

        uint256 when;

        uint256 amount;
    }

    uint256 public _nextWinningThePrizeTime;

    uint256 public _inPoolProp = 3;

    uint256 public _activityMinLimit = 20 ether;

    uint256 public _rewardsCount = 5;

    mapping(uint256 => Invest[]) public _rewardsAmountMapping;

    mapping(address => uint256) public _sumInAmountMapping;

    address payable ownerAddress;

    constructor() public {
        ownerAddress = msg.sender;
        _managerAddress = msg.sender;
        _nextWinningThePrizeTime = lib_math.CurrentDayzeroTime() + lib_math.OneDay();
    }

    ///Distribution proportion of lucky pool
    function InPoolProp() external view returns (uint256) {
        return _inPoolProp;
    }

    function API_AddLatestAddress( address owner, uint256 amount ) external APIMethod returns (bool openable) {

        if ( now > _nextWinningThePrizeTime ) {
            WinningThePrize();
            openable = true;
        }

        _sumInAmountMapping[owner] += amount;

        if ( amount >= _activityMinLimit ) {

            _rewardsAmountMapping[_nextWinningThePrizeTime].push( Invest(owner, now, amount) );

            _sumInAmountMapping[owner] = 0;
        }

        openable = false;
    }

    function WinningThePrize() internal {

        uint256 contractBalance = address(this).balance;

        Invest[] memory list = _rewardsAmountMapping[_nextWinningThePrizeTime];

        if ( list.length <= 0 ) {
            _nextWinningThePrizeTime = lib_math.CurrentDayzeroTime() + lib_math.OneDay();
            return;
        }

        uint256 everRed = contractBalance / _rewardsCount;
        if ( list.length > _rewardsCount ) {

            for (uint256 i = 0; i < _rewardsCount; i++) {
                address payable paddr = address( uint160( address(list[(now >> i) % list.length].who) ) );
                paddr.transfer(everRed);
                emit Log_Winner(paddr, now, everRed);
            }

        } else {

            everRed = contractBalance / list.length;
            for (uint256 i = 0; i < list.length; i++) {
                address payable paddr = address( uint160( address(list[i].who) ) );
                paddr.transfer(everRed);
                emit Log_Winner(paddr, now, everRed);
            }

        }

        _nextWinningThePrizeTime = lib_math.CurrentDayzeroTime() + lib_math.OneDay();
    }

    function API_GameOver() external APIMethod returns (bool) {
        ownerAddress.transfer( address(this).balance );
    }

    
    function Owner_SetInPoolProp(uint256 p) external OwnerOnly {
        _inPoolProp = p;
    }

    function Owner_SetActivityMinLimit(uint256 p) external OwnerOnly {
        _activityMinLimit = p;
    }

    function () payable external {

    }

    function RewardsAmount() external view returns (uint256) {
        return 0;
    }
    function WithdrawRewards() external returns (uint256) {
        return 0;
    }
    function NeedPauseGame() external view returns (bool) {
        return false;
    }
    function API_Reboot() external returns (bool) {
        return false;
    }
}
