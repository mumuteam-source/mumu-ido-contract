// ===== Data Struct ===== //
 
struct PayloadData {
    vipLevel: Int as uint8;
    timestamp: Int as uint32;
    signature: Slice;
}

struct IdoData {
    index: Int as uint64;
    this_contract_jettonWallet: Address;
    total_score: Int as coins;
    parameter: Int as uint16;
}
struct IdoRecord {
    investCoinAddress: Address; //USDT or some stable coins 
    investorAddress: Address;   //Jetton Master Wallet Address
    jettonIdoAmount: Int as coins; //user invested Amount of Jetton
    jettonRefundAmount: Int as coins;
    projectCoinClaimedAmount: Int as coins;
    investedAt: Int as uint32;
    refundedAt: Int as uint32;
    claimedAt: Int as uint32;
}

struct ProjectInfoGet {
    price: Int as uint32;
    targetAmount: Int as coins;
    currentAmount: Int as coins;
    participants: Int as uint32;
    raiseCoinAddress: Address;
    moneyAddress: Address;
    vip1Allocation: Int as coins;
    vip2Allocation: Int as coins;
    vip3Allocation: Int as coins;
    vip1Percent: Int as uint32;
    vip2Percent: Int as uint32;
    vip3Percent: Int as uint32;
    vip1CurrentAmount: Int as coins;
    vip2CurrentAmount: Int as coins;
    vip3CurrentAmount: Int as coins;
    investCoinDecimals: Int as uint8;
    projectCoinDecimals: Int as uint8;
    startTime: Int as uint32;
    endSellTime: Int as uint32;
    protectTime: Int as uint32;
    claimTime: Int as uint32;
    raiseStatus: Int as uint16;
    claimedAmount: Int as coins;
    investCoinWallet: Address;
    projectCoinWallet: Address;
    // vip1CurrentAmount: Int as uint32;
    // vip2CurrentAmount: Int as uint32;
    // vip3CurrentAmount: Int as uint32;
    }
// ===== TEP64 Standard: Jetton Messages ===== //
message(0xf8a7ea5) TokenTransfer {
    query_id: Int as uint64;
    amount: Int as coins;
    destination: Address;
    response_destination: Address;
    custom_payload: Cell?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining; // Comment Text message when Transfer the jetton
}

message(0x178d4519) TokenTransferInternal {
    query_id: Int as uint64;
    amount: Int as coins;
    from: Address;
    response_destination: Address;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining; // Comment Text message when Transfer the jetton
}

message(0x7362d09c) TokenNotification {
    query_id: Int as uint64;
    amount: Int as coins;
    from: Address;
    forward_payload: Slice as remaining; // Comment Text message when Transfer the jetton 
}

// For the end-point of the Tx, this data means nothing important.
// (Ref: https://github.com/ton-blockchain/TEPs/blob/master/text/0074-jettons-standard.md)
// ===== LOG Event ===== //
message TransferEvent {
    sender_address: Address;
    jetton_amount: Int as coins;
    ido_action: String;
    action_message: String;
    idoTimestamp: Int as uint32;
}

// ================================================================================ //
message UserIdo {
    from: Address;
    amount: Int as coins;
}
message Refund {
    from: Address;
    amount: Int as coins;
}

message Claim {
    from: Address;
    amount: Int as uint64;
}
message Redeem {
    queryId: Int as uint64;
    project_id: Int as uint16;
}
message GetWeighted {
    // ===== on-chain fetch ===== //
    applied_user_address: Address;
}

message SetProjectCoinAddress {
    projectCoinAddress: Address;
    this_contract_wallet:Address;
    decimals: Int as uint8;
}

message SetInvestCoinAddress {
    investCoinAddress: Address;
    this_contract_wallet:Address;
    decimals: Int as uint8;
}


message SetPublicKey{
    publicKey: Int;
}

message SetIDOTimes {
    startTime: Int as uint32;
    protectTime: Int as uint32;
    claimTime: Int as uint32;
    endTime: Int as uint32;
}

message WithdrawFunds {
    destination: Address;
}

message TestSignature {
    forward_payload: Slice as remaining; 
}

message SetProjectInfo {
    price: Int as uint32;
    targetAmount: Int as coins;
    vip1Allocation: Int as coins;
    vip2Allocation: Int as coins;
    vip3Allocation: Int as coins;
    vip1Percent: Int as uint32;
    vip2Percent: Int as uint32;
    vip3Percent: Int as uint32;
    startTime: Int as uint32;
    endSellTime: Int as uint32;
    protectTime: Int as uint32;
    claimTime: Int as uint32;
    raiseStatus: Int as uint16;
}
