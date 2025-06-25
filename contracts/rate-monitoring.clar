;; Rate Monitoring Contract
;; Manages exchange rate tracking and updates

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u200))
(define-constant ERR-INVALID-RATE (err u201))
(define-constant ERR-PAIR-NOT-FOUND (err u202))
(define-constant MAX-RATE-AGE u144) ;; ~24 hours in blocks

;; Data Variables
(define-data-var oracle-address principal tx-sender)

;; Data Maps
(define-map exchange-rates
  { pair: (string-ascii 10) }
  {
    rate: uint,
    timestamp: uint,
    updated-by: principal
  }
)

(define-map rate-history
  { pair: (string-ascii 10), block: uint }
  { rate: uint }
)

;; Public Functions

;; Update exchange rate (oracle only)
(define-public (update-rate (pair (string-ascii 10)) (rate uint))
  (begin
    (asserts! (or (is-eq tx-sender CONTRACT-OWNER) (is-eq tx-sender (var-get oracle-address))) ERR-NOT-AUTHORIZED)
    (asserts! (> rate u0) ERR-INVALID-RATE)

    ;; Store in history
    (map-set rate-history
      { pair: pair, block: block-height }
      { rate: rate }
    )

    ;; Update current rate
    (map-set exchange-rates
      { pair: pair }
      {
        rate: rate,
        timestamp: block-height,
        updated-by: tx-sender
      }
    )
    (ok true)
  )
)

;; Set oracle address (admin only)
(define-public (set-oracle (new-oracle principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (var-set oracle-address new-oracle)
    (ok true)
  )
)

;; Read-only Functions

;; Get current rate
(define-read-only (get-rate (pair (string-ascii 10)))
  (map-get? exchange-rates { pair: pair })
)

;; Check if rate is fresh
(define-read-only (is-rate-fresh (pair (string-ascii 10)))
  (match (map-get? exchange-rates { pair: pair })
    rate-data
      (< (- block-height (get timestamp rate-data)) MAX-RATE-AGE)
    false
  )
)

;; Get historical rate
(define-read-only (get-historical-rate (pair (string-ascii 10)) (block uint))
  (map-get? rate-history { pair: pair, block: block })
)

;; Get oracle address
(define-read-only (get-oracle)
  (var-get oracle-address)
)
