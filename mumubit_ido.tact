import "@stdlib/deploy";
import "./message.tact";

contract MumubitIdo with Deployable {
    // Empty init() function is present by default in all Tact contracts
    // since v1.3.0, so the following may be omitted:
    
    // owner address
    owner: Address;

    // invest coin coin wallet and project coin wallet address
    // decimals and other initial variables
    this_contract_investCoinWallet: Address?;
    this_contract_projectCoinWallet: Address?;
    invest_coin_address: Address;   
    project_coin_address: Address;
    investCoinDecimals: Int as uint8 = 6;
    projectCoinDecimals: Int as uint8 = 9;

    // maximum number of participants.
    const MAX_PARTICIPANTS: Int = 5000; 
    // IDO records
    index: Int as uint32 = 0;    
    ido_record: map<Address, IdoRecord>;
    ido_list: map<Int, IdoRecord>;

    // the price of project coin, 
    // 500 should be divided by 1000;
    // and the decimals
    project_coin_price: Int as coins = 500;
    // target amount
    ido_target_amount: Int as coins = 0;
    // current amount
    ido_current_amount: Int as coins = 0;
    // claimed amount
    ido_claim_amount: Int as coins =0;
    // start time
    start_time: Int as uint32 = 1720915200;
    // protect time
    protect_time: Int as uint32 = 1720925200;
    // claim time
    claim_time: Int as uint32 =1720935200;
    // end time
    end_time: Int as uint32 = 1720945200;



    // VIP 
    // VIPLimit: map<Int, Int as uint32>;
    // VIPPerLimit: map<Int, Int as uint32>;
    // VIPPerCurrentAmount: map<Int, Int as coins>;
    vip1Limit: Int as coins = 1000000000;
    vip2Limit: Int as coins = 5000000000;
    vip3Limit: Int as coins = 10000000000;

    vip1PerLimit: Int as uint32 = 20;
    vip2PerLimit: Int as uint32 = 30;
    vip3PerLimit: Int as uint32 = 50;

    vip1PerCurrentAmount: Int as coins = 0;
    vip2PerCurrentAmount: Int as coins = 0;
    vip3PerCurrentAmount: Int as coins = 0;

    
    // public key in Int
    publicKey: Int = 11515758040791894312519273808582344479606047423343319073911177921016049419084;  
    // could be withdrawl
    funds_withdrawn: Bool = false; 

    
    // init 
    // In the contract, the corresponding jetton wallet and decimals
    // must be set through separate functions rather than through the initialization function.
    init(investCoinAddress: Address,projectCoinAddress: Address){
        
        self.owner =  sender();        

        self.invest_coin_address = investCoinAddress; 
        self.this_contract_investCoinWallet = null;
        // let myInit=  initOf JettonDefaultWallet(investCoinAddress,myAddress());
        // self.this_contract_investCoinWallet = contractAddress(myInit);
        // self.investCoinDecimals = 6; // ton usdt 6 decimals
    
        self.project_coin_address = projectCoinAddress;
        self.this_contract_projectCoinWallet = null;
        // let initAddress = initOf JettonDefaultWallet(projectCoinAddress,myAddress());
        // self.this_contract_projectCoinWallet = contractAddress(initAddress);
        // self.projectCoinDecimals = 9; // jetton default 9 decimals

        self.ido_target_amount = ton("100");
    }

    // ***********************************/
    

    // get the vip limit
    fun getVipLimit(vipLevel: Int): Int {
        if (vipLevel == 1) {
            return self.vip1Limit;
        } else if (vipLevel == 2) {
            return self.vip2Limit;
        } else if (vipLevel == 3) {
            return self.vip3Limit;
        }
        return 0; 
    }

    // get vip per limit
    fun getVipPerLimit(vipLevel: Int): Int {
        if (vipLevel == 1) {
            return self.vip1PerLimit;
        } else if (vipLevel == 2) {
            return self.vip2PerLimit;
        } else if (vipLevel == 3) {
            return self.vip3PerLimit;
        }
        return 0; 
    }

    // get tue vip current amount
    fun getVipCurrentAmount(vipLevel: Int): Int {
        if (vipLevel == 1) {
            return self.vip1PerCurrentAmount;
        } else if (vipLevel == 2) {
            return self.vip2PerCurrentAmount;
        } else if (vipLevel == 3) {
            return self.vip3PerCurrentAmount;
        }
        return 0; 
    }

    // update the vip current amount
    fun updateVipCurrentAmount(vipLevel: Int, amount: Int) {
        if (vipLevel == 1) {
            self.vip1PerCurrentAmount += amount;
        } else if (vipLevel == 2) {
            self.vip2PerCurrentAmount += amount;
        } else if (vipLevel == 3) {
            self.vip3PerCurrentAmount += amount;
        }
    }

    // decode Jetton Notification's paylaod
    // get the userviplevel, timestamp and signature 
    fun decodePayload(payload: Slice): PayloadData {
        return PayloadData{
            vipLevel: payload.loadUint(8),
            timestamp: payload.loadUint(32),
            signature: payload.loadRef().beginParse()
        };
    }

    // Based on the official documentation, using fromSlice, 
    // if there's a parsing error, it will return a null result. 
    fun cautiousParse(payload: Slice): PayloadData? {
        let data: PayloadData? = null;
        try {
            data = PayloadData.fromSlice(payload);
        } catch (e) {
            dump("Slice payload doesn't match PayloadData Struct!");
        }
        return data;
    }

    // get the params of notification's payload
    // use to verify the signature
    fun verifySignature(userVipLevel: Int, timestamp: Int, amount: Int, from: Address, signature: Slice): Bool {
        let dataToSign = beginCell()
            .storeUint(userVipLevel, 8)
            .storeUint(timestamp, 32)
            .storeAddress(from)
            .storeCoins(amount)
            .endCell();

        return checkSignature(dataToSign.hash(), signature, self.publicKey);
    }

    // Jetton Notification refund Transfer
    // as the sign error 
    fun refundTransfer(to: Address, amount: Int, reason: String) {
        // refund Jetton
        send(SendParameters{
            to: self.this_contract_investCoinWallet!!,
            value: ton("0.1"),
            mode: SendRemainingValue + SendIgnoreErrors,
            body: TokenTransfer{
                query_id: 0,
                amount: amount,
                destination: to,
                response_destination: myAddress(),
                custom_payload: null,
                forward_ton_amount: ton("0.09"),
                forward_payload: beginCell().storeUint(0, 1).endCell().beginParse()
            }.toCell()
        });

        // emit the log info
        emit(TransferEvent{
            sender_address: to,
            jetton_amount: amount,
            ido_action: "participate",
            action_message: reason,
            idoTimestamp: now()
        }.toCell());
        
    }

    // test funs ***********************************/

    fun TestVerifySignature(userVipLevel: Int, timestamp: Int, sender: Address, signature: Slice): Bool {
        let dataToSign = beginCell()
            .storeUint(userVipLevel, 8)
            .storeUint(timestamp, 32)
            .storeAddress(sender)
            .endCell();
        return checkSignature(dataToSign.hash(), signature, self.publicKey);
    }

    // test sign
    receive(msg: TestSignature) {

        dump("Test Signature");
        
        // decode payload
        let payloadData: PayloadData = self.decodePayload(msg.forward_payload);
        let userVipLevel: Int = payloadData.vipLevel;
        let timestamp: Int = payloadData.timestamp;
        let signature: Slice = payloadData.signature;

        dump(userVipLevel);
        dump(timestamp);
        dump(signature);
        dump(self.publicKey);
        dump(sender());

        // length 
        if(signature.bits() == 512){
            dump("Valid signature length");
        }

        // verify
        if (self.TestVerifySignature(userVipLevel, timestamp,sender(),signature)) {
            dump("Valid signature");
            
        }else{
            dump("Invalid signature");  
        }

    }

    // ***********************************/
    // set project info as owner
    // as the price, target amount ,timestamps and so on 
    // excluded the jetton address and decimals
    receive(msg: SetProjectInfo) {
        require(sender() == self.owner, "Only owner can set project info");

        self.project_coin_price = msg.price;

        self.ido_target_amount = msg.targetAmount;

        self.vip1Limit = msg.vip1Allocation;
        self.vip2Limit = msg.vip2Allocation;
        self.vip3Limit = msg.vip3Allocation;

        self.vip1PerLimit = msg.vip1Percent;
        self.vip2PerLimit = msg.vip2Percent;
        self.vip3PerLimit = msg.vip3Percent;

        self.start_time = msg.startTime;
        self.protect_time = msg.protectTime;
        self.claim_time = msg.claimTime;
        self.end_time = msg.endSellTime;

    }

    // set invest coin address after ido started
    receive(msg: SetInvestCoinAddress){
        let ctx: Context = context();
        // check the owner
        require(ctx.sender==self.owner,"Only Owner can set this parameter!");
        // check the time
        require(now() < self.start_time, "Cannot change invest coin address after IDO has started");
        self.invest_coin_address = msg.investCoinAddress;
        self.this_contract_investCoinWallet = msg.this_contract_wallet;
        self.investCoinDecimals = msg.decimals;
        // let initAddress = initOf JettonDefaultWallet(msg.coinAddress,myAddress());
        // self.this_contract_projectCoinWallet = contractAddress(initAddress);
    }
   
    // set project coin address after ido started
    receive(msg: SetProjectCoinAddress){
        let ctx: Context = context();
        // check the owner
        require(ctx.sender==self.owner,"Only Owner can set this parameter!");
        // check the time
        require(now() < self.start_time, "Cannot change project coin address after IDO has started");
        self.project_coin_address = msg.projectCoinAddress;
        self.this_contract_projectCoinWallet = msg.this_contract_wallet;
        self.projectCoinDecimals = msg.decimals; 
        // let initAddress = initOf JettonDefaultWallet(msg.coinAddress,myAddress());
        // self.this_contract_projectCoinWallet = contractAddress(initAddress);
    }

    // set public key
    receive(msg: SetPublicKey) {
        require(sender() == self.owner, "Only owner can set public key");
        self.publicKey = msg.publicKey;
    }

    // set timestamps of start/end protect and claim
    receive(msg: SetIDOTimes) {
        require(sender() == self.owner, "Only owner can set times");
        // check the time
        require(now() < msg.startTime, "Start time must be in the future");
        require(msg.startTime < msg.protectTime, "Protect time must be after start time");
        require(msg.protectTime < msg.claimTime, "Claim time must be after protect time");
        require(msg.claimTime < msg.endTime, "End time must be after claim time");

        self.start_time = msg.startTime;
        self.protect_time = msg.protectTime;
        self.claim_time = msg.claimTime;
        self.end_time = msg.endTime;
    }

    // receive the TokenNotification msg of jetton transfer 
    // use the forward_payload send the signature and other params

    receive(ido: TokenNotification) {
        
        // return when the sender isn't the wallet address of contract
        // ignore other jetton transfers 
        if(context().sender != self.this_contract_investCoinWallet){
            return;
        }
        // gas should be enough
        require(context().value >= ton("0.1"), "not enough value");

        // check the sender again
        require(context().sender == self.this_contract_investCoinWallet, "not from the correct jetton wallet");
        
        // Ensure the maximum number of participants is not exceeded
        if(self.index > self.MAX_PARTICIPANTS){
            dump("Max participants reached");
            self.refundTransfer(ido.from, ido.amount, "Max participants reached");
            return;
        }
        // decode payload
        // let payloadData: PayloadData = self.decodePayload(ido.forward_payload);

        // if wrong paylaod stract,we return jetton to the sender
        let payloadData: PayloadData? = self.cautiousParse(ido.forward_payload);
        if (payloadData == null) {
            dump("Invalid payload");
            self.refundTransfer(ido.from, ido.amount, "Invalid payload");
            return;
        }

        let userVipLevel: Int = payloadData!!.vipLevel;
        let timestamp: Int = payloadData!!.timestamp;
        let signature: Slice = payloadData!!.signature;

        // verify sign
        if (!self.verifySignature(userVipLevel, timestamp, ido.amount, ido.from, signature)) {
            dump("Invalid signature");
            self.refundTransfer(ido.from, ido.amount, "Invalid signature");
            return;
        }
        // check timestamp
        // 
        if (now() < self.start_time || now() > self.protect_time) {
            self.refundTransfer(ido.from, ido.amount, "IDO not active");
            return;
        }

        //
        if (timestamp < self.start_time || timestamp > now()) {
            self.refundTransfer(ido.from, ido.amount, "Invalid transaction timestamp");
            return;
        }

        //  check vip level
        if (userVipLevel < 1 || userVipLevel > 3) {
            self.refundTransfer(ido.from, ido.amount, "Invalid VIP level");
            return;
        }

        // check the vip limit of each level
        let vipLimit: Int = self.getVipLimit(userVipLevel);

        // the vip percent limit of different level
        let vipPerLimit: Int = self.getVipPerLimit(userVipLevel);
        let actualVipLimit: Int = (self.ido_target_amount * vipPerLimit) / 100;

        // get the current amount
        let vipCurrentAmount: Int = self.getVipCurrentAmount(userVipLevel);

        // user invested Amount
        let userRecord: IdoRecord? = self.ido_record.get(ido.from);
        let userInvestedAmount: Int = 0;
        if (userRecord != null) {
            userInvestedAmount = userRecord!!.jettonIdoAmount;
        }
        
        // check the amount and limit
        if (userInvestedAmount + ido.amount > vipLimit ||
            vipCurrentAmount + ido.amount > actualVipLimit ||
            self.ido_current_amount + ido.amount > self.ido_target_amount) 
        {
            self.refundTransfer(ido.from, ido.amount, "Exceeds limit");
            return;
        }
        // yodate
        if (userRecord != null) {
            let oldIdo = userRecord!!;
            oldIdo.jettonIdoAmount += ido.amount;
            oldIdo.investedAt = now();
            self.ido_record.set(ido.from, oldIdo);
        } else {
            self.ido_record.set(ido.from,
                IdoRecord{
                    investCoinAddress: self.invest_coin_address, 
                    investorAddress: ido.from,
                    jettonIdoAmount: ido.amount,
                    jettonRefundAmount: 0,
                    projectCoinClaimedAmount: 0,
                    investedAt: now(),
                    refundedAt: 0,
                    claimedAt: 0
                }
            );
            self.ido_list.set(self.index, self.ido_record.get(ido.from)!!);
            self.index += 1;
        }

        // update invest amount of current time
        self.ido_current_amount += ido.amount;

        // update vip current amount
        self.updateVipCurrentAmount(userVipLevel, ido.amount);

        
        emit(TransferEvent{
            sender_address: ido.from,
            jetton_amount: ido.amount,
            ido_action: "participate",
            action_message: "success",
            idoTimestamp: now()
        }.toCell());
    }

    // Refund 
    receive("Refund") {

        // time check
        require(now() > self.protect_time && now() < self.claim_time, "Refund is only allowed between protect time and claim time");

        // gas check
        require(context().value >= ton("0.1"), "Not enough value provided for gas");

        // get the record of this user
        let sender: Address = sender();
        let userRecord: IdoRecord? = self.ido_record.get(sender);
        require(userRecord != null, "No IDO record found for this address");

        let oldIdo: IdoRecord = userRecord!!;
        
        // check whether claimed out
        require(oldIdo.jettonRefundAmount == 0 && oldIdo.projectCoinClaimedAmount == 0, "Already refunded or claimed");

        // refund
        send(SendParameters{
            to: self.this_contract_investCoinWallet!!,
            value: 0,
            mode: (SendRemainingValue + SendIgnoreErrors),
            body: TokenTransfer{
                query_id: 0,
                amount: oldIdo.jettonIdoAmount,
                destination: sender,
                response_destination: myAddress(),
                custom_payload: null,
                forward_ton_amount: ton("0.01"),
                forward_payload: beginCell().storeUint(0, 1).endCell().beginParse()
            }.toCell()
        });

        // update 
        self.ido_record.set(sender,
            IdoRecord{
                investCoinAddress: oldIdo.investCoinAddress,
                investorAddress: sender,
                jettonIdoAmount: 0,
                jettonRefundAmount: oldIdo.jettonIdoAmount,
                projectCoinClaimedAmount: 0,
                investedAt: oldIdo.investedAt,
                refundedAt: now(),
                claimedAt: 0
            }    
        );

        // update current amount after refund
        self.ido_current_amount -= oldIdo.jettonIdoAmount;

        // 
        emit(TransferEvent{
            sender_address: sender,
            jetton_amount: oldIdo.jettonIdoAmount,
            ido_action: "refund",
            action_message: "success",
            idoTimestamp: now()
        }.toCell());

    }

    // claim
    receive("Claim") {

        // time check
        require(now() >= self.claim_time, "Claiming is not allowed before claim time");

        //  gas check
        require(context().value >= ton("0.1"), "Not enough value provided for gas");

        // record check
        let sender: Address = sender();
        let userRecord: IdoRecord? = self.ido_record.get(sender);
        require(userRecord != null, "No IDO record found for this address");

        let oldIdo: IdoRecord = userRecord!!;
        
        // not claimed out or refund out
        require(oldIdo.projectCoinClaimedAmount == 0 && oldIdo.jettonRefundAmount == 0, "Already claimed or refunded");

        // check amount for claim
        // let claimAmount: Int = (oldIdo.jettonIdoAmount * 1000) / self.project_coin_price;
        // calculate the 1000 factor of decimals diff between project_coin_price and invest coin price 
        let decimalsDiff: Int = self.projectCoinDecimals - self.investCoinDecimals;
        let claimAmount: Int = 0;
        if (decimalsDiff >= 0) {
            let adjustedAmount: Int = oldIdo.jettonIdoAmount * pow(10, decimalsDiff);
            claimAmount = (adjustedAmount * 1000) / self.project_coin_price;
        } else {
            let adjustedPrice: Int = self.project_coin_price * pow(10, -decimalsDiff);
            claimAmount = (oldIdo.jettonIdoAmount * 1000) / adjustedPrice;
        }
        // let adjustedAmount: Int = oldIdo.jettonIdoAmount * pow(10, decimalsDiff);
        // let claimAmount: Int =  (adjustedAmount * 1000) / self.project_coin_price;

        // transfer project coin to invest user
        send(SendParameters{
            to: self.this_contract_projectCoinWallet!!,
            value: 0,
            mode: (SendRemainingValue + SendIgnoreErrors),
            body: TokenTransfer{
                query_id: 0,
                amount: claimAmount,
                destination: sender,
                response_destination: myAddress(),
                custom_payload: null,
                forward_ton_amount: ton("0.01"),
                forward_payload: beginCell().storeUint(0, 1).endCell().beginParse()
            }.toCell()
        });

        // update record
        self.ido_record.set(sender,
            IdoRecord{
                investCoinAddress: oldIdo.investCoinAddress,
                investorAddress: sender,
                jettonIdoAmount: oldIdo.jettonIdoAmount,
                jettonRefundAmount: 0,
                projectCoinClaimedAmount: claimAmount,
                investedAt: oldIdo.investedAt,
                refundedAt: 0,
                claimedAt: now()
            }    
        );

        // update claim amount
        self.ido_claim_amount += claimAmount;

        // emit log Info
        emit(TransferEvent{
            sender_address: sender,
            jetton_amount: claimAmount,
            ido_action: "claim",
            action_message: "success",
            idoTimestamp: now()
        }.toCell());

    }

    // with the remains to the project manager
    receive(msg: WithdrawFunds) {
        // owner check
        require(sender() == self.owner, "Only owner can withdraw funds");

        // check timestamp should after the end_time
        require(now() >= self.end_time, "IDO has not ended yet");
        
        // where reached the target
        // require(self.ido_current_amount >= self.ido_target_amount, "IDO target not reached");

        // check where withdrawed out
        require(!self.funds_withdrawn, "Funds have already been withdrawn");

        // set the flag of withdraw
        self.funds_withdrawn = true;

        // get the ido current amount jettons
        let amount_to_send: Int = self.ido_current_amount;

        // send to the owner's address
        send(SendParameters{
            to: self.this_contract_investCoinWallet!!,
            value: 0,
            mode: (SendRemainingValue + SendIgnoreErrors),
            body: TokenTransfer{
                query_id: 0,
                amount: amount_to_send,
                destination: msg.destination,
                response_destination: myAddress(),
                custom_payload: null,
                forward_ton_amount: ton("0.01"),
                forward_payload: beginCell().storeUint(0, 1).endCell().beginParse()
            }.toCell()
        });

        // emit log
        emit(TransferEvent{
            sender_address: myAddress(),
            jetton_amount: amount_to_send,
            ido_action: "withdraw_funds",
            action_message: "Funds withdrawn by owner",
            idoTimestamp: now()
        }.toCell());
    } 

    //  ***********************************/

    // //ido project info geter
    get fun idoInfo(): ProjectInfoGet{
        dump("get Ido Info");
        return ProjectInfoGet{
            price: self.project_coin_price,
            targetAmount: self.ido_target_amount,
            currentAmount: self.ido_current_amount,
            participants: self.index,
            raiseCoinAddress: self.project_coin_address,
            moneyAddress: self.invest_coin_address,
            vip1Allocation: self.vip1Limit,
            vip2Allocation: self.vip2Limit,
            vip3Allocation: self.vip3Limit,
            vip1Percent: self.vip1PerLimit,
            vip2Percent: self.vip2PerLimit,
            vip3Percent: self.vip3PerLimit,
            startTime: self.start_time,
            endSellTime: self.end_time,
            protectTime: self.protect_time,
            claimTime: self.claim_time,
            claimedAmount: self.ido_claim_amount,
            vip1CurrentAmount: self.vip1PerCurrentAmount,
            vip2CurrentAmount: self.vip2PerCurrentAmount,
            vip3CurrentAmount: self.vip3PerCurrentAmount,
            investCoinDecimals: self.investCoinDecimals,
            projectCoinDecimals: self.projectCoinDecimals,
            investCoinWallet: self.this_contract_investCoinWallet!!,
            projectCoinWallet: self.this_contract_projectCoinWallet!!
        };
    }

    // get user ido info
    get fun userIdoInfo(userAddress: Address): IdoRecord{
        let oldIdo: IdoRecord = self.ido_record.get(userAddress)!!;
        return oldIdo;
    }

    // invest coin address
    get fun investCoin(): Address {
        return self.invest_coin_address;
    }

    // current invest amount
    get fun investAmount(): Int {
        return self.ido_current_amount;
    }

    // index for current investers
    get fun index(): Int {
        return self.index;
    }

    // get publickey
    get fun publickey(): Int {
        return self.publicKey;
    }
}
