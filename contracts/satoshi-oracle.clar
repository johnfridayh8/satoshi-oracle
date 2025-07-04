;; SatoshiOracle - Decentralized Bitcoin Price Prediction Protocol
;;
;; A trustless prediction market protocol built on Stacks, enabling users to 
;; speculate on Bitcoin price movements while maintaining complete self-custody
;; of their assets. Harness the power of collective market intelligence through
;; transparent, oracle-driven settlement mechanisms.
;;
;; Core Innovation:
;; SatoshiOracle eliminates traditional market maker dependencies by creating
;; peer-to-peer prediction pools where participants stake STX tokens on Bitcoin
;; price direction. Winners automatically receive proportional rewards from the
;; losing side's pool, creating a zero-sum game with transparent economics.
;;
;; Architecture Highlights:
;; - Fully non-custodial design preserving user sovereignty
;; - Atomic settlement via Stacks L2 smart contracts
;; - Programmable oracle integration for price resolution
;; - Transparent fee structure with no hidden costs
;; - Bitcoin-native focus aligning with Stacks ecosystem values
;;

;; CONSTANTS & ERROR HANDLING

(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-OWNER-ONLY (err u100))
(define-constant ERR-INVALID-PARAMETER (err u101))
(define-constant ERR-NOT-FOUND (err u102))
(define-constant ERR-MARKET-CLOSED (err u103))
(define-constant ERR-INVALID-PREDICTION (err u104))
(define-constant ERR-INSUFFICIENT-BALANCE (err u105))
(define-constant ERR-ALREADY-CLAIMED (err u106))

;; PROTOCOL CONFIGURATION

;; Oracle configuration for external price feeds
(define-data-var oracle-address principal 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)

;; Market participation parameters
(define-data-var minimum-stake uint u1000000) ;; 1.0 STX minimum stake
(define-data-var protocol-fee uint u2)        ;; 2% protocol fee on winnings
(define-data-var market-counter uint u0)      ;; Global market ID counter

;; DATA STRUCTURES

;; Market definition and state tracking
(define-map markets
  uint ;; Market ID
  {
    opening-price: uint,      ;; BTC/USD opening price (satoshis)
    closing-price: uint,      ;; BTC/USD closing price (satoshis)
    bull-commitment: uint,    ;; Total bullish positions (STX)
    bear-commitment: uint,    ;; Total bearish positions (STX)
    activation-block: uint,   ;; Market start block height
    expiration-block: uint,   ;; Market end block height
    resolution-status: bool,  ;; Settlement completion flag
  }
)

;; User position tracking
(define-map positions
  {
    market: uint,
    participant: principal,
  } ;; Composite key
  {
    direction: (string-ascii 4), ;; Position type: "bull" or "bear"
    amount: uint,                ;; STX amount committed
    claimed: bool,               ;; Reward claim status
  }
)

;; MARKET CREATION & MANAGEMENT

;; Creates a new Bitcoin price prediction market
(define-public (create-market
    (opening-price uint)
    (activation-block uint)
    (expiration-block uint)
  )
  (let ((new-market-id (var-get market-counter)))
    ;; Authorization check
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-OWNER-ONLY)
    
    ;; Parameter validation
    (asserts! (> expiration-block activation-block) ERR-INVALID-PARAMETER)
    (asserts! (> opening-price u0) ERR-INVALID-PARAMETER)
    
    ;; Initialize new market
    (map-set markets new-market-id {
      opening-price: opening-price,
      closing-price: u0,
      bull-commitment: u0,
      bear-commitment: u0,
      activation-block: activation-block,
      expiration-block: expiration-block,
      resolution-status: false,
    })
    
    ;; Increment market counter
    (var-set market-counter (+ new-market-id u1))
    (ok new-market-id)
  )
)

;; MARKET PARTICIPATION

;; Allows users to take positions on Bitcoin price direction
(define-public (take-position
    (market-id uint)
    (position (string-ascii 4))
    (stake uint)
  )
  (let (
      (market (unwrap! (map-get? markets market-id) ERR-NOT-FOUND))
      (current-block stacks-block-height)
    )
    ;; Market timing validation
    (asserts!
      (and
        (>= current-block (get activation-block market))
        (< current-block (get expiration-block market))
      )
      ERR-MARKET-CLOSED
    )
    
    ;; Position validation
    (asserts! (or (is-eq position "bull") (is-eq position "bear"))
      ERR-INVALID-PREDICTION
    )
    (asserts! (>= stake (var-get minimum-stake)) ERR-INVALID-PARAMETER)
    
    ;; Balance verification
    (asserts! (<= stake (stx-get-balance tx-sender)) ERR-INSUFFICIENT-BALANCE)
    
    ;; Transfer stake to contract
    (try! (stx-transfer? stake tx-sender (as-contract tx-sender)))
    
    ;; Record user position
    (map-set positions {
      market: market-id,
      participant: tx-sender,
    } {
      direction: position,
      amount: stake,
      claimed: false,
    })
    
    ;; Update market commitments
    (map-set markets market-id
      (merge market {
        bull-commitment: (if (is-eq position "bull")
          (+ (get bull-commitment market) stake)
          (get bull-commitment market)
        ),
        bear-commitment: (if (is-eq position "bear")
          (+ (get bear-commitment market) stake)
          (get bear-commitment market)
        ),
      })
    )
    (ok true)
  )
)

;; MARKET RESOLUTION

;; Settles market with final Bitcoin price from oracle
(define-public (settle-market
    (market-id uint)
    (closing-price uint)
  )
  (let ((market (unwrap! (map-get? markets market-id) ERR-NOT-FOUND)))
    ;; Authorization check - only oracle can settle
    (asserts! (is-eq tx-sender (var-get oracle-address)) ERR-OWNER-ONLY)
    
    ;; Timing validation
    (asserts! (>= stacks-block-height (get expiration-block market))
      ERR-MARKET-CLOSED
    )
    (asserts! (not (get resolution-status market)) ERR-MARKET-CLOSED)
    (asserts! (> closing-price u0) ERR-INVALID-PARAMETER)
    
    ;; Finalize market with closing price
    (map-set markets market-id
      (merge market {
        closing-price: closing-price,
        resolution-status: true,
      })
    )
    (ok true)
  )
)

;; REWARD DISTRIBUTION

;; Processes reward claims for winning positions
(define-public (claim-rewards (market-id uint))
  (let (
      (market (unwrap! (map-get? markets market-id) ERR-NOT-FOUND))
      (position (unwrap!
        (map-get? positions {
          market: market-id,
          participant: tx-sender,
        })
        ERR-NOT-FOUND
      ))
    )
    ;; Claim eligibility validation
    (asserts! (get resolution-status market) ERR-MARKET-CLOSED)
    (asserts! (not (get claimed position)) ERR-ALREADY-CLAIMED)
    
    (let (
        (winning-side (if (> (get closing-price market) (get opening-price market))
          "bull"
          "bear"
        ))
        (total-commitment (+ (get bull-commitment market) (get bear-commitment market)))
        (winning-pool (if (is-eq winning-side "bull")
          (get bull-commitment market)
          (get bear-commitment market)
        ))
      )
      ;; Verify user picked winning side
      (asserts! (is-eq (get direction position) winning-side)
        ERR-INVALID-PREDICTION
      )
      
      (let (
          (gross-reward (/ (* (get amount position) total-commitment) winning-pool))
          (protocol-fee-amount (/ (* gross-reward (var-get protocol-fee)) u100))
          (net-payout (- gross-reward protocol-fee-amount))
        )
        ;; Distribute rewards
        (try! (as-contract (stx-transfer? net-payout (as-contract tx-sender) tx-sender)))
        (try! (as-contract (stx-transfer? protocol-fee-amount (as-contract tx-sender) CONTRACT-OWNER)))
        
        ;; Mark position as claimed
        (map-set positions {
          market: market-id,
          participant: tx-sender,
        }
          (merge position { claimed: true })
        )
        (ok net-payout)
      )
    )
  )
)