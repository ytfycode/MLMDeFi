pragma solidity >=0.5.0 <0.6.0;

import "./InternalModule.sol";
import "./interface/ticket/TicketInterface.sol";
import "./interface/recommend/RecommendInterface.sol";
import "./interface/token/ERC20Interface.sol";
import "./interface/statistics/StatisticsInterface.sol";
import "./interface/round/RoundInterface.sol";

contract Ticket is TicketInterface, InternalModule {

    uint256 public ticketPrice = 60000000000000000000;

    mapping( address => bool ) private _paymentTicketAddrMapping;

    mapping( address => uint256 ) private _latestDyProfitTime;

    mapping( address => uint256 ) private _latestSettTime;

    mapping( address => uint256 ) private _latestJoinTime;

    mapping( address => bool ) private _needClearHistory;

    uint256 public _dyPropExpTime = 180 days;

    uint256 public _reJoinExpTime = 7 days;

    RecommendInterface private _RInc;
    ERC20Interface private _TInc;
    StatisticsInterface private _SInc;
    RoundInterface private _CRInc;

    constructor( RecommendInterface rinc, ERC20Interface tinc, StatisticsInterface sinc ) public {
        _RInc = rinc;
        _TInc = tinc;
        _SInc = sinc;
    }

    function RePaymentTicket() external {

        require(_latestSettTime[msg.sender] != 0);

        internalPaymentTicket(msg.sender);

        _CRInc.API_RepaymentTicketDelegate(msg.sender);
    }

    function internalPaymentTicket( address owner ) internal {

        require( ticketIsVaild(owner) == false, "ERR_01" );
        require( _TInc.balanceOf(owner) >= ticketPrice, "ERR_02");

        _TInc.API_MoveToken( owner, address(0x0), ticketPrice );
        _SInc.API_AddActivate();

        _latestDyProfitTime[msg.sender] = now;
        _latestSettTime[msg.sender] = now;
        _latestJoinTime[msg.sender] = now;

        _paymentTicketAddrMapping[msg.sender] = true;
    }

    function ticketIsVaild( address ownerAddr ) internal view returns (bool) {

        /// Have not purchased tickets yet, return directly without tickets
        if ( !_paymentTicketAddrMapping[ownerAddr] ) {
            return false;
        }

        /// 1.If the ticket has already been purchased, but the last time the dynamic income was generated but the time has exceeded 180 days, the ticket will be invalid.
        if ( now - _latestDyProfitTime[ownerAddr] > _dyPropExpTime ) {
            return false;
        }

        /// 2.If the ticket has already been purchased, but after the last settlement, the current time has exceeded 7 days, the ticket is invalid.
        if ( _latestJoinTime[ownerAddr] > _latestSettTime[ownerAddr] ) {

            /// If the last investment but the time is greater than the last settlement time, it means that the corresponding address is in one round and has not been settled.
            return true;

        } else if ( _latestJoinTime[ownerAddr] < _latestSettTime[ownerAddr] ) {

            /// If the last investment time is less than the last settlement time, it means that the user is not currently in the round, that is, there is no re-investment.
            /// Under current conditions, if the current time is more than 7 days from the last settlement time, it is considered invalid.
            if ( now - _latestSettTime[ownerAddr] > _reJoinExpTime ) {
                return false;
            }
        }
        // This also contains a condition for _latestJoinTime[ownerAddr] == _latestSettTime[ownerAddr]
        // According to the rules, except for the first purchase of tickets, this set of data cannot be generated, so it is directly used as a valid ticket.
        // else {
        //  .....
        // }

        return true;
    }

    // Get the ticket information of the corresponding address. Has indicated whether there is a ticket, vaild indicates whether the ticket is valid.
    function HasTicket( address ownerAddr ) external view returns (bool has, bool isVaild) {
        return (_paymentTicketAddrMapping[ownerAddr], ticketIsVaild(ownerAddr) );
    }

    function ActivateAddress( address recommAddr, bytes6 shortCode ) external {

        internalPaymentTicket( msg.sender );

        _RInc.API_BindEx(msg.sender, recommAddr, shortCode);

        return;
    }

    function PaymentTicket() external {
        require( _RInc.AddressToShortCode(msg.sender) != bytes6(0x000000000000) );
        internalPaymentTicket( msg.sender );
    }

    function API_NeedClearHistory( address owner ) external APIMethod returns (bool) {

        /// 当支付门票后标记为需要重置资产，返回这个结果后马上设置为false
        if ( _needClearHistory[owner] ) {
            _needClearHistory[owner] = false;
            return true;
        }

        return false;
    }

    function API_UpdateLatestDyProfitTime( address owner ) external APIMethod {
        _latestDyProfitTime[owner] = now;
    }

    function API_UpdateLatestSettTime( address owner ) external APIMethod {
        _latestSettTime[owner] = now;
    }

    function API_UpdateLatestJoinTime( address owner ) external APIMethod {
        _latestJoinTime[owner] = now;
    }
    
}
