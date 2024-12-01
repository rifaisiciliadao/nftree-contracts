// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract RifaiNFTree is ERC721, AccessControl, ReentrancyGuard {
    // Structs
    struct PlantingCampaign {
        string campaignMetadata;
        uint256 startDate;
        uint256 endDate;
        uint256 totalTrees;
        uint256 treesPlanted;
        address beneficiary;
        address contributeToken;
        uint256 contributeAmount;
        uint256 rifaiDaoFee;
    }

    // State
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant VALIDATOR_ROLE = keccak256("VALIDATOR_ROLE");
    uint256 private _nextTokenId;
    string private _customBaseURI;
    address public rifaiDaoBeneficiary;
    mapping(uint256 => PlantingCampaign) public plantingCampaigns;
    mapping(uint256 => mapping(address => bool)) public campaignAdopters;
    mapping(uint256 => uint256) public treeIdToCampaignId;
    mapping(uint256 => uint256[]) public campaignTreeIds;
    mapping(uint256 => string) public extendedTreeMetadata;

    // Events
    event TreeAdopted(uint256 indexed campaignId, address indexed adopter);
    event CampaignSet(
        uint256 indexed campaignId,
        string campaignMetadata,
        uint256 startDate,
        uint256 endDate,
        uint256 totalTrees,
        address beneficiary,
        address contributeToken,
        uint256 contributeAmount,
        uint256 rifaiDaoFee
    );
    event TreeMetadataSet(uint256 indexed tokenId, string metadata);

    constructor(
        address defaultAdmin,
        address minter,
        address validator,
        address _rifaiDaoBeneficiary
    ) ERC721("RifaiNFTree", "RNT") {
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(MINTER_ROLE, minter);
        _grantRole(VALIDATOR_ROLE, validator);
        rifaiDaoBeneficiary = _rifaiDaoBeneficiary;
    }

    function _baseURI() internal view override returns (string memory) {
        return _customBaseURI;
    }

    function setBaseURI(
        string memory baseURI
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _customBaseURI = baseURI;
    }

    function setRifaiDaoBeneficiary(
        address _rifaiDaoBeneficiary
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        rifaiDaoBeneficiary = _rifaiDaoBeneficiary;
    }

    function setPublicCampaign(
        uint256 campaignId,
        uint256 startDate,
        uint256 endDate,
        uint256 totalTrees,
        address beneficiary,
        address contributeToken,
        uint256 contributeAmount,
        uint256 rifaiDaoFee,
        string memory campaignMetadata
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            rifaiDaoFee < contributeAmount / 3,
            "Rifai DAO fee is too high."
        );
        // Check if provided payment token is valid
        if (contributeToken != address(0) && contributeAmount > 0) {
            require(
                IERC20(contributeToken).totalSupply() > 0,
                "Invalid payment token."
            );
        }
        // Set the campaign
        uint256 treesPlanted = 0;
        if (campaignTreeIds[campaignId].length > 0) {
            treesPlanted = campaignTreeIds[campaignId].length;
        }
        plantingCampaigns[campaignId] = PlantingCampaign(
            campaignMetadata,
            startDate,
            endDate,
            totalTrees,
            treesPlanted,
            beneficiary,
            contributeToken,
            contributeAmount,
            rifaiDaoFee
        );
        emit CampaignSet(
            campaignId,
            campaignMetadata,
            startDate,
            endDate,
            totalTrees,
            beneficiary,
            contributeToken,
            contributeAmount,
            rifaiDaoFee
        );
    }

    function adoptTree(
        uint256 campaignId,
        address adopter
    ) public nonReentrant {
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
            plantingCampaigns[campaignId].contributeToken != address(0) &&
            plantingCampaigns[campaignId].contributeAmount > 0
        ) {
            // Check if the sender has enough balance
            require(
                IERC20(plantingCampaigns[campaignId].contributeToken).balanceOf(
                    msg.sender
                ) >= plantingCampaigns[campaignId].contributeAmount,
                "Insufficient balance."
            );
            // Request the payment from the sender
            uint256 amountToBeneficiary = plantingCampaigns[campaignId]
                .contributeAmount - plantingCampaigns[campaignId].rifaiDaoFee;
            uint256 amountToRifaiDao = plantingCampaigns[campaignId]
                .rifaiDaoFee;
            IERC20(plantingCampaigns[campaignId].contributeToken).transferFrom(
                msg.sender,
                plantingCampaigns[campaignId].beneficiary,
                amountToBeneficiary
            );
            // Transfer the rifai dao fee to the rifai dao
            if (amountToRifaiDao > 0) {
                IERC20(plantingCampaigns[campaignId].contributeToken)
                    .transferFrom(
                        msg.sender,
                        rifaiDaoBeneficiary,
                        amountToRifaiDao
                    );
            }
        }
        // Mint the NFT
        uint256 tokenId = _nextTokenId++;
        _safeMint(adopter, tokenId);
        // Update the campaign and the tree
        plantingCampaigns[campaignId].treesPlanted++;
        campaignAdopters[campaignId][adopter] = true;
        treeIdToCampaignId[tokenId] = campaignId;
        campaignTreeIds[campaignId].push(tokenId);
        emit TreeAdopted(campaignId, adopter);
    }

    // Set the extended metadata for a tree after the planting campaign has ended
    function setTreeExtendedMetadata(
        uint256 tokenId,
        string memory metadata
    ) public onlyRole(VALIDATOR_ROLE) {
        extendedTreeMetadata[tokenId] = metadata;
        emit TreeMetadataSet(tokenId, metadata);
    }

    // Return a batch of metadata for a batch of trees
    function getTreeExtendedMetadataBatch(
        uint256[] memory tokenIds
    ) public view returns (string[] memory) {
        string[] memory metadata = new string[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            metadata[i] = extendedTreeMetadata[tokenIds[i]];
        }
        return metadata;
    }

    // Return the array of token ids for a campaign
    function getCampaignTreeIds(
        uint256 campaignId
    ) public view returns (uint256[] memory) {
        return campaignTreeIds[campaignId];
    }

    // The following functions are overrides required by Solidity.
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
