(define-map escrows
  {
    escrow-id: uint
  }
  {
    owner: principal,        ;; business owner initiating export
    agent: principal,        ;; logistics or escrow agent
    customer: principal,     ;; buyer or importer
    amount: uint,            ;; amount locked in escrow (in micro-STX)
    status: (string-ascii 32), ;; "Open", "Shipped", "Completed", "Disputed", "Cancelled"
    deposit-timestamp: uint
  }
  )

(define-data-var next-escrow-id uint u1)

;; Constants for incentive amounts (in micro-STX)
(define-constant INCENTIVE_OWNER u1000000)   ;; 1 STX
(define-constant INCENTIVE_AGENT u500000)    ;; 0.5 STX
(define-constant INCENTIVE_CUSTOMER u250000) ;; 0.25 STX

;; Contract deployer
(define-constant CONTRACT_DEPLOYER tx-sender)

;; Error constants
(define-constant ERR_AMOUNT_INVALID u1)
(define-constant ERR_UNAUTHORIZED u100)
(define-constant ERR_NOT_DISPUTED u101)
(define-constant ERR_ESCROW_NOT_FOUND u102)
(define-constant ERR_INVALID_STATUS u103)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Escrow Lifecycle
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-private (generate-escrow-id)
  (let ((id (var-get next-escrow-id)))
    (var-set next-escrow-id (+ id u1))
    id))

(define-public (create-escrow (agent principal) (customer principal) (amount uint))
  (begin
    ;; Validate amount
    (asserts! (>= amount u1) (err ERR_AMOUNT_INVALID))
    (let ((escrow-id (generate-escrow-id)))
      ;; Lock STX into contract
      (match (stx-transfer? amount tx-sender (as-contract tx-sender))
        success
        (begin
          (map-set escrows
            { escrow-id: escrow-id }
            { owner: tx-sender,
              agent: agent,
              customer: customer,
              amount: amount,
              status: "Open",
              deposit-timestamp: burn-block-height }
          )
          (ok escrow-id)
        )
        failure (err failure)
      )
    )
  )
)

(define-public (confirm-shipment (escrow-id uint))
  (let ((e (map-get? escrows { escrow-id: escrow-id })))
    (match e
      escrow
      (begin
        (asserts! (is-eq tx-sender (get agent escrow)) (err ERR_UNAUTHORIZED))
        (asserts! (is-eq (get status escrow) "Open") (err ERR_INVALID_STATUS))
        (map-set escrows { escrow-id: escrow-id }
          { owner: (get owner escrow),
            agent: (get agent escrow),
            customer: (get customer escrow),
            amount: (get amount escrow),
            status: "Shipped",
            deposit-timestamp: (get deposit-timestamp escrow) })
        (ok true)
      )
      (err ERR_ESCROW_NOT_FOUND)
    )
  )
)

(define-public (release-funds (escrow-id uint))
  (let ((e (map-get? escrows { escrow-id: escrow-id })))
    (match e
      escrow
      (begin
        (asserts! (is-eq tx-sender (get customer escrow)) (err ERR_UNAUTHORIZED))
        (asserts! (or (is-eq (get status escrow) "Open") (is-eq (get status escrow) "Shipped")) (err ERR_INVALID_STATUS))
        ;; Transfer principal amount to owner
        (try! (stx-transfer? (get amount escrow) (as-contract tx-sender) (get owner escrow)))
        ;; Distribute incentives (ignore failures for incentives)
        (unwrap-panic (stx-transfer? INCENTIVE_OWNER (as-contract tx-sender) (get owner escrow)))
        (unwrap-panic (stx-transfer? INCENTIVE_AGENT (as-contract tx-sender) (get agent escrow)))
        (unwrap-panic (stx-transfer? INCENTIVE_CUSTOMER (as-contract tx-sender) (get customer escrow)))
        ;; Update status
        (map-set escrows { escrow-id: escrow-id }
          { owner: (get owner escrow),
            agent: (get agent escrow),
            customer: (get customer escrow),
            amount: (get amount escrow),
            status: "Completed",
            deposit-timestamp: (get deposit-timestamp escrow) })
        (ok true)
      )
      (err ERR_ESCROW_NOT_FOUND)
    )
  )
)

(define-public (raise-dispute (escrow-id uint) (reason (string-ascii 128)))
  (let ((e (map-get? escrows { escrow-id: escrow-id })))
    (match e
      escrow
      (begin
        ;; Only owner or customer can raise dispute
        (asserts! (or (is-eq tx-sender (get customer escrow)) (is-eq tx-sender (get owner escrow))) (err ERR_UNAUTHORIZED))
        (asserts! (not (is-eq (get status escrow) "Completed")) (err ERR_INVALID_STATUS))
        (map-set escrows { escrow-id: escrow-id }
          { owner: (get owner escrow),
            agent: (get agent escrow),
            customer: (get customer escrow),
            amount: (get amount escrow),
            status: "Disputed",
            deposit-timestamp: (get deposit-timestamp escrow) })
        (ok true)
      )
      (err ERR_ESCROW_NOT_FOUND)
    )
  )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Admin Function: resolve dispute
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-public (resolve-dispute (escrow-id uint) (release-to-owner bool))
  (begin
    ;; Only contract deployer can resolve
    (asserts! (is-eq tx-sender CONTRACT_DEPLOYER) (err ERR_UNAUTHORIZED))
    (let ((e (map-get? escrows { escrow-id: escrow-id })))
      (match e
        escrow
        (begin
          (asserts! (is-eq (get status escrow) "Disputed") (err ERR_NOT_DISPUTED))
          (begin
            ;; Decide payout
            (try! (if release-to-owner
              (stx-transfer? (get amount escrow) (as-contract tx-sender) (get owner escrow))
              (stx-transfer? (get amount escrow) (as-contract tx-sender) (get customer escrow))))
            (map-set escrows { escrow-id: escrow-id }
              { owner: (get owner escrow),
                agent: (get agent escrow),
                customer: (get customer escrow),
                amount: (get amount escrow),
                status: (if release-to-owner "Completed" "Cancelled"),
                deposit-timestamp: (get deposit-timestamp escrow) })
            (ok true)
          )
        )
        (err ERR_ESCROW_NOT_FOUND)
      )
    )
  )
)

;; Read-only getters
(define-read-only (get-escrow (escrow-id uint))
  (match (map-get? escrows { escrow-id: escrow-id })
    e (ok e)
    (err ERR_ESCROW_NOT_FOUND)))
