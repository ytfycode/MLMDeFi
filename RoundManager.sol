pragma solidity >=0.5.0 <0.6.0;

import "./Round.sol";
import "./InternalModule.sol";
import "./interface/change/ChangeInterface.sol";

contract RoundManager {

    Round[] public RoundHistory;
    Round public CurrenRound;
    address payable _contractOwner;

    DepositLimitInterface private _DInc;
    StatisticsInterface private _SInc;
    RecommendInterface private _RInc;
    LevelSubInterface private _LInc;
    TicketInterface private _TInc;
    ERC20Interface private _EInc;
    CostInterface private _CInc;

    TokenChangerInterface private _changeInc;


    uint256 private _staticProfix = 40;


    uint256 private _interestProfix = 18;

    modifier OwnerOnly {
        require(msg.sender == _contractOwner);
        _;
    }

    constructor(
        DepositLimitInterface dinc,
        RecommendInterface rinc,
        LevelSubInterface linc,
        TicketInterface tinc,
        ERC20Interface iinc,
        CostInterface cinc,
        StatisticsInterface sinc,
        uint256 s,
        uint256 i,
        TokenChangerInterface changeInc
    ) public {

        _changeInc = changeInc;
        _contractOwner = msg.sender;

        _DInc = dinc;
        _RInc = rinc;
        _LInc = linc;
        _TInc = tinc;
        _EInc = iinc;
        _CInc = cinc;
        _SInc = sinc;

        _staticProfix = s;
        _interestProfix = i;
    }

    function GetRoundHistoryAt( uint256 idx ) external view returns ( address addr ) {
        return address(RoundHistory[idx]);
    }


    function GetRoundTotal() external view returns (uint256) {
        return RoundHistory.length;
    }


    function Owner_StartNewRound() external OwnerOnly returns (bool) {


        if ( CurrenRound == Round(0x0) ) {
            CurrenRound = configNewRound();
            return true;

        } else if ( CurrenRound != Round(0x0) && !CurrenRound.isBroken() ) {

            return false;
        } else {
    
            RoundHistory.push(CurrenRound);
            CurrenRound = configNewRound();
            return true;
        }

    }

    function configNewRound() internal returns (Round newRound) {

        newRound = new Round( _DInc, _RInc, _LInc, _TInc, _EInc, _CInc, _SInc, _staticProfix, _interestProfix );

        InternalModule(address(_DInc)).AddAuthAddress(address(newRound));
        InternalModule(address(_RInc)).AddAuthAddress(address(newRound));
        InternalModule(address(_LInc)).AddAuthAddress(address(newRound));
        InternalModule(address(_TInc)).AddAuthAddress(address(newRound));
        InternalModule(address(_EInc)).AddAuthAddress(address(newRound));
        InternalModule(address(_CInc)).AddAuthAddress(address(newRound));
        InternalModule(address(_SInc)).AddAuthAddress(address(newRound));

    }
}
