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