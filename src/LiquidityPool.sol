// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {Currency} from "v4-core/src/types/Currency.sol";
import {CurrencyLibrary} from "v4-core/src/types/Currency.sol";

contract LiquidityPool {
    IPoolManager public immutable poolManager;

    constructor(address _poolManager) {
        poolManager = IPoolManager(_poolManager);
    }

    function createPool(
        Currency currency0,
        Currency currency1,
        uint24 fee,
        int24 tickSpacing,
        address hooks,
        uint160 startingPrice
    ) external returns (PoolKey memory pool) {
        // Ensure currencies are sorted
        require(uint160(address(currency0)) < uint160(address(currency1)), "Currencies not sorted");

        // Create the pool key
        pool = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: fee,
            tickSpacing: tickSpacing,
            hooks: hooks
        });

        // Initialize the pool with the starting price
        poolManager.initialize(pool, startingPrice);
    }


    function addLiquidity(
        PoolKey memory pool,
        Currency currency0,
        Currency currency1,
        uint256 amount0,
        uint256 amount1
    ) external {
    poolManager.addLiquidity(pool, currency0, currency1, amount0, amount1);
    }



}
