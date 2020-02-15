pragma solidity >=0.5.0 <0.6.0;

import "./InternalModule.sol";
import "./interface/depositlimit/DepositLimitInterface.sol";
import "./interface/recommend/RecommendInterface.sol";
import "./interface/levelsub/LevelSubInterface.sol";
import "./interface/ticket/TicketInterface.sol";
import "./interface/round/RoundInterface.sol";
import "./interface/token/ERC20Interface.sol";
import "./interface/cost/CostInterface.sol";
import "./interface/statistics/StatisticsInterface.sol";
import "./interface/luckassetspool/LuckAssetsPoolInterface.sol";
import "./interface/redress/RedressInterface.sol";

/*
Error definition
DAO_Warning : The corresponding address uses the attack contract to try DAO attack at the time of settlement.
E01 : The user is not bound before the user tries to start a new round
E02 : The user did not pay the ticket when the user tried to start a new round, or the ticket has expired
E03 : There are still unfinished or unsettled rounds when the user tries to start a new round
E04 : The amount the user is trying to participate in is greater than the limit amount.
E05 : There are no rounds in progress when the user tries to settle the round
E06 : When the user tries to settle the round, the current round has not yet reached the time that can be settled.
E07 : When the user starts a new round, the input is less than 1 ether, which is less than the minimum input limit.
E08 : ERC20Token balance is insufficient to pay the commission when the user settles the proceeds
E09 : The user who tries to receive compensation, the corresponding user's total participation amount is less than the earned amount, no compensation
E10: The user tries to receive compensation again after the compensation has been extracted.
E11: When extracting dynamic income, the extractable amount of the corresponding address is insufficient
E12: When extracting dynamic revenue, the number of ethers attempted to extract is less than the minimum extraction limit
*/

contract Round is RoundInterface, InternalModule {


    /// Join this gams
    function Join() external payable OnlyInPlaying {

        require( _RecommendInc.GetIntroducer(msg.sender) != address(0x0), "E01" );

        bool ticketIsVaild = false;
        (  , ticketIsVaild ) = _TicketInc.HasTicket(msg.sender);
        require( ticketIsVaild, "E02" );

        require( _depositMapping[msg.sender].startTime == 0, "E03");

        require( _depositMapping[msg.sender].joinEther + msg.value <= _DepositLimitInc.DepositLimitOf(msg.sender), "E04" );

        require( _DepositLimitInc.SurplusDepositLimitAll() >= msg.value );
        _DepositLimitInc.API_AddDepositLimitAll( msg.value );

        uint256 minLimit = _joinMinLimit;
        if ( _depositMapping[msg.sender].joinEther > 0 ) {

            uint256 latestWithDrawProfix = ((((_depositMapping[msg.sender].joinEther / (100 - _staticProfix)) * 100) * _staticProfix) / 100);

            latestWithDrawProfix = (latestWithDrawProfix * 70) / 100;

            minLimit = latestWithDrawProfix > _joinMinLimit ? latestWithDrawProfix : _joinMinLimit;
        }

        require( msg.value >= minLimit, "E07" );

        if ( _depositMapping[msg.sender].endTime == 0 ) {
            _depositMapping[msg.sender] = Deposited(now, now + _everRoundTime, msg.value, false);
        } else {
            _depositMapping[msg.sender].startTime = now;
            _depositMapping[msg.sender].endTime = now + _everRoundTime;
            _depositMapping[msg.sender].joinEther += msg.value;
        }

        _RecommendInc.API_MarkValid(msg.sender, msg.value);

        totalEther += msg.value;

        _StatisticsInc.API_NewJoin( msg.sender, now, _depositMapping[msg.sender].joinEther );
        _StatisticsInc.API_NewPlayer( msg.sender );
        _inEtherMapping[msg.sender] += msg.value;

        address payable lpiaddr = address( uint160( address(_LuckPoolInc) ) );
        lpiaddr.transfer( (msg.value * _LuckPoolInc.InPoolProp()) / 100 );

        _LuckPoolInc.API_AddLatestAddress( msg.sender, msg.value );

        _TicketInc.API_UpdateLatestJoinTime(msg.sender);

        emit Event_NewDepositJoined( msg.sender, msg.value, _depositMapping[msg.sender].joinEther );
    }

    function GetCurrentRoundInfo( address owner ) external view returns
    (
        uint256 stime,
        uint256 etime,
        uint256 value,
        bool redressable
    ) {

        Deposited memory record = _depositMapping[owner];

        return (record.startTime, record.endTime, record.joinEther, record.redressable);
    }

    function Settlement() external OnlyInPlaying {
        // ....
        // To prevent the contract from being copied, we have hidden this part of the
        // source code, which will be published later.
        // 
        // but about the funds can be queried,analyzed, and verified by the block browser.
        //
    }

    function TotalInOutAmount() external view returns (uint256 inEther, uint256 outEther) {
        return (_inEtherMapping[msg.sender], _outEtherMapping[msg.sender]);
    }

    function GetRedressInfo() external view OnlyInBrokened returns (uint256 total, bool withdrawable) {

        if ( _outEtherMapping[msg.sender] >= _inEtherMapping[msg.sender] ) {
            return (0, false);
        }

        uint256 mulEther = _inEtherMapping[msg.sender] - _outEtherMapping[msg.sender];

        uint256 redtotal = (mulEther * _beforBrokenedCostProp / 1 ether);

        return (redtotal, _depositMapping[msg.sender].redressable);
    }

    function DrawRedress() external OnlyInBrokened returns (bool) {

        if ( _outEtherMapping[msg.sender] >= _inEtherMapping[msg.sender] ) {
            return false;
        }

        if ( !_depositMapping[msg.sender].redressable ) {

            _depositMapping[msg.sender].redressable = true;

            // There is compensation, but the first extraction has not yet taken place. The first extraction time should be after 0:00 the next day after the crash.
            uint256 mulEther = _inEtherMapping[msg.sender] - _outEtherMapping[msg.sender];

            uint256 redtotal = (mulEther * _beforBrokenedCostProp / 1 ether);

            // add redress record
            _RedressInc.API_AddRedress(msg.sender, redtotal);

            return true;
        }

        return false;
    }

    function DynamicAmountOf( address owner ) external view returns (uint256) {
        return _withdrawQuotaMapping[owner];
    }

    function WithdrawDynamic() external OnlyInPlaying returns (bool) {

        require( _withdrawQuotaMapping[msg.sender] >= _withdrawQuotaMinLimit, "E11");
        // require( value > _withdrawQuotaMinLimit, "E12" );

        uint256 value = _withdrawQuotaMapping[msg.sender];

        uint256 size;
        address payable safeAddr = msg.sender;
        assembly { size := extcodesize(safeAddr) }
        require( size == 0, "DAO_Warning" );

        uint256 cost = _CostInc.WithdrawCost( value );

        require( _ERC20Inc.balanceOf(msg.sender) >= cost, "E08" );

        _ERC20Inc.API_MoveToken( msg.sender, address(0x0), cost );

        _withdrawQuotaMapping[msg.sender] = 0;

        if ( address(this).balance < value ) {

            _StatisticsInc.API_AddDynamicTotalAmount( msg.sender, address(this).balance );
            _outEtherMapping[safeAddr] += address(this).balance;

            safeAddr.transfer(address(this).balance);
            isBroken = true;
            _beforBrokenedCostProp = _CostInc.CurrentCostProp();
            _LuckPoolInc.API_WinningThePrize();
            return false;
        }

        /// transfer
        safeAddr.transfer( value );
        totalWithdraw += value;

        _StatisticsInc.API_AddDynamicTotalAmount( msg.sender, value );
        _outEtherMapping[safeAddr] += value;

        _TicketInc.API_UpdateLatestDyProfitTime( msg.sender );

        return true;
    }

    function API_RepaymentTicketDelegate( address owner ) external OnlyInPlaying APIMethod {

        if ( _depositMapping[owner].startTime != 0 || _depositMapping[owner].endTime != 0 || _depositMapping[owner].joinEther > 0 ) {
            _depositMapping[owner].startTime = 0;
            _depositMapping[owner].endTime = 0;
            _depositMapping[owner].joinEther = 0;
        }

    }

    function () payable OnlyInPlaying external {
        totalEther += msg.value;
    }
}
