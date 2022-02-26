//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

library OwnedRanges {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    struct OwnedRangesMapping {
        uint64 maxIndex;
        uint64 bacthSize;
        uint48 nextBatch;
        bool initialized;
        mapping (address => EnumerableSet.UintSet) _rangeStartHolders;
        mapping (uint256 => uint256) _rangeStartsToEnds;
        EnumerableMap.UintToAddressMap _rangeStartReverseMapping;
    }

    function init(OwnedRangesMapping storage rmap, address owner, uint64 number_of_items, uint64 _batchSize) internal returns (bool) {
        require(!rmap.initialized);
        rmap._rangeStartHolders[owner].add(0);
        rmap._rangeStartsToEnds[0] = number_of_items;
        rmap._rangeStartReverseMapping.set(0, owner);
        rmap.maxIndex = number_of_items;
        rmap.initialized = true;
        rmap.bacthSize = _batchSize;
        return true;
    }

    function ownerOf(OwnedRangesMapping storage rmap, uint256 idx) internal view returns (address) {
        uint256 revMapLen = rmap._rangeStartReverseMapping.length();
        // if (revMapLen > rmap.saturationPoint) {
        (bool hit, address owner) = rmap._rangeStartReverseMapping.tryGet(idx);
        if(hit) {
            return owner;
        }
        // }
        uint256 currentEnd = rmap._rangeStartsToEnds[0];
        if (idx < currentEnd) {
            return rmap._rangeStartReverseMapping.get(0);
        }

        for (uint i = 0; i < revMapLen-1; i++) {
            uint256 currentStart = currentEnd;
            currentEnd = rmap._rangeStartsToEnds[currentStart];
            if (idx < currentEnd) {
                return rmap._rangeStartReverseMapping.get(currentStart);
            }
        }
        return address(0);
    }

    function ownerOfRanges(OwnedRangesMapping storage rmap, address owner, uint256 idx) internal view returns (bool, uint, uint) {
        uint256 len = rmap._rangeStartHolders[owner].length();

        // if (revMapLen > rmap.saturationPoint) {
            (bool hit,) = rmap._rangeStartReverseMapping.tryGet(idx);
            if(hit) {
                return (hit, idx, rmap._rangeStartsToEnds[idx]);
            }
        // }

        // uint256 currentEnd = rmap._rangeStartsToEnds[0];
        // if (idx < currentEnd) {
        //     return (rmap._rangeStartReverseMapping.get(0), 0, currentEnd);
        // }
        uint256 currentStart;
        uint256 currentEnd;
        for (uint i = 0; i < len; i++) {
            currentStart = rmap._rangeStartHolders[owner].at(i);
            currentEnd = rmap._rangeStartsToEnds[currentStart];
            if (idx >= currentStart && idx < currentEnd) {
                return (true, currentStart, currentEnd);
            }
        }

        return (false, 0, 0);
    }

    function setOwner(OwnedRangesMapping storage rmap, uint256 idx, uint256 rangeStart, uint256 rangeEnd, uint256 size, address currentOwner, address newOwner) internal returns (bool) {

        uint256 nextRangeStart = idx+size;
        ///Handle when range len == 1
        if (nextRangeStart == rangeEnd) {
            //No range, simple transfer
            rmap._rangeStartsToEnds[rangeStart] = idx;
            rmap._rangeStartHolders[currentOwner].remove(idx);
            rmap._rangeStartHolders[newOwner].add(idx);
            rmap._rangeStartHolders[currentOwner].add(nextRangeStart);
            rmap._rangeStartsToEnds[idx] = nextRangeStart;
            rmap._rangeStartReverseMapping.set(idx, newOwner);
            return true;
        }

        //Handle when range len > 1

        //We split the map into three, (start, n-idx), (idx) (idx+1, end)

        rmap._rangeStartsToEnds[rangeStart] = idx;
        rmap._rangeStartsToEnds[idx] = nextRangeStart;
        rmap._rangeStartsToEnds[nextRangeStart] = rangeEnd;

        rmap._rangeStartReverseMapping.set(idx, newOwner);
        rmap._rangeStartReverseMapping.set(nextRangeStart, currentOwner);

        rmap._rangeStartHolders[currentOwner].add(nextRangeStart);
        rmap._rangeStartHolders[newOwner].add(idx);
        return true;
    }

    // function setOwner(OwnedRangesMapping storage rmap, uint256 idx, address newOwner) internal returns (bool) {
    //     uint256 currentEnd;
    //     uint256 revMapLen = rmap._rangeStartReverseMapping.length();
    //     if (true) {
    //         (bool hit, address owner) = rmap._rangeStartReverseMapping.tryGet(idx);
    //         if(hit) {
    //             currentEnd = rmap._rangeStartsToEnds[idx];
    //             return _setOwner(rmap, idx, idx, currentEnd, owner, newOwner);
    //         }
    //     }
    //     address currentAddr = rmap._rangeStartReverseMapping.get(0);
    //     currentEnd = rmap._rangeStartsToEnds[0];
    //     if (idx < currentEnd) {
    //         return _setOwner(rmap, idx, 0, currentEnd, currentAddr, newOwner);
    //     }
    //     for (uint i = 0; i < revMapLen-1; i++) {
    //         uint256 currentStart = currentEnd;
    //         currentEnd = rmap._rangeStartsToEnds[currentStart];
    //         if (idx < currentEnd) {
    //             return _setOwner(rmap, idx, currentStart, currentEnd, rmap._rangeStartReverseMapping.get(currentStart), newOwner);
    //         }
    //     }
    //     return false;
    // }

    function ownedIndexToIdx(OwnedRangesMapping storage rmap, address owner, uint256 ownedIndex) internal view returns (uint256) {
        uint256 currentStart = rmap._rangeStartHolders[owner].at(0);
        uint256 currentEnd = rmap._rangeStartsToEnds[currentStart];
        if (ownedIndex < (currentEnd - currentStart)) {
            return currentStart + ownedIndex;
        }
        ownedIndex -= currentEnd - currentStart;
        if (ownedIndex < 1) {
            require(false);
        }
        for (uint i = 1; i < rmap._rangeStartHolders[owner].length(); i++) {
            currentStart = rmap._rangeStartHolders[owner].at(i);
            currentEnd = rmap._rangeStartsToEnds[currentStart];
            if (ownedIndex < (currentEnd - currentStart)) {
                return currentStart + ownedIndex;
            }
            ownedIndex -= currentEnd - currentStart;
            if (ownedIndex < 1) {
                require(false);
            }
        }
        require(false);
        return 0;
    }

    function ownerBalance(OwnedRangesMapping storage rmap, address owner) internal view returns (uint256) {
        uint256 balance = 0;
        for (uint i = 0; i < rmap._rangeStartHolders[owner].length(); i++) {
            uint256 currentStart = rmap._rangeStartHolders[owner].at(i);
            uint256 currentEnd = rmap._rangeStartsToEnds[currentStart];
            balance += (currentEnd - currentStart);
        }
        return balance;
    }

    function length(OwnedRangesMapping storage rmap) internal view returns (uint256) {
        return rmap.maxIndex;
    }
}