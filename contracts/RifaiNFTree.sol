// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract RifaiNFTree is ERC721, AccessControl, ReentrancyGuard {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 private _nextTokenId;
    string private _customBaseURI;

    struct PlantingCampaign {
        string campaignMetadata;
        uint256 startDate;
        uint256 endDate;
        uint256 totalTrees;
        uint256 treesPlanted;
        address beneficiary;
        address paymentToken;
        uint256 paymentAmount;
    }
    mapping(uint256 => PlantingCampaign) public plantingCampaigns;

    constructor(
        address defaultAdmin,
        address minter
    ) ERC721("RifaiNFTree", "RNT") {
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(MINTER_ROLE, minter);
    }

    function _baseURI() internal view override returns (string memory) {
        return _customBaseURI;
    }

    function setBaseURI(
        string memory baseURI
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _customBaseURI = baseURI;
    }

    function setPublicCampaign(
        uint256 campaignId,
        uint256 startDate,
        uint256 endDate,
        uint256 totalTrees,
        address beneficiary,
        address paymentToken,
        uint256 paymentAmount,
        string memory campaignMetadata
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            plantingCampaigns[campaignId].startDate > block.timestamp &&
                plantingCampaigns[campaignId].endDate < block.timestamp,
            "Campaign already started or ended."
        );
        // Check if provided payment token is valid
        if (paymentToken != address(0) && paymentAmount > 0) {
            require(
                IERC20(paymentToken).totalSupply() > 0,
                "Invalid payment token."
            );
        }
        // Set the campaign
        plantingCampaigns[campaignId] = PlantingCampaign(
            campaignMetadata,
            startDate,
            endDate,
            totalTrees,
            0,
            beneficiary,
            paymentToken,
            paymentAmount
        );
    }

    function adoptTree(
        uint256 campaignId,
        address adopter
    ) public onlyRole(MINTER_ROLE) nonReentrant {
        // Check if the campaign is valid
        require(
            plantingCampaigns[campaignId].startDate < block.timestamp &&
                plantingCampaigns[campaignId].endDate > block.timestamp,
            "Campaign not started or already ended."
        );
        // Check if the campaign has not ended
        require(
            plantingCampaigns[campaignId].treesPlanted <
                plantingCampaigns[campaignId].totalTrees,
            "Campaign already ended."
        );
        // Check if the campaign has a payment token and amount
        if (
            plantingCampaigns[campaignId].paymentToken != address(0) &&
            plantingCampaigns[campaignId].paymentAmount > 0
        ) {
            // Check if the sender has enough balance
            require(
                IERC20(plantingCampaigns[campaignId].paymentToken).balanceOf(
                    msg.sender
                ) >= plantingCampaigns[campaignId].paymentAmount,
                "Insufficient balance."
            );
            // Request the payment from the sender
            IERC20(plantingCampaigns[campaignId].paymentToken).transferFrom(
                msg.sender,
                plantingCampaigns[campaignId].beneficiary,
                plantingCampaigns[campaignId].paymentAmount
            );
        }
        // Mint the NFT
        uint256 tokenId = _nextTokenId++;
        _safeMint(adopter, tokenId);
        // Update the campaign
        plantingCampaigns[campaignId].treesPlanted++;
    }

    // The following functions are overrides required by Solidity.
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
