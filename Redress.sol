pragma solidity >=0.5.0 <0.6.0;

import "./InternalModule.sol";
import "./interface/redress/RedressInterface.sol";
import "./interface/token/ERC20Interface.sol";

contract Redress is InternalModule, RedressInterface {

    struct LockedRedress {

        uint256 total;

        uint256 withdrawed;

        uint256 latestWithdrawTime;
    }

    ERC20Interface private _EInc;

    constructor( ERC20Interface einc ) public {
        _EInc = einc;
    }

    uint256 public _withdrawProp = 2;

    uint256 public _freeDuration = 1 days;

    mapping( address => LockedRedress ) _lockRedressMapping;

    function RedressInfo() external view returns ( uint256 total, uint256 withdrawed, uint256 cur ) {

        if ( _lockRedressMapping[msg.sender].total == 0 ) {
            return (0, 0, 0);
        }

        LockedRedress memory red = _lockRedressMapping[msg.sender];

        uint256 cwdc = (now - red.latestWithdrawTime) / _freeDuration;

        uint256 amount = red.total * (_withdrawProp * cwdc) / 100;

        if ( red.withdrawed + amount > red.total ) {
            amount = red.total - red.withdrawed;
        }

        return ( red.total, red.withdrawed, amount );
    }

    function WithdrawRedress() external returns (uint256) {

        LockedRedress storage red = _lockRedressMapping[msg.sender];

        if ( red.total == 0 || red.total == red.withdrawed ) {
            return 0;
        }

        uint256 cwdc = (now - red.latestWithdrawTime) / _freeDuration;
        uint256 amount = red.total * (_withdrawProp * cwdc) / 100;

        if ( red.withdrawed + amount > red.total ) {
            amount = red.total - red.withdrawed;
        }

        red.withdrawed += amount;

        red.latestWithdrawTime = (now / _freeDuration) * _freeDuration;

        _EInc.API_MoveToken( address(_EInc), msg.sender, amount );

        emit Event_WithdrawRedress( msg.sender, amount, red.withdrawed );

        return amount;
    }

    function API_AddRedress( address who, uint256 amount ) external APIMethod {

        if ( _lockRedressMapping[who].total == 0 ) {

            // new
            _lockRedressMapping[who] = LockedRedress( amount, 0, (now / _freeDuration) * _freeDuration );

        } else {

            // append
            _lockRedressMapping[who].total += amount;
        }

        emit Event_AddNewRedress( who, amount, _lockRedressMapping[who].total );
    }

}
