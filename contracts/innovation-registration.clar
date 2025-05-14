;; Innovation Registration Contract
;; Records experimental concepts in the regulatory sandbox

(define-data-var admin principal tx-sender)

;; Innovation status: 0 = draft, 1 = submitted, 2 = approved, 3 = rejected, 4 = completed
(define-map innovations uint
  {
    owner: principal,
    title: (string-utf8 100),
    description: (string-utf8 500),
    status: uint,
    submission-time: uint,
    approval-time: uint,
    completion-time: uint,
    approver: (optional principal)
  }
)

(define-data-var innovation-counter uint u0)

(define-read-only (get-innovation (innovation-id uint))
  (default-to
    {
      owner: tx-sender,
      title: u"",
      description: u"",
      status: u0,
      submission-time: u0,
      approval-time: u0,
      completion-time: u0,
      approver: none
    }
    (map-get? innovations innovation-id)
  )
)

(define-public (register-innovation (title (string-utf8 100)) (description (string-utf8 500)))
  (let ((new-id (+ (var-get innovation-counter) u1)))
    ;; Verify entity is verified (contract-call to entity-verification contract)
    ;; (asserts! (contract-call? .entity-verification is-verified tx-sender) (err u1))

    (var-set innovation-counter new-id)
    (ok (map-set innovations new-id
      {
        owner: tx-sender,
        title: title,
        description: description,
        status: u1, ;; submitted
        submission-time: block-height,
        approval-time: u0,
        completion-time: u0,
        approver: none
      }
    ))
  )
)

(define-public (approve-innovation (innovation-id uint))
  (let ((innovation (get-innovation innovation-id)))
    (asserts! (is-eq tx-sender (var-get admin)) (err u2)) ;; Error 2: Not authorized
    (asserts! (is-eq (get status innovation) u1) (err u3)) ;; Error 3: Innovation not in submitted status
    (ok (map-set innovations innovation-id
      (merge innovation
        {
          status: u2, ;; approved
          approval-time: block-height,
          approver: (some tx-sender)
        }
      )
    ))
  )
)

(define-public (reject-innovation (innovation-id uint))
  (let ((innovation (get-innovation innovation-id)))
    (asserts! (is-eq tx-sender (var-get admin)) (err u2)) ;; Error 2: Not authorized
    (asserts! (is-eq (get status innovation) u1) (err u3)) ;; Error 3: Innovation not in submitted status
    (ok (map-set innovations innovation-id
      (merge innovation
        {
          status: u3, ;; rejected
          approval-time: block-height,
          approver: (some tx-sender)
        }
      )
    ))
  )
)

(define-public (complete-innovation (innovation-id uint))
  (let ((innovation (get-innovation innovation-id)))
    (asserts! (is-eq tx-sender (get owner innovation)) (err u2)) ;; Error 2: Not authorized
    (asserts! (is-eq (get status innovation) u2) (err u4)) ;; Error 4: Innovation not in approved status
    (ok (map-set innovations innovation-id
      (merge innovation
        {
          status: u4, ;; completed
          completion-time: block-height
        }
      )
    ))
  )
)

(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u2)) ;; Error 2: Not authorized
    (ok (var-set admin new-admin))
  )
)

(define-read-only (is-approved (innovation-id uint))
  (is-eq (get status (get-innovation innovation-id)) u2)
)
