;; Testing Boundary Contract
;; Defines operational constraints for sandbox innovations

(define-data-var admin principal tx-sender)

;; Boundary types: 1 = financial limit, 2 = user limit, 3 = time limit, 4 = geographic limit
(define-map boundaries uint
  {
    innovation-id: uint,
    boundary-type: uint,
    value: uint,
    description: (string-utf8 200),
    is-active: bool,
    creation-time: uint,
    creator: principal
  }
)

(define-data-var boundary-counter uint u0)

(define-read-only (get-boundary (boundary-id uint))
  (default-to
    {
      innovation-id: u0,
      boundary-type: u0,
      value: u0,
      description: u"",
      is-active: false,
      creation-time: u0,
      creator: tx-sender
    }
    (map-get? boundaries boundary-id)
  )
)

(define-public (create-boundary (innovation-id uint) (boundary-type uint) (value uint) (description (string-utf8 200)))
  (let ((new-id (+ (var-get boundary-counter) u1)))
    (asserts! (is-eq tx-sender (var-get admin)) (err u2)) ;; Error 2: Not authorized
    (asserts! (> boundary-type u0) (err u3)) ;; Error 3: Invalid boundary type
    (asserts! (< boundary-type u5) (err u3)) ;; Error 3: Invalid boundary type

    (var-set boundary-counter new-id)
    (ok (map-set boundaries new-id
      {
        innovation-id: innovation-id,
        boundary-type: boundary-type,
        value: value,
        description: description,
        is-active: true,
        creation-time: block-height,
        creator: tx-sender
      }
    ))
  )
)

(define-public (update-boundary (boundary-id uint) (value uint) (description (string-utf8 200)))
  (let ((boundary (get-boundary boundary-id)))
    (asserts! (is-eq tx-sender (var-get admin)) (err u2)) ;; Error 2: Not authorized
    (ok (map-set boundaries boundary-id
      (merge boundary
        {
          value: value,
          description: description
        }
      )
    ))
  )
)

(define-public (deactivate-boundary (boundary-id uint))
  (let ((boundary (get-boundary boundary-id)))
    (asserts! (is-eq tx-sender (var-get admin)) (err u2)) ;; Error 2: Not authorized
    (ok (map-set boundaries boundary-id
      (merge boundary
        {
          is-active: false
        }
      )
    ))
  )
)

(define-public (activate-boundary (boundary-id uint))
  (let ((boundary (get-boundary boundary-id)))
    (asserts! (is-eq tx-sender (var-get admin)) (err u2)) ;; Error 2: Not authorized
    (ok (map-set boundaries boundary-id
      (merge boundary
        {
          is-active: true
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

(define-read-only (get-boundaries-for-innovation (innovation-id uint))
  ;; In a real implementation, this would return all boundaries for an innovation
  ;; For simplicity, we're just returning a placeholder
  (list (get-boundary u0))
)
