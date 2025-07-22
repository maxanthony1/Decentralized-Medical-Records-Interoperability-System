;; Cross-Hospital Data Sharing Contract
;; Enables secure medical record transfers between institutions

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u200))
(define-constant ERR-INVALID-HOSPITAL (err u201))
(define-constant ERR-TRANSFER-NOT-FOUND (err u202))
(define-constant ERR-INVALID-STATUS (err u203))
(define-constant ERR-CONSENT-REQUIRED (err u204))
(define-constant ERR-INVALID-INPUT (err u205))

;; Data Variables
(define-data-var next-transfer-id uint u1)

;; Data Maps
(define-map hospitals
  { hospital-id: principal }
  {
    name: (string-ascii 100),
    license: (string-ascii 50),
    verified: bool,
    created-at: uint,
    public-key: (buff 64)
  }
)

(define-map data-transfers
  { transfer-id: uint }
  {
    patient-id: principal,
    from-hospital: principal,
    to-hospital: principal,
    data-hash: (buff 32),
    encrypted-key: (buff 64),
    status: (string-ascii 20),
    requested-at: uint,
    completed-at: (optional uint),
    access-level: uint
  }
)

(define-map transfer-approvals
  { transfer-id: uint, approver: principal }
  {
    approved: bool,
    approved-at: uint,
    signature: (buff 64)
  }
)

(define-map hospital-partnerships
  { hospital-a: principal, hospital-b: principal }
  {
    active: bool,
    established-at: uint,
    trust-level: uint
  }
)

;; Read-only functions
(define-read-only (get-hospital (hospital-id principal))
  (map-get? hospitals { hospital-id: hospital-id })
)

(define-read-only (get-transfer (transfer-id uint))
  (map-get? data-transfers { transfer-id: transfer-id })
)

(define-read-only (get-transfer-approval (transfer-id uint) (approver principal))
  (map-get? transfer-approvals { transfer-id: transfer-id, approver: approver })
)

(define-read-only (get-partnership (hospital-a principal) (hospital-b principal))
  (map-get? hospital-partnerships { hospital-a: hospital-a, hospital-b: hospital-b })
)

(define-read-only (is-hospital-verified (hospital-id principal))
  (match (get-hospital hospital-id)
    hospital-data (get verified hospital-data)
    false
  )
)

(define-read-only (get-next-transfer-id)
  (var-get next-transfer-id)
)

;; Public functions
(define-public (register-hospital (name (string-ascii 100)) (license (string-ascii 50)) (public-key (buff 64)))
  (let ((hospital-id tx-sender))
    (asserts! (is-none (get-hospital hospital-id)) ERR-INVALID-HOSPITAL)
    (map-set hospitals
      { hospital-id: hospital-id }
      {
        name: name,
        license: license,
        verified: false,
        created-at: block-height,
        public-key: public-key
      }
    )
    (ok hospital-id)
  )
)

(define-public (verify-hospital (hospital-id principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (match (get-hospital hospital-id)
      hospital-data
      (begin
        (map-set hospitals
          { hospital-id: hospital-id }
          (merge hospital-data { verified: true })
        )
        (ok true)
      )
      ERR-INVALID-HOSPITAL
    )
  )
)

(define-public (establish-partnership (partner-hospital principal) (trust-level uint))
  (let ((hospital-id tx-sender))
    (asserts! (is-hospital-verified hospital-id) ERR-INVALID-HOSPITAL)
    (asserts! (is-hospital-verified partner-hospital) ERR-INVALID-HOSPITAL)
    (asserts! (and (>= trust-level u1) (<= trust-level u5)) ERR-INVALID-INPUT)

    (map-set hospital-partnerships
      { hospital-a: hospital-id, hospital-b: partner-hospital }
      {
        active: true,
        established-at: block-height,
        trust-level: trust-level
      }
    )

    ;; Create reciprocal partnership
    (map-set hospital-partnerships
      { hospital-a: partner-hospital, hospital-b: hospital-id }
      {
        active: true,
        established-at: block-height,
        trust-level: trust-level
      }
    )

    (ok true)
  )
)

(define-public (request-data-transfer
  (patient-id principal)
  (to-hospital principal)
  (data-hash (buff 32))
  (encrypted-key (buff 64))
  (access-level uint)
)
  (let (
    (transfer-id (var-get next-transfer-id))
    (from-hospital tx-sender)
  )
    (asserts! (is-hospital-verified from-hospital) ERR-INVALID-HOSPITAL)
    (asserts! (is-hospital-verified to-hospital) ERR-INVALID-HOSPITAL)
    (asserts! (and (>= access-level u1) (<= access-level u5)) ERR-INVALID-INPUT)

    ;; Check if hospitals have partnership
    (asserts!
      (is-some (get-partnership from-hospital to-hospital))
      ERR-NOT-AUTHORIZED
    )

    ;; TODO: Check patient consent (would integrate with patient-consent contract)

    (map-set data-transfers
      { transfer-id: transfer-id }
      {
        patient-id: patient-id,
        from-hospital: from-hospital,
        to-hospital: to-hospital,
        data-hash: data-hash,
        encrypted-key: encrypted-key,
        status: "PENDING",
        requested-at: block-height,
        completed-at: none,
        access-level: access-level
      }
    )

    (var-set next-transfer-id (+ transfer-id u1))
    (ok transfer-id)
  )
)

(define-public (approve-transfer (transfer-id uint) (signature (buff 64)))
  (let ((approver tx-sender))
    (match (get-transfer transfer-id)
      transfer-data
      (begin
        (asserts!
          (or
            (is-eq approver (get patient-id transfer-data))
            (is-eq approver (get to-hospital transfer-data))
          )
          ERR-NOT-AUTHORIZED
        )

        (map-set transfer-approvals
          { transfer-id: transfer-id, approver: approver }
          {
            approved: true,
            approved-at: block-height,
            signature: signature
          }
        )

        ;; Check if both patient and receiving hospital have approved
        (let (
          (patient-approved (is-some (get-transfer-approval transfer-id (get patient-id transfer-data))))
          (hospital-approved (is-some (get-transfer-approval transfer-id (get to-hospital transfer-data))))
        )
          (if (and patient-approved hospital-approved)
            (begin
              (map-set data-transfers
                { transfer-id: transfer-id }
                (merge transfer-data {
                  status: "APPROVED",
                  completed-at: (some block-height)
                })
              )
              (ok "APPROVED")
            )
            (ok "PENDING")
          )
        )
      )
      ERR-TRANSFER-NOT-FOUND
    )
  )
)

(define-public (complete-transfer (transfer-id uint))
  (let ((hospital tx-sender))
    (match (get-transfer transfer-id)
      transfer-data
      (begin
        (asserts! (is-eq hospital (get to-hospital transfer-data)) ERR-NOT-AUTHORIZED)
        (asserts! (is-eq (get status transfer-data) "APPROVED") ERR-INVALID-STATUS)

        (map-set data-transfers
          { transfer-id: transfer-id }
          (merge transfer-data {
            status: "COMPLETED",
            completed-at: (some block-height)
          })
        )

        (ok true)
      )
      ERR-TRANSFER-NOT-FOUND
    )
  )
)

(define-public (cancel-transfer (transfer-id uint))
  (let ((requester tx-sender))
    (match (get-transfer transfer-id)
      transfer-data
      (begin
        (asserts!
          (or
            (is-eq requester (get patient-id transfer-data))
            (is-eq requester (get from-hospital transfer-data))
          )
          ERR-NOT-AUTHORIZED
        )

        (map-set data-transfers
          { transfer-id: transfer-id }
          (merge transfer-data { status: "CANCELLED" })
        )

        (ok true)
      )
      ERR-TRANSFER-NOT-FOUND
    )
  )
)
