pragma solidity >=0.5.0 <0.6.0;

import "./interface/statistics/StatisticsInterface.sol";
import "./InternalModule.sol";

contract Statistics is StatisticsInterface, InternalModule {

    mapping(address => uint256) _staticProfixTotalMapping;

    mapping(address => uint256) _dynamicProfixTotalMapping;

    mapping(address => bool) _playerAddresses;

    uint256 public JoinedPlayerTotalCount = 0;

    uint256 public JoinedGameTotalCount = 0;

    uint256 public AllWithdrawEtherTotalCount = 0;

    uint256 public WinnerCount = 0;

    constructor() public {
        _managerAddress = msg.sender;
    }

    function GetStaticProfitTotalAmount() external view returns (uint256) {
        return _staticProfixTotalMapping[msg.sender];
    }

    function GetDynamicProfitTotalAmount() external view returns (uint256) {
        return _dynamicProfixTotalMapping[msg.sender];
    }

    function API_AddStaticTotalAmount( address player, uint256 value ) external APIMethod {
        _staticProfixTotalMapping[player] += value;
        AllWithdrawEtherTotalCount += value;
    }

    function API_AddDynamicTotalAmount( address player, uint256 value ) external APIMethod {
        _dynamicProfixTotalMapping[player] += value;
        AllWithdrawEtherTotalCount += value;
    }

    function API_AddWinnerCount() external APIMethod {
        WinnerCount++;
    }
}
