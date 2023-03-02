// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/oft/extension/BasedOFT.sol";

/// @title A LayerZero OmnichainFungibleToken example of BasedOFT
/// @notice Use this contract only on the BASE CHAIN. It locks tokens on source, on outgoing send(), and unlocks tokens when receiving from other chains.

interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract Xyn is BasedOFT {
    uint private blockForTradingStart;
    address public lpPairLaunch = address(0);
    address private tokensaleContract = address(0);
    address public FACTORY;
    address public WETH;
    address public ROUTER;
    mapping(address => bool) private restrictedWallets;
    mapping(address => bool) private automatedMarketMakerPairs;

    constructor(address _layerZeroEndpoint, uint _initialSupply, address _FACTORY, address _WETH, address _ROUTER) BasedOFT("AIT", "AIT", _layerZeroEndpoint) {
        _mint(_msgSender(), _initialSupply);
        FACTORY = _FACTORY;
        WETH = _WETH;
        ROUTER = _ROUTER;

        lpPairLaunch = IFactory(FACTORY).createPair(address(this), WETH);
    }

    function _transfer(address from, address to, uint amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");

        if (!tradingActive()) {
            require(_msgSender() == owner() || _msgSender() == tokensaleContract || _msgSender() == ROUTER, "Trading is not active.");
        }

        if (tradingActive() && from == lpPairLaunch && to != lpPairLaunch) {
            require(_msgSender() == owner(), "Trading is not active");
        }

        super._transfer(from, to, amount);
    }

    function tradingActive() private view returns (bool) {
        return block.number > blockForTradingStart;
    }

    function enableTrading(uint blocksUntilTrading) external onlyOwner {
        require(lpPairLaunch != address(0), "Lp pair not set");
        require(!tradingActive(), "Trading is already active, cannot relaunch.");
        require(blocksUntilTrading < 3, "Cannot make penalty blocks more than 2");
        uint tradingActivatedBlock = block.number;
        blockForTradingStart = tradingActivatedBlock + blocksUntilTrading;
    }

    function setTokensaleContract(address _tokensaleContract) external onlyOwner {
        require(!tradingActive(), "Trading is already active");
        tokensaleContract = _tokensaleContract;
    }
}
