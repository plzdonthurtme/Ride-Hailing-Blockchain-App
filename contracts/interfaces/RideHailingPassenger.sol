// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "../data_storages/RideHailingAccountsDataStorage.sol";
import "../data_storages/RideHailingRidesDataStorage.sol";
import "../data_storages/RideHailingDisputesDataStorage.sol";

contract RideHailingPassenger {
    RideHailingAccountsDataStorage private accountsDataStorage;
    RideHailingRidesDataStorage private ridesDataStorage;
    RideHailingDisputesDataStorage private rideDisputeDataStorage;

    constructor(
        RideHailingAccountsDataStorage accountsDataStorageAddress,
        RideHailingRidesDataStorage ridesDataStorageAddress,
        RideHailingDisputesDataStorage rideDisputeDataStorageAddress
    ) {
        accountsDataStorage = accountsDataStorageAddress;
        ridesDataStorage = ridesDataStorageAddress;
        rideDisputeDataStorage = rideDisputeDataStorageAddress;
    }

    function requestRide(
        uint256 bidAmount,
        string memory startLocation,
        string memory destination
    ) external payable functionalAccountOnly {
        require(
            msg.value + accountsDataStorage.getAccountBalance(msg.sender) >=
                bidAmount + accountsDataStorage.MIN_DEPOSIT_AMOUNT(),
            "Insufficient value sent"
        );

        require(
            rideDisputeDataStorage.getNumUnrespondedDisputes(msg.sender) == 0,
            "You have yet to respond your disputes"
        );

        require(
            ridesDataStorage.hasCurrentRide(msg.sender) == false,
            "Passenger cannot request ride as previous ride has not been completed"
        );
        ridesDataStorage.createRide(msg.sender, startLocation, destination, bidAmount);
        accountsDataStorage.addBalance(msg.value, address(accountsDataStorage));
    }

    // editRide?

    function acceptDriver(uint256 rideId) external functionalAccountOnly {
        ridesDataStorage.acceptByPassenger(rideId, msg.sender);
    }

    function completeRide(uint256 rideId) external functionalAccountOnly {
        ridesDataStorage.completeByPassenger(rideId, msg.sender);
    }

    function rateDriver(uint256 rideId, uint256 score) external functionalAccountOnly {
        require(ridesDataStorage.rideCompleted(rideId), "Ride has not been marked as completed");

        require(score >= 0 && score <= 10, "Invalid Rating. Rating must be between 0 and 5");
        require(
            ridesDataStorage.getRatingForDriver(rideId) == 0,
            "You have rated this driver previously"
        );
        ridesDataStorage.rateDriver(rideId, score);
        address driver = ridesDataStorage.getDriver(rideId);
        accountsDataStorage.rateUser(score, driver);
    }

    modifier functionalAccountOnly() {
        require(accountsDataStorage.accountExists(msg.sender), "Account does not exist");
        require(accountsDataStorage.accountIsFunctional(msg.sender), "Minimum deposit not met");
        _;
    }
}
