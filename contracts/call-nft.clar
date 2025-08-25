;; Call Protocol NFT Contract
;; A decentralized NFT platform for creating, minting, and trading unique digital assets
;; with advanced ownership, trading, and generative mechanics on the Stacks blockchain.

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-ALREADY-LISTED (err u101))
(define-constant ERR-NOT-LISTED (err u102))
(define-constant ERR-LISTING-EXPIRED (err u103))
(define-constant ERR-INVALID-PRICE (err u104))
(define-constant ERR-NFT-NOT-FOUND (err u105))
(define-constant ERR-DUPLICATE-PATTERN (err u106))
(define-constant ERR-INVALID-PARAMETERS (err u107))
(define-constant ERR-INSUFFICIENT-FUNDS (err u108))
(define-constant ERR-TRANSFER-FAILED (err u109))
(define-constant ERR-NOT-OWNER (err u110))

;; SIP-009 NFT Interface
(define-trait nft-trait
  (
    ;; Transfer token to a specified principal
    (transfer (uint principal principal) (response bool uint))
    ;; Get the token owner
    (get-owner (uint) (response principal uint))
    ;; Get the last token ID
    (get-last-token-id () (response uint uint))
    ;; Get the token URI
    (get-token-uri (uint) (response (optional (string-ascii 256)) uint))
  )
)

;; Data variables
(define-data-var last-token-id uint u0)
(define-data-var contract-owner principal tx-sender)
(define-data-var royalty-percentage uint u50) ;; 5.0% (represented as 50 for 5.0%)
(define-data-var mint-price uint u10000000) ;; 10 STX

;; NFT ownership tracking
(define-map token-owners uint principal)

;; Lattice pattern parameters storage
(define-map lattice-parameters 
  uint
  {
    seed: uint,                ;; Random seed for pattern generation
    lattice-type: (string-utf8 20),  ;; Type of lattice (e.g., "square", "hexagonal", "triangular")
    dimensions: {              ;; Pattern dimensions
      width: uint,
      height: uint
    },
    complexity: uint,          ;; Complexity parameter (affects number of nodes/connections)
    color-scheme: {            ;; Color scheme information
      primary: (string-utf8 20),
      secondary: (string-utf8 20),
      background: (string-utf8 20)
    },
    metadata-uri: (string-ascii 256) ;; URI for off-chain metadata/image
  }
)

;; Uniqueness verification - hash of parameters to token ID
(define-map pattern-hashes (buff 32) uint)

;; Track original creator for royalties
(define-map token-creators uint principal)

;; Marketplace listings
(define-map token-listings
  uint
  {
    price: uint,
    seller: principal,
    expiry: uint
  }
)



;; Generate a new token ID
(define-private (generate-new-token-id)
  (let ((new-id (+ (var-get last-token-id) u1)))
    (var-set last-token-id new-id)
    new-id
  )
)

;; Calculate royalty amount based on sale price
(define-private (calculate-royalty (sale-price uint))
  (/ (* sale-price (var-get royalty-percentage)) u1000)
)

;; Check if caller is the owner of the token
(define-private (is-owner (token-id uint) (caller principal))
  (match (map-get? token-owners token-id)
    owner (is-eq owner caller)
    false
  )
)

;; Transfer funds to a recipient
(define-private (transfer-funds (amount uint) (recipient principal))
  (stx-transfer? amount tx-sender recipient)
)

;; Public functions


;; Transfer ownership of an NFT
(define-public (transfer (token-id uint) (sender principal) (recipient principal))
  (begin
    (asserts! (is-owner token-id sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq tx-sender sender) ERR-NOT-AUTHORIZED)
    ;; Remove from listing if it's listed
    (match (map-get? token-listings token-id)
      listing (map-delete token-listings token-id)
      true
    )
    ;; Update ownership
    (map-set token-owners token-id recipient)
    (ok true)
  )
)

;; Read-only functions

;; Get the owner of a token
(define-read-only (get-owner (token-id uint))
  (match (map-get? token-owners token-id)
    owner (ok owner)
    (err ERR-NFT-NOT-FOUND)
  )
)

;; Get the metadata URI for a token
(define-read-only (get-token-uri (token-id uint))
  (match (map-get? lattice-parameters token-id)
    params (ok (some (get metadata-uri params)))
    (err ERR-NFT-NOT-FOUND)
  )
)

;; Get the last token ID
(define-read-only (get-last-token-id)
  (ok (var-get last-token-id))
)

;; Get the creator of a token
(define-read-only (get-token-creator (token-id uint))
  (match (map-get? token-creators token-id)
    creator (ok creator)
    (err ERR-NFT-NOT-FOUND)
  )
)

;; Get the lattice parameters for a token
(define-read-only (get-lattice-parameters (token-id uint))
  (match (map-get? lattice-parameters token-id)
    params (ok params)
    (err ERR-NFT-NOT-FOUND)
  )
)

;; Contract administration functions

;; Update the mint price
(define-public (set-mint-price (new-price uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (var-set mint-price new-price)
    (ok true)
  )
)

;; Update the royalty percentage
(define-public (set-royalty-percentage (new-percentage uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (asserts! (<= new-percentage u300) ERR-INVALID-PARAMETERS) ;; Max 30%
    (var-set royalty-percentage new-percentage)
    (ok true)
  )
)

;; Transfer contract ownership
(define-public (transfer-contract-ownership (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (var-set contract-owner new-owner)
    (ok true)
  )
)