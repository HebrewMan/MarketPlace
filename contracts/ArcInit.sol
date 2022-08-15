// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ArcInit {

    /**
     * @dev Stauts of initialization
     */
    bool private _isInit;

    /**
     * @dev Modifier for initialization. Make sure only call onece
     */
    modifier isInit {
        require(!_isInit, "Initialized!");
        _;
        _isInit = true;
    }
}