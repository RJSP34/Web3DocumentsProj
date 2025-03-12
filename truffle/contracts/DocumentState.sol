// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./Role.sol"; 
import "./User.sol"; 

contract DocumentState {
    uint256 constant MAX_PDF_SIZE = 20 * 1024 * 1024; // 20 MB limit
    bytes4 constant PDF_SIGNATURE = 0x25504446; // Hex representation of "%PDF"

    enum RecordState {
        Active,
        Deleted
    }

    struct Document {
        // Unique identifier for the chat.
        uint256 id;
        // Non-unique name for the chat.
        string documentName;
        // id of the patient.
        uint256 patientID;
        // The PDF
        bytes pdfData;
        address issuer;
        // The participants to the chat, represented by their public key.
        address[] participantPublicKeys;
        mapping(address => bool) participantStatus;

        RecordState recordState;
        uint256 createdAt;
        uint256 changedAt;
    }

    event DocumentCreated(uint256 indexed id, string documentName, address indexed issuer);
    event DocumentUpdated(uint256 indexed id, string newDocumentName, address indexed issuer);
    event DocumentDeleted(uint256 indexed id, address indexed issuer);
    event DocumentRecovered(uint256 indexed id, address indexed issuer);

    mapping(uint256 => Document) private documents;
    uint256 private documentCount = 0;
    uint256 private currentID = 1;

    User private usersContract;

    constructor(address _usersContractAddress) {
        usersContract = User(_usersContractAddress);
    }

    function isPDF(bytes memory data) internal pure returns (bool) {
        if (data.length >= 4) {
            bytes4 signature;
            assembly {
                signature := mload(add(data, 32))
            }
            return signature == PDF_SIGNATURE;
        }
        return false;
    }

    function createDocument(
        string memory _documentName,
        uint256 _patientID,
        bytes memory _pdfData,
        address _issuer,
        address[] memory _participantPublicKeys
    ) public {
        require(bytes(_documentName).length > 0, "Document name must not be empty");

        require(_patientID != 0, "Patient ID must be specified");

        require(_pdfData.length > 0, "PDF data must not be empty");

        require(_pdfData.length <= MAX_PDF_SIZE, "PDF data exceeds the size limit");

        require(isPDF(_pdfData), "Invalid PDF data");

        require(_participantPublicKeys.length > 0, "Participant public keys must be specified");

        require(address(usersContract) != address(0), "User contract not set");

        require(usersContract.hasMedicalPersonalRole(), "Participant public keys must be specified");

        Document storage newDocument = documents[currentID];
        newDocument.id = currentID;
        newDocument.documentName = _documentName;
        newDocument.patientID = _patientID;
        newDocument.pdfData = _pdfData;
        newDocument.issuer = msg.sender;
        newDocument.participantPublicKeys = _participantPublicKeys;

        for (uint256 i = 0; i < _participantPublicKeys.length; i++) {
            newDocument.participantStatus[_participantPublicKeys[i]] = false;
        }

        newDocument.recordState = RecordState.Active;
        newDocument.createdAt = block.timestamp;
        newDocument.changedAt = block.timestamp;

        documentCount++;
        emit DocumentCreated(currentID, _documentName, _issuer);
        currentID++;
    }

    function updateDocument( uint256 _id, string memory _newDocumentName, bytes memory _newPdfData) public {
        Document storage existingDocument = documents[_id];

        require(existingDocument.id != 0, "Document with this ID does not exist");

        require(bytes(_newDocumentName).length > 0, "New document name must not be empty");

        require(_newPdfData.length > 0, "New PDF data must not be empty");

        require(_newPdfData.length <= MAX_PDF_SIZE, "New PDF data exceeds the size limit");

        require(msg.sender == existingDocument.issuer || isInPublicAddressList( existingDocument.participantPublicKeys, msg.sender), "Unauthorized issuer");

        existingDocument.documentName = _newDocumentName;
        existingDocument.pdfData = _newPdfData;
        existingDocument.changedAt = block.timestamp;
        emit DocumentUpdated(_id, _newDocumentName, msg.sender);
    }

    function isInPublicAddressList(address[] memory participantPublicKeys, address _address) internal pure returns (bool) {
        for (uint256 i = 0; i < participantPublicKeys.length; i++) {
            if (participantPublicKeys[i] == _address) {
                return true; 
            }
        }
        return false;
    }

    function getDocumentById(uint256 _id) public view returns (
        string memory documentName,
        uint256 patientID,
        bytes memory pdfData,
        address[] memory participantPublicKeys,
        uint256 createdAt,
        uint256 changedAt
    ) {
        Document storage retrievedDocument = documents[_id];

        require(retrievedDocument.id != 0 && retrievedDocument.recordState != RecordState.Deleted, "Document with this ID does not exist");
        require(msg.sender == retrievedDocument.issuer || isInPublicAddressList( retrievedDocument.participantPublicKeys, msg.sender), "Unauthorized issuer");

        return 
        (
            retrievedDocument.documentName,
            retrievedDocument.patientID,
            retrievedDocument.pdfData,
            retrievedDocument.participantPublicKeys,
            retrievedDocument.createdAt,
            retrievedDocument.changedAt
        );
    }

    function getAllDocuments() public view returns (
        string[] memory documentNames,
        uint256[] memory patientIDs,
        bytes[] memory pdfDatas,
        address[][] memory participantPublicKeysList,
        bool[][] memory participantStatusList,
        uint256[] memory createdAtList,
        uint256[] memory changedAtList
    ) {

    documentNames = new string[](documentCount);
    patientIDs = new uint256[](documentCount);
    pdfDatas = new bytes[](documentCount);
    participantPublicKeysList = new address[][](documentCount);
    participantStatusList = new bool[][](documentCount);
    createdAtList = new uint256[](documentCount);
    changedAtList = new uint256[](documentCount);

    for (uint256 i = 1; i <= documentCount; i++) {
        Document storage currentDocument = documents[i];

        if (currentDocument.id != 0 && currentDocument.recordState != RecordState.Deleted) {
            documentNames[i-1] = currentDocument.documentName;
            patientIDs[i-1] = currentDocument.patientID;
            pdfDatas[i-1] = currentDocument.pdfData;
            participantPublicKeysList[i-1] = currentDocument.participantPublicKeys;

            bool[] memory participantStatus = new bool[](currentDocument.participantPublicKeys.length);
            for (uint256 j = 0; j < currentDocument.participantPublicKeys.length; j++) {
                participantStatus[j] = currentDocument.participantStatus[currentDocument.participantPublicKeys[j]];
            }
            participantStatusList[i-1] = participantStatus;

            createdAtList[i-1] = currentDocument.createdAt;
            changedAtList[i-1] = currentDocument.changedAt;
        }
    }

    return (documentNames, patientIDs, pdfDatas, participantPublicKeysList, participantStatusList, createdAtList, changedAtList);
    }

    function deleteDocument(uint256 _id) public {
        Document storage existingDocument = documents[_id];

        require(existingDocument.id != 0 && existingDocument.recordState != RecordState.Deleted, "Document with this ID does not exist");

        existingDocument.recordState = RecordState.Deleted;
        existingDocument.changedAt = block.timestamp;
        documentCount--;
        emit DocumentDeleted(_id, msg.sender);
    }

    function recoverDocument(uint256 _id) public {
        Document storage existingDocument = documents[_id];

        require(existingDocument.id != 0, "Document with this ID does not exist");

        require(existingDocument.recordState == RecordState.Deleted, "Document with this ID is not deleted");

        existingDocument.recordState = RecordState.Active;
        existingDocument.changedAt = block.timestamp;
        documentCount++;
        emit DocumentRecovered(_id, msg.sender);
    }

    function signDocument(uint256 _id) public {
        Document storage documentToSign = documents[_id];

        require(documentToSign.id != 0 && documentToSign.recordState != RecordState.Deleted, "Document with this ID does not exist");

        require(isInPublicAddressList(documentToSign.participantPublicKeys, msg.sender), "Unauthorized signer");

        require(!documentToSign.participantStatus[msg.sender], "Document already signed by this participant");

        documentToSign.participantStatus[msg.sender] = true;
        documentToSign.changedAt = block.timestamp;

        emit DocumentUpdated(_id, documentToSign.documentName, msg.sender);
    }

    function addUser(
        string memory _userName,
        Role.UserRole _userRole
    ) public {
        require(address(usersContract) != address(0), "User contract not set");

        usersContract.createUser(_userName, _userRole);
    }

    function updateUser(
        string memory _newUserName    
    ) public {
        require(address(usersContract) != address(0), "User contract not set");

        usersContract.updateUser(_newUserName);
    }
}

