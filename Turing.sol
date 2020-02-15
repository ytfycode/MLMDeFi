pragma solidity >=0.5.0 <0.6.0;

import "./InternalModule.sol";
import "./interface/lib_math.sol";
import "./interface/turing/TuringInterface.sol";

interface RoundInc {
    function CurrentDepsitedTotalAmount() external view returns (uint256);
}

library History {

    struct DB {

        uint256 safetyValue;

        uint256 withdrawThreshold;

        uint256 latestDay;
        mapping (uint256 => TuringRecord) map;
    }

    struct TuringRecord {

        bool exist;

        uint256 dayTime;

        uint256 depositMaxLimit;

        uint256 depositTotalCurren;

        uint256 staticProfixProp;

        uint256 latestUpdateTimeP90;
    }

    function isExist( DB storage self, uint256 dayzero ) public view returns (bool) {
        return self.map[dayzero].exist;
    }

    function getRecordByDay( DB storage self, uint256 dayzero ) internal view returns ( TuringRecord storage ) {
        return self.map[dayzero];
    }

    function getLatestRecord( DB storage self ) internal view returns ( TuringRecord storage ) {
        return self.map[self.latestDay];
    }

    function appendResult( DB storage self, uint256 dayzero, TuringRecord memory newRecord) internal {

        if ( !isExist(self, dayzero) )  {
            self.map[dayzero] = newRecord;
            self.latestDay = dayzero;
        }
    }

}

contract Turing is TuringInterface, InternalModule {

    History.DB private _history;
    using History for History.DB;

    RoundInc public roundContractAddress;
    /// call only One
    function CallOnlyOnceInit( address roundAddress ) public {
        require (roundContractAddress == RoundInc(0x0));
        roundContractAddress = RoundInc(roundAddress);
    }

    bool public enable = false;
    bool public ownerDisable = false;

    uint256 public I = 200 ether;

    uint256 public P = 10;

    uint256 public T = 25;

    uint256 public S = 100;

    constructor() public {

        _managerAddress = msg.sender;

        _history.safetyValue = S;
        _history.withdrawThreshold = S;

        History.TuringRecord memory initRecord = History.TuringRecord(true, lib_math.CurrentDayzeroTime(), I, 0, P, 0);
        _history.appendResult(_history.latestDay, initRecord );
    }

    function GetProfitPropBytime(uint256 time) external view returns (uint256) {
        uint256 today = lib_math.ConvertTimeToDay(time);
        return _history.getRecordByDay(today).staticProfixProp;
    }

    function GetCurrentWithrawThreshold() external view returns (uint256) {
        return _history.withdrawThreshold;
    }

    function GetDepositedLimitMaxCurrent() external view returns (uint256) {
        return _history.getLatestRecord().depositMaxLimit;
    }

    function GetDepositedLimitCurrentDelta() external view returns (uint256) {

        if ( !_history.isExist( lib_math.CurrentDayzeroTime() ) ) {
            return I;
        }

        return _history.getLatestRecord().depositMaxLimit - _history.getLatestRecord().depositTotalCurren;
    }

    function GetSafetyValue() external view returns (uint256) {
        return _history.safetyValue;
    }

    function GetLatestRecordTime() external view returns (uint256) {
        return _history.latestDay;
    }

    function GetDetailResultByDay(uint256 dayzero) external view returns (
        uint256 dayTime,
        uint256 depositMaxLimit,
        uint256 depositTotalCurren,
        uint256 staticProfixProp,
        uint256 latestUpdateTimeP90
    ) {

        History.TuringRecord memory r = _history.map[dayzero];

        return (r.dayTime, r.depositMaxLimit, r.depositTotalCurren, r.staticProfixProp, r.latestUpdateTimeP90);
    }

    function API_SubDepositedLimitCurrent(uint256 v) external APIMethod {

        History.TuringRecord storage r = _history.getLatestRecord();

        if ( r.depositTotalCurren + v > r.depositMaxLimit ) {
            r.depositTotalCurren = r.depositMaxLimit;
        } else {
            r.depositTotalCurren += v;
        }

        if ( r.latestUpdateTimeP90 == 0 && r.depositMaxLimit - r.depositTotalCurren < (r.depositMaxLimit * 10 / 100) ) {
            r.latestUpdateTimeP90 = now;
        }
    }

    function Analysis() external {

        uint256 today = lib_math.ConvertTimeToDay(now);
        if ( _history.isExist(today) ) {
            return ;
        }

        History.TuringRecord memory lRecord = _history.getLatestRecord();
        History.TuringRecord memory initRecord = History.TuringRecord(true, today, I, 0, P, 0);

        if ( !enable || ownerDisable ) {

            _history.withdrawThreshold = S;

            _history.appendResult(today, initRecord );

            return ;
        }

        uint256 M = (roundContractAddress.CurrentDepsitedTotalAmount() * P / 1000) * 2;
        if ( M == 0 ) {
            M = 1;
        }

        if ( lib_math.CurrentDayzeroTime() - lRecord.dayTime > lib_math.OneDay() ) {

            lRecord.dayTime = today;

            _history.appendResult(today, lRecord);

            return ;

        } else {

            uint256 X = 23;

            if ( lRecord.latestUpdateTimeP90 > lRecord.dayTime ) {
                X = ((lRecord.latestUpdateTimeP90 - lRecord.dayTime) / lib_math.OneHours()) % 24;
            }

            uint8[24] memory Ys = [
                160, 150, 140, 135,
                130, 130, 130, 130,
                100, 100, 100, 100,
                 66,  66,  66,  66,
                 33,  33,  33,  33,
                 33,  33,  33,  33
            ];
            uint256 FA = lRecord.depositMaxLimit * Ys[X] / 100;
            uint256 FN = 0;

            if ( FA >= M && FA >= I ) {

                FN = FA;

            } else if ( FA >= I && FA <= M) {

                FN = M;

            } else {

                FN = I;

            }

            uint256 D = address(roundContractAddress).balance / M;
            uint256 FN2 = (D * 100) / T;
            _history.safetyValue = FN2;

            if ( FN2 > 100 ) {
                _history.withdrawThreshold = 100;
            } else {
                _history.withdrawThreshold = FN2;
            }

            initRecord.depositMaxLimit = FN;

            initRecord.staticProfixProp = (P * _history.withdrawThreshold) / 100;

            if ( initRecord.staticProfixProp / lRecord.staticProfixProp > 2 ) {

                initRecord.staticProfixProp = lRecord.staticProfixProp * 2;

            } else if ( lRecord.staticProfixProp / initRecord.staticProfixProp > 2 ) {

                initRecord.staticProfixProp = lRecord.staticProfixProp / 2;
            }

            _history.appendResult(today, initRecord);

            return ;
        }

    }

    function API_PowerOn() external APIMethod {

        if ( ownerDisable ) {
            return ;
        }

        enable = true;
    }

    function Owner_PowerOn() external OwnerOnly {

        ownerDisable = false;
        enable = true;
    }

    function Owner_PowerOff() external OwnerOnly {

        ownerDisable = true;
        enable = false;
    }

    function Owner_IPTS(uint256 i, uint256 p, uint256 t, uint256 s) external OwnerOnly {
        I = i;
        P = p;
        T = t;
        S = s;
    }
}
