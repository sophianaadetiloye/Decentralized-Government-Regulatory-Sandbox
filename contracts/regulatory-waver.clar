;; Regulatory Waiver Contract
;; Manages temporary exemptions from regulations

(define-data-var admin principal tx-sender)

;; Waiver status: 0 = requested, 1 = granted, 2 = denied, 3 = revoked, 4 = expired
(define-map waivers uint
  {
    innovation-id: uint,
    entity-id: principal,
    regulation-code: (string-utf8 50),
    justification: (string-utf8 500),
    status: uint,
    request-time: uint,
    decision-time: uint,
    expiration-time: uint,
    approver: (optional principal)
  }
)

(define-data-var waiver-counter uint u0)

(define-read-only (get-waiver (waiver-id uint))
  (default-to
    {
      innovation-id: u0,
      entity-id: tx-sender,
      regulation-code: u"",
      justification: u"",
      status: u0,
      request-time: u0,
      decision-time: u0,
      expiration-time: u0,
      approver: none
    }
    (map-get? waivers waiver-id)
  )
)

(define-public (request-waiver (innovation-id uint) (regulation-code (string-utf8 50)) (justification (string-utf8 500)))
  (let ((new-id (+ (var-get waiver-counter) u1)))
    ;; Verify innovation is approved (would call innovation-registration contract)
    ;; (asserts! (contract-call? .innovation-registration is-approved innovation-id) (err u1))

    (var-set waiver-counter new-id)
    (ok (map-set waivers new-id
      {
        innovation-id: innovation-id,
        entity-id: tx-sender,
        regulation-code: regulation-code,
        justification: justification,
        status: u0, ;; requested
        request-time: block-height,
        decision-time: u0,
        expiration-time: u0,
        approver: none
      }
    ))
  )
)

(define-public (grant-waiver (waiver-id uint) (duration uint))
  (let ((waiver (get-waiver waiver-id)))
    (asserts! (is-eq tx-sender (var-get admin)) (err u2)) ;; Error 2: Not authorized
    (asserts! (is-eq (get status waiver) u0) (err u3)) ;; Error 3: Waiver not in requested status
    (ok (map-set waivers waiver-id
      (merge waiver
        {
          status: u1, ;; granted
          decision-time: block-height,
          expiration-time: (+ block-height duration),
          approver: (some tx-sender)
        }
      )
    ))
  )
)

(define-public (deny-waiver (waiver-id uint))
  (let ((waiver (get-waiver waiver-id)))
    (asserts! (is-eq tx-sender (var-get admin)) (err u2)) ;; Error 2: Not authorized
    (asserts! (is-eq (get status waiver) u0) (err u3)) ;; Error 3: Waiver not in requested status
    (ok (map-set waivers waiver-id
      (merge waiver
        {
          status: u2, ;; denied
          decision-time: block-height,
          approver: (some tx-sender)
        }
      )
    ))
  )
)

(define-public (revoke-waiver (waiver-id uint))
  (let ((waiver (get-waiver waiver-id)))
    (asserts! (is-eq tx-sender (var-get admin)) (err u2)) ;; Error 2: Not authorized
    (asserts! (is-eq (get status waiver) u1) (err u4)) ;; Error 4: Waiver not in granted status
    (ok (map-set waivers waiver-id
      (merge waiver
        {
          status: u3, ;; revoked
          decision-time: block-height
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

(define-read-only (is-waiver-active (waiver-id uint))
  (let ((waiver (get-waiver waiver-id)))
    (and
      (is-eq (get status waiver) u1) ;; granted
      (< block-height (get expiration-time waiver))
    )
  )
)
