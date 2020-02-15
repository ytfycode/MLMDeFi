pragma solidity >=0.5.0 <0.6.0;

import "./interface/cost/CostInterface.sol";
import "./InternalModule.sol";

contract Cost is CostInterface, InternalModule {

    uint256 public _costProp = 10;

    // 1ETH = _prop ERC20Token
    uint256 public _prop = 3000 ether;

    constructor() public {

    }

    function CurrentCostProp() external view returns (uint256) {
        return _prop;
    }

    function WithdrawCost(uint256 value) external view returns (uint256) {
        return ((value * _costProp / 100) * _prop) / 1 ether;
    }

    function Owner_SetChangeProp( uint256 p ) external OwnerOnly {
        _prop = p;
    }

    function Owner_SetCostProp(uint256 newProp) external OwnerOnly {
        _costProp = newProp;
    }
}
