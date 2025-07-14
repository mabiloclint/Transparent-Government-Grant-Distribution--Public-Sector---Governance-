(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-AMOUNT (err u101))
(define-constant ERR-GRANT-NOT-FOUND (err u102))
(define-constant ERR-ALREADY-APPROVED (err u103))
(define-constant ERR-INSUFFICIENT-FUNDS (err u104))
(define-constant ERR-GRANT-EXPIRED (err u105))

(define-constant DEFAULT-EXPIRY-BLOCKS u2016)

(define-data-var government-address principal tx-sender)
(define-data-var total-grants uint u0)
(define-data-var total-funds uint u0)

(define-map grants 
    { grant-id: uint } 
    {
        applicant: principal,
        amount: uint,
        purpose: (string-ascii 256),
        status: (string-ascii 64),
        approved-at: uint,
        milestone-count: uint,
        completed-milestones: uint,
        expiry-block: uint
    }
)

(define-map milestones
    { grant-id: uint, milestone-id: uint }
    {
        description: (string-ascii 256),
        amount: uint,
        completed: bool
    }
)

(define-public (initialize-government (address principal))
    (begin
        (asserts! (is-eq tx-sender (var-get government-address)) ERR-NOT-AUTHORIZED)
        (var-set government-address address)
        (ok true)
    )
)

(define-public (apply-for-grant (amount uint) (purpose (string-ascii 256)))
    (let ((grant-id (+ (var-get total-grants) u1)))
        (asserts! (> amount u0) ERR-INVALID-AMOUNT)
        (map-set grants
            { grant-id: grant-id }
            {
                applicant: tx-sender,
                amount: amount,
                purpose: purpose,
                status: "PENDING",
                approved-at: u0,
                milestone-count: u0,
                completed-milestones: u0,
                expiry-block: u0
            }
        )
        (var-set total-grants grant-id)
        (ok grant-id)
    )
)

(define-public (approve-grant (grant-id uint))
    (let ((grant (unwrap! (map-get? grants { grant-id: grant-id }) ERR-GRANT-NOT-FOUND)))
        (asserts! (is-eq tx-sender (var-get government-address)) ERR-NOT-AUTHORIZED)
        (asserts! (is-eq (get status grant) "PENDING") ERR-ALREADY-APPROVED)
        (map-set grants
            { grant-id: grant-id }
            (merge grant {
                status: "APPROVED",
                approved-at: burn-block-height,
                expiry-block: (+ burn-block-height DEFAULT-EXPIRY-BLOCKS)
            })
        )
        (ok true)
    )
)

(define-public (add-milestone (grant-id uint) (description (string-ascii 256)) (amount uint))
    (let (
        (grant (unwrap! (map-get? grants { grant-id: grant-id }) ERR-GRANT-NOT-FOUND))
        (milestone-id (+ (get milestone-count grant) u1))
    )
        (asserts! (is-eq (get applicant grant) tx-sender) ERR-NOT-AUTHORIZED)
        (map-set milestones
            { grant-id: grant-id, milestone-id: milestone-id }
            {
                description: description,
                amount: amount,
                completed: false
            }
        )
        (map-set grants
            { grant-id: grant-id }
            (merge grant {
                milestone-count: milestone-id
            })
        )
        (ok milestone-id)
    )
)

(define-public (complete-milestone (grant-id uint) (milestone-id uint))
    (let (
        (grant (unwrap! (map-get? grants { grant-id: grant-id }) ERR-GRANT-NOT-FOUND))
        (milestone (unwrap! (map-get? milestones { grant-id: grant-id, milestone-id: milestone-id }) ERR-GRANT-NOT-FOUND))
    )
        (asserts! (is-eq tx-sender (var-get government-address)) ERR-NOT-AUTHORIZED)
        (asserts! (not (get completed milestone)) ERR-ALREADY-APPROVED)
        
        (map-set milestones
            { grant-id: grant-id, milestone-id: milestone-id }
            (merge milestone { completed: true })
        )
        
        (map-set grants
            { grant-id: grant-id }
            (merge grant {
                completed-milestones: (+ (get completed-milestones grant) u1)
            })
        )
        (ok true)
    )
)

(define-read-only (get-grant-details (grant-id uint))
    (ok (unwrap! (map-get? grants { grant-id: grant-id }) ERR-GRANT-NOT-FOUND))
)

(define-read-only (get-milestone-details (grant-id uint) (milestone-id uint))
    (ok (unwrap! (map-get? milestones { grant-id: grant-id, milestone-id: milestone-id }) ERR-GRANT-NOT-FOUND))
)

(define-public (set-grant-expiry (grant-id uint) (expiry-blocks uint))
    (let ((grant (unwrap! (map-get? grants { grant-id: grant-id }) ERR-GRANT-NOT-FOUND)))
        (asserts! (is-eq tx-sender (var-get government-address)) ERR-NOT-AUTHORIZED)
        (asserts! (is-eq (get status grant) "APPROVED") ERR-GRANT-NOT-FOUND)
        (map-set grants
            { grant-id: grant-id }
            (merge grant {
                expiry-block: (+ burn-block-height expiry-blocks)
            })
        )
        (ok true)
    )
)

(define-read-only (is-grant-expired (grant-id uint))
    (let ((grant (unwrap! (map-get? grants { grant-id: grant-id }) ERR-GRANT-NOT-FOUND)))
        (let ((expiry-block (get expiry-block grant)))
            (if (is-eq expiry-block u0)
                (ok false)
                (ok (>= burn-block-height expiry-block))
            )
        )
    )
)

(define-read-only (get-grant-with-status (grant-id uint))
    (let ((grant (unwrap! (map-get? grants { grant-id: grant-id }) ERR-GRANT-NOT-FOUND)))
        (let ((is-expired (unwrap-panic (is-grant-expired grant-id))))
            (ok (merge grant {
                status: (if is-expired "EXPIRED" (get status grant))
            }))
        )
    )
)
;;Thanks