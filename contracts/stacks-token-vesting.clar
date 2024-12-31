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
