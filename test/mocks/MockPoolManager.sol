// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {Currency} from "v4-core/src/types/Currency.sol";

contract MockPoolManager {
    bool public poolInitialized;
    bool public liquidityAdded;
    uint256 public lastAmount0;
    uint256 public lastAmount1;
    PoolKey public lastPoolKey;
    uint160 public lastStartingPrice;

    function initialize(PoolKey memory key, uint160 startingPrice) external returns (int24 tick) {
        poolInitialized = true;
        lastPoolKey = key;
        lastStartingPrice = startingPrice;
        return 0; // Mock tick return value
    }

    function addLiquidity(
        PoolKey memory key, 
        Currency currency0, 
        Currency currency1, 
        uint256 amount0, 
        uint256 amount1
    ) external returns (bytes memory) {
        liquidityAdded = true;
        lastPoolKey = key;
        lastAmount0 = amount0;
        lastAmount1 = amount1;
        return "";
    }
} 