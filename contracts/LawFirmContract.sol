// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LawFirmContract {
    uint256 public lawFirmID = 0;
    uint256 public clientID = 0;
    uint256 public legalDocumentID = 0;
    uint256 public quotationID = 0;
    uint256 public ticketID = 0;

    uint256[] public lawFirmIDs;
    uint256[] public clientIDs;
    uint256[] public legalDocumentIDs;
    uint256[] public quotationIDs;
    uint256[] public ticketIDs;

    // Ticket Status Possibilities
    enum TicketStatus {
        Open, // signatories can start voting on ticket
        Closed, // signatories are no longer allowed to vote on ticket
        ConsensusReached // signatories have reached a consensus on outcome of ticket 
    }

    // Majority Approval Vote Outcome Possibilities
    enum MajorityApprovalVoteOutcome {
        Approved,
        Rejected
    }

    // Payable address can receive Ether
    address payable public owner;

    // Law Firm Entity & Attributes
    struct LawFirm {
        string name;
        address payable walletAddress;
    } 
    // Law Firm Array Position 0 --> Law Firm Struct
    LawFirm[] public lawFirms;

    // Client Entity & Attributes
    struct Client {
        string name;
        address walletAddress;
    }
    // Client Array Position 0 --> Client Struct
    Client[] public clients;
 
    // Legal Document Entity & Attributes
    struct LegalDocument {
        string name;
        string docIPFSURI;
    }
    // Legal Document Array Position 0 --> Legal Document Struct
    LegalDocument[] public legalDocuments;

    // Quotation Entity & Attributes
    struct Quotation {
        uint256 price; // Price in Quantity of MATIC Tokens / Ether
        uint256 platformFee;
        uint256 contractEscrow;
        uint256 lawFirmInitialPayment;
        uint256 lawFirmConcludingPayment;
    }
    // Quotation Array Position 0 --> Quotation Struct
    Quotation[] public quotations;

    // Ticket Entity & Attributes
    struct Ticket {
        // transfer designation of 'owner' from current Owner Wallet Address to suggested Signatory Wallet Address
        address fromOwnerWalletAddress;
        address toSignatoryWalletAddress;
    }
    // Ticket Array Position 0 --> Ticket Struct
    Ticket[] public tickets;

    // map law firm IDs (Array Values) to law firms (Array Values)
    mapping(uint256 => LawFirm) public lawFirmIDToLawFirm;

    // map client IDs (Array Values) to clients (Array Values)
    mapping(uint256 => Client) public clientIDToClient;

    // map legal document IDs (Array Values) to legal documents (Array Values)
    mapping(uint256 => LegalDocument) public legalDocumentIDToLegalDocument;

    // map quotation IDS (Array Values) to quotations (Array Values)
    mapping(uint256 => Quotation) public quotationIDToQuotation;

    // map ticket IDs (Array Values) to tickets (Array Values)
    mapping(uint256 => Ticket) public ticketIDToTicket;

    // ? - map law firms to owners
    // ? - setLawFirmOwner() - update lawFirmToOwner mapping and LawFirm struct walletAddress attribute
    mapping(uint256 => address payable) public lawFirmToOwner; // Law Firm ID to Owner Wallet Address

    // ? - map law firms to signatories
    // ? - addLawFirmSignatories() - update lawFirmToSignatories mapping
    mapping(uint256 => address payable[]) public lawFirmToSignatories; // Law Firm ID to *Signatory Wallet Address

    // map law firms to clients
    mapping(uint256 => uint256[]) public lawFirmToClient; // Law Firm ID to *Client IDs

    // map law firms to legal documents (before item 'Ownership Transfer')
    // To identify law firm that uploaded the legal document
    mapping(uint256 => uint256[]) public lawFirmToLegalDocument; // Law Firm ID to *Legal Document IDs

    // map clients to legal documents (after item 'Ownership Transfer')
    // To identify client that purchased the legal document from 'x' Law Firm
    mapping(uint256 => uint256[]) public clientToLegalDocument; // Client ID to *Legal Document IDs

    // map legal documents to law firms / clients (Law Firm / Client)
    // To identify the current owner of the legal document
    // How to differentiate between law firm ID and client ID?
    mapping(uint256 => bytes32[2]) public legalDocumentToCurrentOwner; // Legal Document ID to Owner Type(Law Firm / Client) + Owner ID(Law Firm ID / Client ID)

    // map legal documents to quotations by law firms
    // To identify the price for the legal document
    mapping(uint256 => uint256) public legalDocumentToQuotation; // Legal Document ID to Quotation ID

    // map quotations to law firms
    // To identify who prepared the quotation (Law Firm)
    mapping(uint256 => uint256) public quotationToLawFirm; // Quotation ID to Law Firm ID

    // map quotations to clients
    // To identify for whom the quotation was prepared (Client)
    mapping(uint256 => uint256) public quotationToClient; // Quotation ID to Client ID

    // map tickets to ticket status
    // To determine whether signatories are still allowed to vote on the approval of a ticket
    mapping(uint256 => TicketStatus) public ticketToTicketStatus; // Ticket ID to Enum Ticket Status

    // map tickets to law firms
    // To identify the law firm for which the transfer of designation 'owner' has been requested
    mapping(uint256 => uint256) public ticketToLawFirm; // Ticket ID to Law Firm ID

    // map tickets to signatory votes
    // To identify the approval votes casted by the signatories of a specific law firm
    mapping(uint256 => mapping(address => bool)) public ticketToSignatoryVotes; // Ticket ID to *(Signatory Wallet Address to Casted Approval Vote [true / false])
    
    // map tickets to ticket fulfilment tracker count
    // To determine whether all the signatories of a law firm have voted on a ticket
    mapping(uint256 => address payable[]) public ticketToTicketFulfilmentTrackerCount; // Ticket ID to *Signatory Wallet Address [each must be unique]

    // map tickets to majority approval vote outcome
    // To determine whether the transfer of designation 'owner' has been approved or rejected by signatories of a law firm
    mapping(uint256 => MajorityApprovalVoteOutcome) public ticketToMajorityApprovalVoteOutcome; // Ticket ID to Enum Majority Approval Vote Outcome [Approved / Rejected]

    // constructor 
    constructor() {
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(payable(msg.sender) == owner);
        _;
    }

    modifier onlyLawFirmOwner(uint256 _lawFirmID) {
        require(payable(msg.sender) == lawFirmToOwner[lawFirmID]);
        _;
    }

    modifier onlyOpenTicket(uint256 _ticketID) {
        require(ticketToTicketStatus[_ticketID] == TicketStatus.Open);
        _;
    }

    modifier onlyClosedTicket(uint256 _ticketID) {
        require(ticketToTicketStatus[_ticketID] == TicketStatus.Closed);
        _;
    }
   
    modifier onlyConsensusReachedTicket(uint256 _ticketID) {
        require(ticketToTicketStatus[_ticketID] == TicketStatus.ConsensusReached);
        _;
    }

    modifier onlyMajorityApprovedTicket(uint256 _ticketID) {
        require(ticketToMajorityApprovalVoteOutcome[_ticketID] == MajorityApprovalVoteOutcome.Approved);
        _;
    }

    modifier onlyNonNominatedLawFirmSignatories(uint256 _ticketID, address _signatoryWalletAddress) {
        // retrieve ticket from ticket ID
        Ticket memory ticket = ticketIDToTicket[_ticketID];

        // retrieve nominated signatory wallet address from ticket
        address nominatedSignatory = ticket.toSignatoryWalletAddress;

        require(_signatoryWalletAddress != nominatedSignatory);
        _; 
    }

    modifier onlyLawFirmSignatories(uint256 _lawFirmID, address _signatoryWalletAddress) {
        // retrieve signatory wallet addresses array from law firm ID
        address payable[] memory signatoryWalletAddresses = lawFirmToSignatories[_lawFirmID];
        bool isSignatory = false;

        // check if msg.sender is one of the law firm signatories
        for(uint256 i=0; i<signatoryWalletAddresses.length; i++) {
            if(payable(_signatoryWalletAddress) == signatoryWalletAddresses[i]) {
                isSignatory = true;
            }
        }

        require(isSignatory == true);
        _;
    }

    // Functions

    // Sequence of Events
    // Create Majority Approval Vote Ticket 
    // Vote on 'Owner' Designation Transfer
    // Determine Majority Approval Vote
    // Set Law Firm Owner

    //createMajorityApprovalVoteTicket - done by current law firm owner
    function createMajorityApprovalVoteTicket(uint256 _lawFirmID, address _toSignatoryWalletAddress) public onlyLawFirmOwner(_lawFirmID) onlyLawFirmSignatories(_lawFirmID, _toSignatoryWalletAddress) returns(uint256){
        // add Ticket ID into Ticket ID Array
        ticketID += 1;
        ticketIDs.push(ticketID);

        // add Ticket into Ticket Array
        Ticket memory ticket = Ticket(msg.sender, _toSignatoryWalletAddress);
        tickets.push(ticket);

        // map Ticket ID to Ticket
        ticketIDToTicket[ticketID] = ticket;  

        // map ticket to ticket status (open)
        ticketToTicketStatus[ticketID] = TicketStatus.Open;

        // map ticket to law firm
        ticketToLawFirm[ticketID] = _lawFirmID;

        // return value
        return ticketID; 
    }

    // voteOnOwnerDesignationTransfer - done by law firm signatories
    function voteOnOwnerDesignationTransfer(uint256 _ticketID, uint256 _lawFirmID, bool _vote) public onlyNonNominatedLawFirmSignatories(_ticketID, msg.sender) onlyLawFirmSignatories(_lawFirmID, msg.sender) onlyOpenTicket(_ticketID){
        bool signatoryHasVoted = false;
        
        // set signatory votes in mapping(tickets)
        ticketToSignatoryVotes[_ticketID][msg.sender] = _vote;

        // retrieve wallet addresses of signatories who have voted on ticket before
        address payable[] memory signatoryWalletAddresses = ticketToTicketFulfilmentTrackerCount[_ticketID];

        // check if signatory has voted on ticket before
        for(uint256 i=0; i<signatoryWalletAddresses.length; i++) { // start for loop
            if(payable(msg.sender) == signatoryWalletAddresses[i]) { // start if statement
                signatoryHasVoted = true; 
            } // end if statement
        } // end for loop

        // if signatory has not voted before, update ticket fulfilment tracker count
        if(signatoryHasVoted == false) {
            ticketToTicketFulfilmentTrackerCount[_ticketID].push(payable(msg.sender));
        }

        if(ticketToTicketFulfilmentTrackerCount[_ticketID].length == lawFirmToSignatories[_lawFirmID].length-1) {
            // map ticket to ticket status (closed)
            ticketToTicketStatus[_ticketID] = TicketStatus.Closed;
        }

    }

    // determineMajorityApprovalVote (close ticket) - done by last law firm signatory to vote
    function determineMajorityApprovalVote(uint256 _ticketID) public onlyClosedTicket(_ticketID) returns(MajorityApprovalVoteOutcome) {
        // specify minimum number of votes required to gain majority approval 
        uint256 minVoteForApproval = (ticketToTicketFulfilmentTrackerCount[_ticketID].length/2) + 1;
        uint256 ApprovalVoteCount = 0;

        // retrieve signatory wallet addresses from ticket fulfilment tracker count
        address payable[] memory signatoryWalletAddresses = ticketToTicketFulfilmentTrackerCount[_ticketID];

        // calculate number of signatory votes casted for this ticket
        for(uint256 i=0; i<signatoryWalletAddresses.length; i++) { // start for loop
            if(ticketToSignatoryVotes[_ticketID][signatoryWalletAddresses[i]] == true){ // start if statement 1
                ApprovalVoteCount += 1;
            } // end if statement 1
        } // end for loop

        // check if signatories approve transfer of 'owner' designation
        if(ApprovalVoteCount >= minVoteForApproval) { // start if statement 2
            // map ticket to majority approval vote outcome (Approved)
            ticketToMajorityApprovalVoteOutcome[_ticketID] = MajorityApprovalVoteOutcome.Approved;
        } // end if statement 2
        else {
            // map ticket to majority approval vote outcome (Rejected)
            ticketToMajorityApprovalVoteOutcome[_ticketID] = MajorityApprovalVoteOutcome.Rejected; 
        }

        // map ticket to ticket status (consensusReached)
        ticketToTicketStatus[_ticketID] = TicketStatus.ConsensusReached;

        // return value
        return ticketToMajorityApprovalVoteOutcome[_ticketID];
        
    }

    // setLawFirmOwner - done by current law firm owner
    // ? - revamp setLawFirmOwner function 
    function setLawFirmOwner(uint256 _ticketID, uint256 _lawFirmID) public onlyConsensusReachedTicket(_ticketID) onlyMajorityApprovedTicket(_ticketID) onlyLawFirmOwner(_lawFirmID) {
        // retrieve new owner wallet address from ticket struct
        Ticket memory tempTicket = ticketIDToTicket[_ticketID];
        address newOwnerWalletAddress = tempTicket.toSignatoryWalletAddress;
        
        // retrieve old law firm owner's wallet address
        address payable oldOwnerWalletAddress = lawFirmToOwner[_lawFirmID];
        bool newOwnerIsSignatory = false;

        // check if new Owner Wallet Address exist in Signatory Wallet Address Array
        for(uint256 i=0; i<lawFirmToSignatories[_lawFirmID].length; i++) {
            if(lawFirmToSignatories[_lawFirmID][i] == payable(newOwnerWalletAddress)) {
                newOwnerIsSignatory = true;
            }
        }

        if(newOwnerIsSignatory == true) {
            // map law Firm ID to new Owner Wallet Address
            lawFirmToOwner[_lawFirmID] = payable(newOwnerWalletAddress);

            // update law Firm struct Wallet Address Attribute in Law Firm Array
            for(uint256 j=0; j<lawFirms.length; j++) {
                if(lawFirms[j].walletAddress == oldOwnerWalletAddress) {
                    lawFirms[j].walletAddress = payable(newOwnerWalletAddress);
                }
            }

            // update law Firm struct Wallet Address attribute in lawFirmIDToLawFirm mapping
            lawFirmIDToLawFirm[_lawFirmID].walletAddress = payable(newOwnerWalletAddress);

            // ? - pop new Owner Wallet Address from Signatory Wallet Address Array in mapping lawFirmToSignatories
            address payable[] storage signatoryWalletAddresses = lawFirmToSignatories[_lawFirmID];
            for(uint256 k=0; k<signatoryWalletAddresses.length; k++) {
                if(signatoryWalletAddresses[k] == payable(newOwnerWalletAddress)) {
                    // delete new Owner Wallet Address from array index position
                    delete signatoryWalletAddresses[k];

                    // check if array index position is not last
                    if(k != signatoryWalletAddresses.length-1) {
                        // set element at empty array index position to element at last array index position
                        signatoryWalletAddresses[k] = signatoryWalletAddresses[signatoryWalletAddresses.length-1];
                    }
                     // pop element from last array index position
                     signatoryWalletAddresses.pop();
                    
                }
            }
            lawFirmToSignatories[_lawFirmID] = signatoryWalletAddresses;

            // ? - push old Owner Wallet Address into Signatory Wallet Address Array in mapping lawFirmToSignatories
            lawFirmToSignatories[_lawFirmID].push(oldOwnerWalletAddress);
        }

    }

    // addLawFirm - done by Ebric
    function addLawFirm(string memory _name, address _ownerWalletAddress, address[] memory signatoryWalletAddresses) public returns(uint256) {
        // add Law Firm ID into Law Firm ID Array
        lawFirmID += 1;
        lawFirmIDs.push(lawFirmID);

        // add Law Firm into Law Firm Array
        LawFirm memory lawFirm = LawFirm(_name, payable(_ownerWalletAddress));
        lawFirms.push(lawFirm);

        // map Law Firm ID to Law Firm
        lawFirmIDToLawFirm[lawFirmID] = lawFirm; 

        // map Law Firm ID to Owner Wallet Address
        lawFirmToOwner[lawFirmID] = payable(_ownerWalletAddress);

        // map Law Firm ID to *Signatory Wallet Address   
        for(uint256 i=0; i<signatoryWalletAddresses.length; i++) {
            lawFirmToSignatories[lawFirmID].push(payable(signatoryWalletAddresses[i]));
        }

        // return value
        return lawFirmID;
    }

    // addClient - done by LawFirm
    function addClient(string memory _name, address _walletAddress, uint256 _lawFirmID) public returns(uint256) {
        // add Client ID into Client ID Array
        clientID += 1;
        clientIDs.push(clientID);

        // add Client into Client Array
        Client memory client = Client(_name, _walletAddress);
        clients.push(client);

        // map Client ID to Client
        clientIDToClient[clientID] = client;  

        // map law firm to client
        lawFirmToClient[_lawFirmID].push(clientID);

        // return value
        return clientID;   
    }

    // Sequence of Events
    // Initiate Transaction 
    // Distribute Platform Fee and Law Firm Initial Payment
    // Add Legal Document
    // Transfer Ownership of Legal Document
    // Distribute Law Firm Concluding Payment

    // Quotation Price: x
    // Platform Fee: 10% of x 
    // Contract / Escrow: 90% of x = y
    // Law Firm Initial Payment: 50% of y
    // Law Firm Concluding Payment: 50% of y

    // distributeLawFirmConcludingPayment - done by Client
    function distributeLawFirmConcludingPayment(uint256 _legalDocumentID) public returns(bool){
        // retrieve quotation ID from legal document ID
        uint256 tempQuotationID = legalDocumentToQuotation[_legalDocumentID];

        // retrieve quotation from quotation ID
        Quotation memory tempQuotation = quotationIDToQuotation[tempQuotationID];

        // retrieve law firm who prepared quotation
        uint256 tempLawFirmID = quotationToLawFirm[tempQuotationID];
        LawFirm memory lawFirm = lawFirmIDToLawFirm[tempLawFirmID];

        // retrieve law firm's wallet address from law firm struct
        address payable tempLawFirmWalletAddress = lawFirm.walletAddress;

        // distribute law firm concluding payment
        (bool lawFirmInitialPaymentSuccess, ) = tempLawFirmWalletAddress.call{value: tempQuotation.lawFirmConcludingPayment}("");
        require(lawFirmInitialPaymentSuccess, "Failed to Distribute Law Firm Concluding Payment!");
        
        // return value 
        return true;
    }

    // distributePlatformFeeAndLawFirmInitialPayment - done by Client
    function distributePlatformFeeAndLawFirmInitialPayment(uint256 _legalDocumentID) public returns(bool){
        // retrieve quotation ID from legal document ID
        uint256 tempQuotationID = legalDocumentToQuotation[_legalDocumentID];

        // retrieve quotation from quotation ID
        Quotation memory tempQuotation = quotationIDToQuotation[tempQuotationID];

        // Owner can receive Ether since the address of owner is payable
        // distribute platform fee to Ebric's wallet address
        (bool platformFeeSuccess, ) = owner.call{value: tempQuotation.platformFee}("");
        require(platformFeeSuccess, "Failed to Distribute Platform Fee!");

        // retrieve law firm who prepared quotation
        uint256 tempLawFirmID = quotationToLawFirm[tempQuotationID];
        LawFirm memory lawFirm = lawFirmIDToLawFirm[tempLawFirmID];

        // retrieve law firm's wallet address from law firm struct
        address payable tempLawFirmWalletAddress = lawFirm.walletAddress;

        // distribute law firm initial payment
        (bool lawFirmInitialPaymentSuccess, ) = tempLawFirmWalletAddress.call{value: tempQuotation.lawFirmInitialPayment}("");
        require(lawFirmInitialPaymentSuccess, "Failed to Distribute Law Firm Initial Payment!");
        
        // return value 
        return true;
    }

    // initiateTransaction - done by Client (payable) #50% of 90% of Quotation Price --> LawFirm #10% of Quotation Price --> Platform / Ebric
    function initiateTransaction(uint256 _quotation, uint256 _lawFirmID, uint256 _clientID) public payable returns(uint256) {
        // _quotation in Wei
        uint256 quotationInWei = _quotation*(10**18);

        // _quotation in Ether
        uint256 quotationPrice = _quotation;

        // modifier --> msg.value should exceed or equal quotationPrice (compare Wei to Wei)
        require(msg.value >= quotationInWei); 

        uint256 platformFee = (quotationInWei * 1) / 10;
        uint256 contractEscrow = (quotationInWei * 9) / 10;
        uint256 lawFirmInitialPayment = (contractEscrow * 5) / 10;
        uint256 lawFirmConcludingPayment = (contractEscrow * 5) / 10;

        // add Quotation ID into Quotation ID Array
        quotationID += 1; 
        quotationIDs.push(quotationID);

        // add Quotation into Quotation Array
        Quotation memory quotation = Quotation(quotationPrice, platformFee, contractEscrow, lawFirmInitialPayment, lawFirmConcludingPayment);
        quotations.push(quotation);

        // map Quotation ID to Quotation
        quotationIDToQuotation[quotationID] = quotation;  
        
        // add Legal Document ID into Legal Document ID Array
        legalDocumentID += 1;
        legalDocumentIDs.push(legalDocumentID);

        // map legal document to quotation by law firm
        legalDocumentToQuotation[legalDocumentID] = quotationID;

        // map quotation to law firm (quotation prepared by)
        quotationToLawFirm[quotationID] = _lawFirmID;

        // map quotation to client (quotation prepared for)
        uint256 tempClientID = _clientID;
        quotationToClient[quotationID] = tempClientID;
        
        // return value
        return legalDocumentID;
    }

    // addLegalDocument - done by LawFirm
    function addLegalDocument(uint256 _legalDocumentID, string memory _name, string memory _docIPFSURI, uint256 _lawFirmID) public returns(uint256) {
        // add Legal Document into Legal Document Array
        LegalDocument memory legalDocument = LegalDocument(_name, _docIPFSURI);
        legalDocuments.push(legalDocument);

        // map Legal Document ID to Legal Document
        legalDocumentIDToLegalDocument[_legalDocumentID] = legalDocument;   

        // map law firm to legal document
        lawFirmToLegalDocument[_lawFirmID].push(_legalDocumentID);

        // map legal document to current owner (Law Firm)
        legalDocumentToCurrentOwner[_legalDocumentID][0] = bytes32("Law Firm");
        legalDocumentToCurrentOwner[_legalDocumentID][1] = bytes32(_lawFirmID);
        
        // return value
        return _legalDocumentID;
    }

    // transferOwnershipOfLegalDocument - done by LawFirm (payable) #50% of Quotation Price --> LawFirm #10% of 50% of Quotation Price --> Platform / Ebric
    function transferOwnershipOfLegalDocument(uint256 _legalDocumentID, uint256 _clientID) public {
        // map client to legal document
        clientToLegalDocument[_clientID].push(_legalDocumentID);

        // map legal document to new owner (Client)
        legalDocumentToCurrentOwner[_legalDocumentID][0] = bytes32("Client");
        legalDocumentToCurrentOwner[_legalDocumentID][1] = bytes32(_clientID);
    }

    // get Law Firm using Law Firm ID
    function getLawFirmByLawFirmID(uint256 _lawFirmID) public view returns(LawFirm memory){
        LawFirm memory tempLawFirm = lawFirmIDToLawFirm[_lawFirmID];
        return tempLawFirm;
    }

    // get Law Firm ID using Law Firm Name
    function getLawFirmIDByLawFirmName(string memory _lawFirmName) public view returns(uint256) {
        uint256 tempLawFirmID;

        for(uint256 i=0; i<lawFirmIDs.length; i++) { // start for loop 
            if(keccak256(abi.encodePacked(lawFirmIDToLawFirm[lawFirmIDs[i]].name)) == keccak256(abi.encodePacked(_lawFirmName))) { // start if statement
                tempLawFirmID = lawFirmIDs[i];
                break;
            } // end if statement
        } // end for loop
        
        return tempLawFirmID;
    }
    
    // get Law Firm ID using Law Firm Wallet Address
    function getLawFirmIDByLawFirmWalletAddress(address _lawFirmWalletAddress) public view returns(uint256) {
        uint256 tempLawFirmID;

         for(uint256 i=0; i<lawFirmIDs.length; i++) { // start for loop 
            if(keccak256(abi.encodePacked(lawFirmIDToLawFirm[lawFirmIDs[i]].walletAddress)) == keccak256(abi.encodePacked(_lawFirmWalletAddress))) { // start if statement
                tempLawFirmID = lawFirmIDs[i];
                break;
            } // end if statement
        } // end for loop
        
        return tempLawFirmID;
    }

    // get Client using Client ID
    function getClientByClientID(uint256 _clientID) public view returns(Client memory){
        Client memory tempClient = clientIDToClient[_clientID];  
        return tempClient;
    }

    // get Client ID using Client Name
    function getClientIDByClientName(string memory _clientName) public view returns(uint256) {
        uint256 tempClientID;

        for(uint256 i=0; i<clientIDs.length; i++) { // start for loop 
            if(keccak256(abi.encodePacked(clientIDToClient[clientIDs[i]].name)) == keccak256(abi.encodePacked(_clientName))) { // start if statement
                tempClientID = clientIDs[i];
                break;
            } // end if statement
        } // end for loop
        
        return tempClientID;
    }

    // get Client ID using Client Wallet Address
    function getClientIDByClientWalletAddress(address _clientWalletAddress) public view returns(uint256) {
        uint256 tempClientID;

         for(uint256 i=0; i<clientIDs.length; i++) { // start for loop 
            if(keccak256(abi.encodePacked(clientIDToClient[clientIDs[i]].walletAddress)) == keccak256(abi.encodePacked(_clientWalletAddress))) { // start if statement
                tempClientID = clientIDs[i];
                break;
            } // end if statement
        } // end for loop
        
        return tempClientID;
    }

    // get Legal Document using Legal Document ID
    function getLegalDocumentByLegalDocumentID(uint256 _legalDocumentID) public view returns(LegalDocument memory){
        LegalDocument memory tempLegalDocument = legalDocumentIDToLegalDocument[_legalDocumentID];  
        return tempLegalDocument;
    }

    // get Legal Document ID using Legal Document Name
     function getLegalDocumentIDByLegalDocumentName(string memory _legalDocumentName) public view returns(uint256) {
        uint256 tempLegalDocumentID;

        for(uint256 i=0; i<legalDocumentIDs.length; i++) { // start for loop 
            if(keccak256(abi.encodePacked(legalDocumentIDToLegalDocument[legalDocumentIDs[i]].name)) == keccak256(abi.encodePacked(_legalDocumentName))) { // start if statement
                tempLegalDocumentID = legalDocumentIDs[i];
                break;
            } // end if statement
        } // end for loop
        
        return tempLegalDocumentID;
    }

    // get Legal Document ID using Legal Document IPFS URI
    function getLegalDocumentIDByLegalDocumentIPFSURI(string memory _legalDocumentIPFSURI) public view returns(uint256) {
        uint256 tempLegalDocumentID;

        for(uint256 i=0; i<legalDocumentIDs.length; i++) { // start for loop 
            if(keccak256(abi.encodePacked(legalDocumentIDToLegalDocument[legalDocumentIDs[i]].docIPFSURI)) == keccak256(abi.encodePacked(_legalDocumentIPFSURI))) { // start if statement
                tempLegalDocumentID = legalDocumentIDs[i];
                break;
            } // end if statement
        } // end for loop
        
        return tempLegalDocumentID;
    }

    // get Current Owner using Legal Document ID
    function getCurrentOwnerByLegalDocument(uint256 _legalDocumentID) public view returns (string memory, uint256){
        string memory ownerType = string(abi.encodePacked(legalDocumentToCurrentOwner[_legalDocumentID][0]));
        uint256 ownerID = uint256(legalDocumentToCurrentOwner[_legalDocumentID][1]);
        return (ownerType, ownerID);
    }

    


}