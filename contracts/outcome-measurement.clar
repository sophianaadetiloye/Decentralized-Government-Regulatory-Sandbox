;; Outcome Measurement Contract
;; Tracks innovation results in the regulatory sandbox

(define-data-var admin principal tx-sender)

;; Metric types: 1 = financial, 2 = user satisfaction, 3 = efficiency, 4 = compliance
(define-map metrics uint
  {
    innovation-id: uint,
    metric-type: uint,
    name: (string-utf8 100),
    description: (string-utf8 200),
    target-value: uint,
    is-active: bool,
    creation-time: uint,
    creator: principal
  }
)

(define-map measurements uint
  {
    metric-id: uint,
    value: uint,
    timestamp: uint,
    reporter: principal,
    notes: (string-utf8 200)
  }
)

(define-data-var metric-counter uint u0)
(define-data-var measurement-counter uint u0)

(define-read-only (get-metric (metric-id uint))
  (default-to
    {
      innovation-id: u0,
      metric-type: u0,
      name: u"",
      description: u"",
      target-value: u0,
      is-active: false,
      creation-time: u0,
      creator: tx-sender
    }
    (map-get? metrics metric-id)
  )
)

(define-read-only (get-measurement (measurement-id uint))
  (default-to
    {
      metric-id: u0,
      value: u0,
      timestamp: u0,
      reporter: tx-sender,
      notes: u""
    }
    (map-get? measurements measurement-id)
  )
)

(define-public (create-metric (innovation-id uint) (metric-type uint) (name (string-utf8 100)) (description (string-utf8 200)) (target-value uint))
  (let ((new-id (+ (var-get metric-counter) u1)))
    (asserts! (is-eq tx-sender (var-get admin)) (err u2)) ;; Error 2: Not authorized
    (asserts! (> metric-type u0) (err u3)) ;; Error 3: Invalid metric type
    (asserts! (< metric-type u5) (err u3)) ;; Error 3: Invalid metric type

    (var-set metric-counter new-id)
    (ok (map-set metrics new-id
      {
        innovation-id: innovation-id,
        metric-type: metric-type,
        name: name,
        description: description,
        target-value: target-value,
        is-active: true,
        creation-time: block-height,
        creator: tx-sender
      }
    ))
  )
)

(define-public (record-measurement (metric-id uint) (value uint) (notes (string-utf8 200)))
  (let (
    (new-id (+ (var-get measurement-counter) u1))
    (metric (get-metric metric-id))
  )
    (asserts! (get is-active metric) (err u4)) ;; Error 4: Metric not active
    ;; In a real implementation, we would verify the entity is authorized to report on this metric

    (var-set measurement-counter new-id)
    (ok (map-set measurements new-id
      {
        metric-id: metric-id,
        value: value,
        timestamp: block-height,
        reporter: tx-sender,
        notes: notes
      }
    ))
  )
)

(define-public (deactivate-metric (metric-id uint))
  (let ((metric (get-metric metric-id)))
    (asserts! (is-eq tx-sender (var-get admin)) (err u2)) ;; Error 2: Not authorized
    (ok (map-set metrics metric-id
      (merge metric
        {
          is-active: false
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

(define-read-only (get-metrics-for-innovation (innovation-id uint))
  ;; In a real implementation, this would return all metrics for an innovation
  ;; For simplicity, we're just returning a placeholder
  (list (get-metric u0))
)

(define-read-only (get-measurements-for-metric (metric-id uint))
  ;; In a real implementation, this would return all measurements for a metric
  ;; For simplicity, we're just returning a placeholder
  (list (get-measurement u0))
)
