// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ArcInit.sol";
import "../interfaces/IAirdrop.sol";

import "../ArcPartner.sol";
import "../ArcGuarder.sol";

abstract contract ArcBase is ArcInit,ArcPartner,IAirdrop,ArcGuarder{

    mapping(uint256 => Activity) public activities;

    // The activity that creates the activity is to be used
    uint256 public currentId;

    /**
     * @dev Modifier to allow actions only when the activity is not paused
     */
    modifier noPaused(uint256 id) {
        require(id > 0, "ARC:ERRID");
        require(activities[id].status, "ARC:ACTIV_PAUSED");
        _;
    }

    /**
     * @dev Modifier to allow actions only when the activity is not destroy
     */
    modifier noDestroy(uint256 id) {
        if (id > 0) {
            require(!activities[id].isDestroy && activities[id].status, "ARC:DESTROYED");
        }
        _;
    }

    // modifier isNormal(uint256 id){
    //     require(!activities[id].isDestroy && activities[id].status, "ARC:DESTROYED");
    //     _;
    // }

    modifier lock(uint256 id) {
        if (id > 0) {
            require(activities[id].unlocked, "ARC:LOCKED");
            activities[id].unlocked = false;
            _;
            activities[id].unlocked = true;
        } else {
            _;
        }
    }

    /**
     * @dev Initialize
     * @param partner address of partner, like owner
     */
    function init(address partner) public isInit {
        _setPartner(partner);
    }


    function openActivity(uint256 id) external onlyPartner noDestroy(id) {
        require(id > 0 && id <= currentId, "ARC:ERRID");
        activities[id].status = true;

        emit SetStatus(id, true);
    }


    function closeActivity(uint256 id) external onlyPartner lock(id) noDestroy(id)
    {
        require(id > 0 && id <= currentId, "ARC:ERRID");
        activities[id].status = false;

        emit SetStatus(id, false);
    }
}
