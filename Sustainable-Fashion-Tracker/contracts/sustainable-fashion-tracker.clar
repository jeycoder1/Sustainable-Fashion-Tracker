;; Sustainable Fashion Tracker Contract
;; Tracks environmental impact and sustainability metrics for fashion items

(define-data-var next-item-id uint u1)
(define-data-var contract-owner principal tx-sender)

(define-map fashion-items uint {
  brand: principal,
  name: (string-ascii 64),
  carbon-footprint: uint,
  materials: (string-ascii 128),
  production-location: (string-ascii 64),
  sustainability-score: uint,
  certified: bool
})

(define-map brand-certifications principal {
  eco-certified: bool,
  fair-trade: bool,
  organic-materials: bool,
  carbon-neutral: bool
})

(define-map user-sustainability-points principal uint)

(define-constant ERR-NOT-AUTHORIZED (err u401))
(define-constant ERR-NOT-FOUND (err u404))
(define-constant ERR-INVALID-SCORE (err u400))

(define-public (register-fashion-item
  (name (string-ascii 64))
  (carbon-footprint uint)
  (materials (string-ascii 128))
  (production-location (string-ascii 64))
  (sustainability-score uint))
  (let ((item-id (var-get next-item-id)))
    (asserts! (<= sustainability-score u100) ERR-INVALID-SCORE)
    (map-set fashion-items item-id {
      brand: tx-sender,
      name: name,
      carbon-footprint: carbon-footprint,
      materials: materials,
      production-location: production-location,
      sustainability-score: sustainability-score,
      certified: false
    })
    (var-set next-item-id (+ item-id u1))
    (ok item-id)))

(define-public (certify-item (item-id uint))
  (let ((item (unwrap! (map-get? fashion-items item-id) ERR-NOT-FOUND)))
    (asserts! (is-eq (get brand item) tx-sender) ERR-NOT-AUTHORIZED)
    (map-set fashion-items item-id (merge item {certified: true}))
    (ok true)))

(define-public (award-sustainability-points (user principal) (points uint))
  (let ((current-points (default-to u0 (map-get? user-sustainability-points user))))
    (map-set user-sustainability-points user (+ current-points points))
    (ok true)))

(define-read-only (get-fashion-item (item-id uint))
  (map-get? fashion-items item-id))

(define-read-only (get-brand-certifications (brand principal))
  (map-get? brand-certifications brand))

(define-read-only (get-user-points (user principal))
  (default-to u0 (map-get? user-sustainability-points user)))

(define-read-only (calculate-environmental-impact (item-id uint))
  (let ((item (unwrap! (map-get? fashion-items item-id) ERR-NOT-FOUND)))
    (ok {
      carbon-footprint: (get carbon-footprint item),
      sustainability-score: (get sustainability-score item),
      impact-level: (if (> (get sustainability-score item) u70) "low" "high")
    })))
