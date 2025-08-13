;; Compliance Tracker Contract
;; Tracks renewable energy mandates and corporate compliance

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u400))
(define-constant ERR-INVALID-INPUT (err u401))
(define-constant ERR-MANDATE-NOT-FOUND (err u402))
(define-constant ERR-ALREADY-COMPLIANT (err u403))

;; Data Variables
(define-data-var next-mandate-id uint u1)
(define-data-var compliance-period-blocks uint u52560) ;; ~1 year in blocks
(define-data-var penalty-rate uint u100) ;; 1% per MWh shortfall

;; Data Maps
(define-map renewable-mandates uint {
  entity: principal,
  required-percentage: uint,
  total-energy-consumption: uint,
  compliance-deadline: uint,
  mandate-type: (string-ascii 20),
  is-active: bool,
  created-at: uint
})

(define-map compliance-status principal {
  current-rec-holdings: uint,
  total-energy-consumption: uint,
  compliance-percentage: uint,
  last-updated: uint,
  is-compliant: bool,
  penalty-amount: uint
})

(define-map entity-energy-sources {entity: principal, energy-source: (string-ascii 20)} uint)
(define-map compliance-history {entity: principal, period: uint} {
  required-recs: uint,
  actual-recs: uint,
  compliance-rate: uint,
  penalty-paid: uint
})

;; Public Functions

;; Create a renewable energy mandate
(define-public (create-mandate (entity principal) (required-percentage uint) (total-consumption uint) (mandate-type (string-ascii 20)))
  (let ((mandate-id (var-get next-mandate-id))
        (deadline (+ block-height (var-get compliance-period-blocks))))

    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (<= required-percentage u100) ERR-INVALID-INPUT)
    (asserts! (> total-consumption u0) ERR-INVALID-INPUT)

    (map-set renewable-mandates mandate-id {
      entity: entity,
      required-percentage: required-percentage,
      total-energy-consumption: total-consumption,
      compliance-deadline: deadline,
      mandate-type: mandate-type,
      is-active: true,
      created-at: block-height
    })

    (var-set next-mandate-id (+ mandate-id u1))
    (ok mandate-id)
  )
)

;; Update compliance status
(define-public (update-compliance-status (entity principal) (rec-holdings uint) (energy-consumption uint))
  (begin
    (asserts! (or (is-eq tx-sender entity) (is-eq tx-sender CONTRACT-OWNER)) ERR-NOT-AUTHORIZED)
    (asserts! (> energy-consumption u0) ERR-INVALID-INPUT)

    (let ((compliance-percentage (/ (* rec-holdings u100) energy-consumption))
          (required-recs (calculate-required-recs entity energy-consumption))
          (is-compliant (>= rec-holdings required-recs))
          (penalty (if is-compliant u0 (calculate-penalty entity (- required-recs rec-holdings)))))

      (map-set compliance-status entity {
        current-rec-holdings: rec-holdings,
        total-energy-consumption: energy-consumption,
        compliance-percentage: compliance-percentage,
        last-updated: block-height,
        is-compliant: is-compliant,
        penalty-amount: penalty
      })

      (ok {
        compliance-percentage: compliance-percentage,
        is-compliant: is-compliant,
        penalty-amount: penalty
      })
    )
  )
)

;; Report energy consumption by source
(define-public (report-energy-consumption (energy-source (string-ascii 20)) (consumption uint))
  (begin
    (asserts! (> consumption u0) ERR-INVALID-INPUT)

    (let ((current-consumption (default-to u0 (map-get? entity-energy-sources {entity: tx-sender, energy-source: energy-source}))))
      (map-set entity-energy-sources {entity: tx-sender, energy-source: energy-source} (+ current-consumption consumption))
    )

    (ok true)
  )
)

;; Pay compliance penalty
(define-public (pay-penalty (amount uint))
  (let ((status (unwrap! (map-get? compliance-status tx-sender) ERR-INVALID-INPUT)))
    (asserts! (>= amount (get penalty-amount status)) ERR-INVALID-INPUT)
    (asserts! (not (get is-compliant status)) ERR-ALREADY-COMPLIANT)

    ;; Transfer STX as penalty payment
    (try! (stx-transfer? amount tx-sender CONTRACT-OWNER))

    ;; Update compliance status
    (map-set compliance-status tx-sender (merge status {
      penalty-amount: u0,
      is-compliant: true
    }))

    (ok true)
  )
)

;; Submit compliance report for period
(define-public (submit-compliance-report (period uint) (actual-recs uint))
  (let ((required-recs (calculate-required-recs tx-sender u0))) ;; Simplified
    (let ((compliance-rate (if (> required-recs u0) (/ (* actual-recs u100) required-recs) u100))
          (penalty (if (>= actual-recs required-recs) u0 (calculate-penalty tx-sender (- required-recs actual-recs)))))

      (map-set compliance-history {entity: tx-sender, period: period} {
        required-recs: required-recs,
        actual-recs: actual-recs,
        compliance-rate: compliance-rate,
        penalty-paid: penalty
      })

      (ok {
        compliance-rate: compliance-rate,
        penalty: penalty
      })
    )
  )
)

;; Read-only Functions

;; Get mandate details
(define-read-only (get-mandate (mandate-id uint))
  (map-get? renewable-mandates mandate-id)
)

;; Get compliance status
(define-read-only (get-compliance-status (entity principal))
  (map-get? compliance-status entity)
)

;; Get entity's energy consumption by source
(define-read-only (get-energy-consumption (entity principal) (energy-source (string-ascii 20)))
  (default-to u0 (map-get? entity-energy-sources {entity: entity, energy-source: energy-source}))
)

;; Get compliance history
(define-read-only (get-compliance-history (entity principal) (period uint))
  (map-get? compliance-history {entity: entity, period: period})
)

;; Check if entity is compliant
(define-read-only (is-entity-compliant (entity principal))
  (match (map-get? compliance-status entity)
    some-status (get is-compliant some-status)
    false
  )
)

;; Calculate required RECs for entity
(define-read-only (calculate-required-recs (entity principal) (energy-consumption uint))
  ;; Simplified calculation - in reality would check specific mandates
  (/ (* energy-consumption u25) u100) ;; Assume 25% renewable requirement
)

;; Get penalty rate
(define-read-only (get-penalty-rate)
  (var-get penalty-rate)
)

;; Get compliance period
(define-read-only (get-compliance-period)
  (var-get compliance-period-blocks)
)

;; Private Functions

;; Calculate penalty for non-compliance
(define-private (calculate-penalty (entity principal) (shortfall uint))
  (* shortfall (var-get penalty-rate))
)

;; Check if mandate is active and not expired
(define-private (is-mandate-active (mandate-id uint))
  (match (map-get? renewable-mandates mandate-id)
    some-mandate (and (get is-active some-mandate) (< block-height (get compliance-deadline some-mandate)))
    false
  )
)

;; Get total energy consumption for entity
(define-private (get-total-consumption (entity principal))
  ;; Simplified - would sum across all energy sources
  (match (map-get? compliance-status entity)
    some-status (get total-energy-consumption some-status)
    u0
  )
)
