;; Token Vesting Contract with Internal Token Implementation
;; Implements configurable vesting schedules with built-in token functionality

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-already-initialized (err u101))
(define-constant err-not-initialized (err u102))
(define-constant err-no-schedule (err u103))
(define-constant err-invalid-recipient (err u104))
(define-constant err-insufficient-balance (err u105))
(define-constant err-cliff-not-reached (err u106))
(define-constant err-invalid-milestone (err u107))
(define-constant err-transfer-failed (err u108))
(define-constant err-arithmetic-overflow (err u109))
(define-constant err-invalid-input (err u110))

;; Token configuration
(define-fungible-token vesting-token)
(define-data-var token-decimals uint u6)
(define-data-var token-uri (string-utf8 256) u"")
(define-data-var token-name (string-utf8 32) u"")
(define-data-var token-symbol (string-utf8 32) u"")

;; Data structures
(define-map vesting-schedules
  { recipient: principal }
  {
    total-amount: uint,
    start-block: uint,
    cliff-blocks: uint,
    duration-blocks: uint,
    released: uint,
    milestones: (list 10 {block: uint, percentage: uint}),
    milestone-count: uint
  }
)

(define-data-var contract-initialized bool false)

;; Safe arithmetic functions
(define-private (safe-add (a uint) (b uint))
  (let ((sum (+ a b)))
    (asserts! (>= sum a) err-arithmetic-overflow)
    (ok sum)))

(define-private (safe-sub (a uint) (b uint))
  (if (>= a b)
      (ok (- a b))
      err-arithmetic-overflow))

(define-private (safe-mul (a uint) (b uint))
  (let ((product (* a b)))
    (asserts! (or (is-eq a u0) (is-eq (/ product a) b)) err-arithmetic-overflow)
    (ok product)))

;; Initialize contract
(define-public (initialize (name (string-utf8 32)) 
                         (symbol (string-utf8 32)) 
                         (decimals uint)
                         (uri (string-utf8 256))
                         (initial-supply uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (not (var-get contract-initialized)) err-already-initialized)
    (asserts! (> initial-supply u0) err-invalid-input)
    (var-set token-name name)
    (var-set token-symbol symbol)
    (var-set token-decimals decimals)
    (var-set token-uri uri)
    (var-set contract-initialized true)
    (try! (ft-mint? vesting-token initial-supply contract-owner))
    (ok true)))

;; Create new vesting schedule
(define-public (create-vesting-schedule
    (recipient principal)
    (total-amount uint)
    (start-block uint)
    (cliff-blocks uint)
    (duration-blocks uint)
    (milestones (list 10 {block: uint, percentage: uint}))
    (milestone-count uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (var-get contract-initialized) err-not-initialized)
    (asserts! (> duration-blocks u0) err-invalid-milestone)
    (asserts! (<= milestone-count u10) err-invalid-milestone)
    (asserts! (> total-amount u0) err-invalid-input)
    (asserts! (>= start-block stacks-block-height) err-invalid-input)

    ;; Validate milestone percentages don't exceed 100%
    (asserts! (< (fold + (map get-percentage (unwrap! (slice? milestones u0 milestone-count) err-invalid-milestone)) u0) u100) err-invalid-milestone)

    ;; Transfer tokens to contract
    (try! (ft-transfer? vesting-token total-amount tx-sender (as-contract tx-sender)))

    ;; Create schedule
    (map-set vesting-schedules
      { recipient: recipient }
      {
        total-amount: total-amount,
        start-block: start-block,
        cliff-blocks: cliff-blocks,
        duration-blocks: duration-blocks,
        released: u0,
        milestones: milestones,
        milestone-count: milestone-count
      })
    (ok true)))

;; Helper to get percentage from milestone
(define-private (get-percentage (milestone {block: uint, percentage: uint}))
  (get percentage milestone))

;; Calculate vested amount
(define-private (calculate-vested-amount (schedule {
    total-amount: uint,
    start-block: uint,
    cliff-blocks: uint,
    duration-blocks: uint,
    released: uint,
    milestones: (list 10 {block: uint, percentage: uint}),
    milestone-count: uint
  }))
  (let (
    (current-block stacks-block-height)
    (cliff-end (unwrap! (safe-add (get start-block schedule) (get cliff-blocks schedule)) u0))
    (vesting-end (unwrap! (safe-add (get start-block schedule) (get duration-blocks schedule)) u0))
  )
    (if (< current-block cliff-end)
      u0
      (if (>= current-block vesting-end)
        (get total-amount schedule)
        (let (
          (elapsed (unwrap! (safe-sub current-block (get start-block schedule)) u0))
          (total-period (get duration-blocks schedule))
          (milestone-vested (get-milestone-vested schedule current-block))
        )
          (if (> milestone-vested u0)
            milestone-vested
            (unwrap! (safe-div 
              (unwrap! (safe-mul (get total-amount schedule) elapsed) u0)
              total-period) 
              u0)))))))
