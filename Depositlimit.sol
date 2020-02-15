pragma solidity >=0.5.0 <0.6.0;

import "./interface/depositlimit/DepositLimitInterface.sol";
import "./InternalModule.sol";

contract DepositLimit is DepositLimitInterface,InternalModule {

    mapping (address => uint256) _limitMapping;

    uint256 private _defaultLimit = 20 ether;

    /// All network daily investment limit
    uint256 public _investEverDayMaxLimit = 1000 ether;

    /// Last quota reset time
    uint256 public _investEverDayUTime = 0;

    /// The amount accumulated since the last reset
    uint256 public _investEverDayTotal = 0;

    constructor(uint256 defaultlimit) public {
        _defaultLimit = defaultlimit;
    }

    function API_AddDepositLimit( address ownerAddr, uint256 value, uint256 maxlimit ) external APIMethod {

        if ( _limitMapping[ownerAddr] == 0 ) {
            _limitMapping[ownerAddr] = _defaultLimit;
        }

        if ( _limitMapping[ownerAddr] + value > maxlimit ) {

            _limitMapping[ownerAddr] = maxlimit;

        } else {

            _limitMapping[ownerAddr] += value;

        }
    }

    function DepositLimitOf( address ownerAddr ) external view returns (uint256) {

        if ( _limitMapping[ownerAddr] == 0 ) {
            return _defaultLimit;
        }

        return _limitMapping[ownerAddr];
    }

    function API_AddDepositLimitAll( uint256 value ) external APIMethod  {

        if ( now - _investEverDayUTime > 1 days ) {

            _investEverDayUTime = ( now / 1 days ) * 1 days;
            _investEverDayTotal = value;

        } else {

            require( _investEverDayMaxLimit >= _investEverDayTotal + value );

            _investEverDayTotal += value;

        }

    }

    // On the remaining day, the whole network can participate in the quota
    function SurplusDepositLimitAll() external view returns (uint256) {

        if ( now - _investEverDayUTime > 1 days ) {

            return _investEverDayMaxLimit;

        } else {

            return _investEverDayMaxLimit - _investEverDayTotal;

        }

    }
}
