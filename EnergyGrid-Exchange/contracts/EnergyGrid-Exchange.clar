;; EnergyGrid-Exchange - Data Marketplace Smart Contract
;; A marketplace for buying and selling structured energy grid data

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-insufficient-funds (err u102))
(define-constant err-unauthorized (err u103))
(define-constant err-already-exists (err u104))
(define-constant err-invalid-price (err u105))
(define-constant err-data-not-available (err u106))

;; Data Variables
(define-data-var contract-fee uint u250) ;; 2.5% fee (250/10000)
(define-data-var next-data-id uint u1)

;; Data Maps
(define-map data-listings
  { data-id: uint }
  {
    seller: principal,
    title: (string-ascii 100),
    description: (string-ascii 500),
    data-type: (string-ascii 50), ;; e.g., "consumption", "generation", "grid-load"
    price: uint,
    metadata-hash: (string-ascii 64), ;; IPFS hash or similar
    active: bool,
    created-at: uint
  }
)

(define-map data-purchases
  { buyer: principal, data-id: uint }
  {
    purchased-at: uint,
    price-paid: uint,
    access-granted: bool
  }
)

(define-map seller-stats
  { seller: principal }
  {
    total-sales: uint,
    total-revenue: uint,
    data-count: uint
  }
)

(define-map buyer-stats
  { buyer: principal }
  {
    total-purchases: uint,
    total-spent: uint
  }
)

;; Read-only functions
(define-read-only (get-data-listing (data-id uint))
  (map-get? data-listings { data-id: data-id })
)

(define-read-only (get-purchase-record (buyer principal) (data-id uint))
  (map-get? data-purchases { buyer: buyer, data-id: data-id })
)

(define-read-only (get-seller-stats (seller principal))
  (default-to 
    { total-sales: u0, total-revenue: u0, data-count: u0 }
    (map-get? seller-stats { seller: seller })
  )
)

(define-read-only (get-buyer-stats (buyer principal))
  (default-to 
    { total-purchases: u0, total-spent: u0 }
    (map-get? buyer-stats { buyer: buyer })
  )
)

(define-read-only (get-contract-fee)
  (var-get contract-fee)
)

(define-read-only (get-next-data-id)
  (var-get next-data-id)
)

(define-read-only (has-access (buyer principal) (data-id uint))
  (match (map-get? data-purchases { buyer: buyer, data-id: data-id })
    purchase (get access-granted purchase)
    false
  )
)

;; Private functions
(define-private (update-seller-stats (seller principal) (revenue uint))
  (let (
    (current-stats (get-seller-stats seller))
  )
    (map-set seller-stats
      { seller: seller }
      {
        total-sales: (+ (get total-sales current-stats) u1),
        total-revenue: (+ (get total-revenue current-stats) revenue),
        data-count: (get data-count current-stats)
      }
    )
  )
)

(define-private (update-buyer-stats (buyer principal) (amount uint))
  (let (
    (current-stats (get-buyer-stats buyer))
  )
    (map-set buyer-stats
      { buyer: buyer }
      {
        total-purchases: (+ (get total-purchases current-stats) u1),
        total-spent: (+ (get total-spent current-stats) amount)
      }
    )
  )
)

(define-private (calculate-fee (price uint))
  (/ (* price (var-get contract-fee)) u10000)
)

;; Public functions

;; List new data for sale
(define-public (list-data 
  (title (string-ascii 100))
  (description (string-ascii 500))
  (data-type (string-ascii 50))
  (price uint)
  (metadata-hash (string-ascii 64))
)
  (let (
    (data-id (var-get next-data-id))
    (seller tx-sender)
  )
    (asserts! (> price u0) err-invalid-price)
    
    ;; Create data listing
    (map-set data-listings
      { data-id: data-id }
      {
        seller: seller,
        title: title,
        description: description,
        data-type: data-type,
        price: price,
        metadata-hash: metadata-hash,
        active: true,
        created-at: stacks-block-height
      }
    )
    
    ;; Update seller stats
    (let (
      (current-stats (get-seller-stats seller))
    )
      (map-set seller-stats
        { seller: seller }
        {
          total-sales: (get total-sales current-stats),
          total-revenue: (get total-revenue current-stats),
          data-count: (+ (get data-count current-stats) u1)
        }
      )
    )
    
    ;; Increment next data ID
    (var-set next-data-id (+ data-id u1))
    
    (ok data-id)
  )
)

;; Purchase data
(define-public (purchase-data (data-id uint))
  (let (
    (buyer tx-sender)
    (listing (unwrap! (map-get? data-listings { data-id: data-id }) err-not-found))
    (price (get price listing))
    (seller (get seller listing))
    (fee (calculate-fee price))
    (seller-amount (- price fee))
  )
    ;; Check if listing is active
    (asserts! (get active listing) err-data-not-available)
    
    ;; Check if buyer already purchased this data
    (asserts! (is-none (map-get? data-purchases { buyer: buyer, data-id: data-id })) err-already-exists)
    
    ;; Transfer payment from buyer to seller
    (try! (stx-transfer? seller-amount buyer seller))
    
    ;; Transfer fee to contract owner
    (try! (stx-transfer? fee buyer contract-owner))
    
    ;; Record purchase
    (map-set data-purchases
      { buyer: buyer, data-id: data-id }
      {
        purchased-at: stacks-block-height,
        price-paid: price,
        access-granted: true
      }
    )
    
    ;; Update stats
    (update-seller-stats seller seller-amount)
    (update-buyer-stats buyer price)
    
    (ok true)
  )
)

;; Update data listing (seller only)
(define-public (update-listing 
  (data-id uint)
  (new-price uint)
  (new-description (string-ascii 500))
  (active bool)
)
  (let (
    (listing (unwrap! (map-get? data-listings { data-id: data-id }) err-not-found))
  )
    ;; Check if caller is the seller
    (asserts! (is-eq tx-sender (get seller listing)) err-unauthorized)
    (asserts! (> new-price u0) err-invalid-price)
    
    ;; Update listing
    (map-set data-listings
      { data-id: data-id }
      (merge listing {
        price: new-price,
        description: new-description,
        active: active
      })
    )
    
    (ok true)
  )
)

;; Deactivate listing (seller only)
(define-public (deactivate-listing (data-id uint))
  (let (
    (listing (unwrap! (map-get? data-listings { data-id: data-id }) err-not-found))
  )
    ;; Check if caller is the seller
    (asserts! (is-eq tx-sender (get seller listing)) err-unauthorized)
    
    ;; Deactivate listing
    (map-set data-listings
      { data-id: data-id }
      (merge listing { active: false })
    )
    
    (ok true)
  )
)

;; Get data access (for purchased data)
(define-public (get-data-access (data-id uint))
  (let (
    (buyer tx-sender)
    (purchase (unwrap! (map-get? data-purchases { buyer: buyer, data-id: data-id }) err-unauthorized))
    (listing (unwrap! (map-get? data-listings { data-id: data-id }) err-not-found))
  )
    ;; Check if access is granted
    (asserts! (get access-granted purchase) err-unauthorized)
    
    ;; Return metadata hash for data access
    (ok (get metadata-hash listing))
  )
)

;; Admin functions (contract owner only)

;; Update contract fee
(define-public (set-contract-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (<= new-fee u1000) err-invalid-price) ;; Max 10% fee
    (var-set contract-fee new-fee)
    (ok true)
  )
)

;; Emergency: revoke data access
(define-public (revoke-access (buyer principal) (data-id uint))
  (let (
    (purchase (unwrap! (map-get? data-purchases { buyer: buyer, data-id: data-id }) err-not-found))
  )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    
    (map-set data-purchases
      { buyer: buyer, data-id: data-id }
      (merge purchase { access-granted: false })
    )
    
    (ok true)
  )
)