pragma solidity >=0.5.0 <0.6.0;

import "./InternalModule.sol";
import "./interface/token/ERC20Interface.sol";
import "./interface/change/ChangeInterface.sol";

contract TokenChanger is TokenChangerInterface, InternalModule {

    struct ChangeRound {
        uint8   roundID;
        uint256 totalToken;     // Current round loop token total
        uint256 propETH;        // The number of current round 1 ETH convertible tokens
        uint256 changed;        // Converted quantity
    }

    ChangeRound[] _rounds;
    ERC20Interface _ERC20Inc;

    uint8 public CurrIdX = 0;

    uint256 public _changeMinLimit = 10000000000000000;

    event Event_ChangedToken(address indexed owner, uint8 indexed round, uint256 indexed value);

    address payable private _ownerAddress;

    constructor(ERC20Interface erc20inc) public {

        _ownerAddress = msg.sender;
        _ERC20Inc = erc20inc;

        _rounds.push( ChangeRound(7, 10000000000000000000000000, 1000000000000000000000, 0) );
    }

    function ChangeRoundAt(uint8 rid) external view returns (uint8 roundID, uint256 total, uint256 prop, uint256 changed) {

        require( rid < _rounds.length, "TC_ERR_004" );

        return (
        _rounds[rid].roundID,
        _rounds[rid].totalToken,
        _rounds[rid].propETH,
        _rounds[rid].changed);
    }

    function CurrentRound() external view returns (uint8 roundID, uint256 total, uint256 prop, uint256 changed) {

        if ( CurrIdX >= _rounds.length ) {
            return (0, 0, 0, 0);
        }

        return (
        _rounds[CurrIdX].roundID,
        _rounds[CurrIdX].totalToken,
        _rounds[CurrIdX].propETH,
        _rounds[CurrIdX].changed);

    }

    function RoundCount() external view returns (uint256) {
        return _rounds.length;
    }

    function DoChangeToken() external payable {

        require( msg.value >= _changeMinLimit, "TC_ERR_001" );
        require( msg.value % _changeMinLimit == 0, "TC_ERR_002" );
        require( CurrIdX < _rounds.length, "TC_ERR_006");
        // require( _roundContractAddress != address(0x0), "TC_ERR_005" );
        ChangeRound storage currRound = _rounds[CurrIdX];

        uint256 minLimitProp = currRound.propETH / ( 1 ether / _changeMinLimit );
        uint256 ctoken = (msg.value / _changeMinLimit) * minLimitProp;

        require ( currRound.changed + ctoken <= currRound.totalToken, "TC_ERR_003" );

        // _ERC20Inc.transfer( msg.sender, ctoken );
        _ERC20Inc.API_MoveToken( address(_ERC20Inc), msg.sender, ctoken );
        _ownerAddress.transfer( address(this).balance );

        emit Event_ChangedToken( msg.sender, CurrIdX, msg.value );

        if ( (currRound.changed + ctoken + minLimitProp) >= currRound.totalToken ) {
            CurrIdX++;
        }

        currRound.changed += ctoken;
    }
}
