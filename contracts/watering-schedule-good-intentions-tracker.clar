;; Watering Schedule Good Intentions Tracker Contract
;; Documents the lifecycle of elaborate plant care spreadsheets from creation to complete abandonment

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-UNAUTHORIZED (err u200))
(define-constant ERR-NOT-FOUND (err u201))
(define-constant ERR-ALREADY-EXISTS (err u202))
(define-constant ERR-INVALID-SCHEDULE (err u203))
(define-constant ERR-SCHEDULE-ABANDONED (err u204))
(define-constant ERR-INVALID-PARAMETERS (err u205))
(define-constant MAX-PLANTS-PER-SCHEDULE u50)
(define-constant MAX-MISSED-WATERINGS u100)
(define-constant GUILT-MULTIPLIER u5)

;; Data Variables
(define-data-var next-schedule-id uint u1)
(define-data-var total-schedules-created uint u0)
(define-data-var total-schedules-abandoned uint u0)
(define-data-var total-watering-attempts uint u0)
(define-data-var total-missed-waterings uint u0)
(define-data-var system-active bool true)

;; Data Maps
(define-map watering-schedules
  { schedule-id: uint }
  {
    creator: principal,
    schedule-name: (string-ascii 64),
    creation-date: uint,
    intended-frequency: uint,
    plant-count: uint,
    commitment-level: uint,
    is-active: bool,
    abandonment-date: (optional uint),
    abandonment-reason: (optional (string-ascii 128)),
    total-attempts: uint,
    successful-waterings: uint,
    missed-waterings: uint,
    guilt-accumulated: uint,
    recovery-attempts: uint
  }
)

(define-map schedule-plants
  { schedule-id: uint, plant-index: uint }
  {
    plant-name: (string-ascii 64),
    plant-type: (string-ascii 64),
    water-frequency-days: uint,
    last-watered: (optional uint),
    times-watered: uint,
    times-missed: uint,
    current-health-status: (string-ascii 32),
    care-notes: (string-ascii 256)
  }
)

(define-map watering-logs
  { schedule-id: uint, log-id: uint }
  {
    log-date: uint,
    action-type: (string-ascii 32),
    plants-affected: uint,
    success-rate: uint,
    emotional-state: (string-ascii 64),
    notes: (string-ascii 256)
  }
)

(define-map user-intention-stats
  { user: principal }
  {
    total-schedules: uint,
    active-schedules: uint,
    abandoned-schedules: uint,
    average-schedule-lifespan: uint,
    total-guilt-points: uint,
    commitment-reliability: uint,
    recovery-success-rate: uint
  }
)

(define-map schedule-analytics
  { schedule-id: uint }
  {
    creation-enthusiasm: uint,
    peak-commitment-period: uint,
    decline-start-date: (optional uint),
    abandonment-warning-signs: (list 5 (string-ascii 64)),
    final-guilt-score: uint,
    lessons-learned: (string-ascii 256)
  }
)

;; Private Functions

(define-private (is-valid-frequency (frequency uint))
  (and (> frequency u0) (<= frequency u365))
)

(define-private (calculate-commitment-decay (days-since-creation uint) (missed-waterings uint))
  (if (is-eq days-since-creation u0)
    u100
    (- u100 (/ (* missed-waterings u10) days-since-creation))
  )
)

(define-private (update-guilt-accumulation (schedule-id uint) (additional-guilt uint))
  (match (map-get? watering-schedules { schedule-id: schedule-id })
    schedule-data
    (begin
      (map-set watering-schedules
        { schedule-id: schedule-id }
        (merge schedule-data {
          guilt-accumulated: (+ (get guilt-accumulated schedule-data) additional-guilt)
        })
      )
      true
    )
    false
  )
)

(define-private (update-user-statistics (user principal) (schedule-abandoned bool) (guilt-points uint))
  (let (
    (current-stats (default-to
      { total-schedules: u0, active-schedules: u0, abandoned-schedules: u0,
        average-schedule-lifespan: u0, total-guilt-points: u0,
        commitment-reliability: u100, recovery-success-rate: u0 }
      (map-get? user-intention-stats { user: user })
    ))
  )
    (begin
      (map-set user-intention-stats
        { user: user }
        {
          total-schedules: (+ (get total-schedules current-stats) u1),
          active-schedules: (if schedule-abandoned (get active-schedules current-stats) (+ (get active-schedules current-stats) u1)),
          abandoned-schedules: (if schedule-abandoned (+ (get abandoned-schedules current-stats) u1) (get abandoned-schedules current-stats)),
          average-schedule-lifespan: (get average-schedule-lifespan current-stats),
          total-guilt-points: (+ (get total-guilt-points current-stats) guilt-points),
          commitment-reliability: (get commitment-reliability current-stats),
          recovery-success-rate: (get recovery-success-rate current-stats)
        }
      )
      true
    )
  )
)

(define-private (log-schedule-activity 
  (schedule-id uint) 
  (action-type (string-ascii 32)) 
  (plants-count uint)
  (success-rate uint)
  (emotional-state (string-ascii 64))
)
  (match (map-get? watering-schedules { schedule-id: schedule-id })
    schedule-data
    (let (
      (log-id (+ (get total-attempts schedule-data) u1))
    )
      (begin
        (map-set watering-logs
          { schedule-id: schedule-id, log-id: log-id }
          {
            log-date: stacks-block-height,
            action-type: action-type,
            plants-affected: plants-count,
            success-rate: success-rate,
            emotional-state: emotional-state,
            notes: ""
          }
        )
        (map-set watering-schedules
          { schedule-id: schedule-id }
          (merge schedule-data {
            total-attempts: log-id
          })
        )
        true
      )
    )
    false
  )
)

;; Public Functions

(define-public (create-watering-schedule 
  (schedule-name (string-ascii 64))
  (intended-frequency uint)
  (initial-commitment-level uint)
)
  (let (
    (schedule-id (var-get next-schedule-id))
  )
    (asserts! (var-get system-active) ERR-UNAUTHORIZED)
    (asserts! (> (len schedule-name) u0) ERR-INVALID-PARAMETERS)
    (asserts! (is-valid-frequency intended-frequency) ERR-INVALID-SCHEDULE)
    (asserts! (<= initial-commitment-level u100) ERR-INVALID-PARAMETERS)
    
    (map-set watering-schedules
      { schedule-id: schedule-id }
      {
        creator: tx-sender,
        schedule-name: schedule-name,
        creation-date: stacks-block-height,
        intended-frequency: intended-frequency,
        plant-count: u0,
        commitment-level: initial-commitment-level,
        is-active: true,
        abandonment-date: none,
        abandonment-reason: none,
        total-attempts: u0,
        successful-waterings: u0,
        missed-waterings: u0,
        guilt-accumulated: u0,
        recovery-attempts: u0
      }
    )
    
    (map-set schedule-analytics
      { schedule-id: schedule-id }
      {
        creation-enthusiasm: initial-commitment-level,
        peak-commitment-period: u0,
        decline-start-date: none,
        abandonment-warning-signs: (list),
        final-guilt-score: u0,
        lessons-learned: ""
      }
    )
    
    (var-set next-schedule-id (+ schedule-id u1))
    (var-set total-schedules-created (+ (var-get total-schedules-created) u1))
    (update-user-statistics tx-sender false u0)
    
    (ok schedule-id)
  )
)

(define-public (add-plant-to-schedule 
  (schedule-id uint)
  (plant-name (string-ascii 64))
  (plant-type (string-ascii 64))
  (water-frequency-days uint)
)
  (let (
    (schedule-data (unwrap! (map-get? watering-schedules { schedule-id: schedule-id }) ERR-NOT-FOUND))
    (new-plant-index (get plant-count schedule-data))
  )
    (asserts! (is-eq (get creator schedule-data) tx-sender) ERR-UNAUTHORIZED)
    (asserts! (get is-active schedule-data) ERR-SCHEDULE-ABANDONED)
    (asserts! (< new-plant-index MAX-PLANTS-PER-SCHEDULE) ERR-INVALID-PARAMETERS)
    (asserts! (is-valid-frequency water-frequency-days) ERR-INVALID-SCHEDULE)
    
    (map-set schedule-plants
      { schedule-id: schedule-id, plant-index: new-plant-index }
      {
        plant-name: plant-name,
        plant-type: plant-type,
        water-frequency-days: water-frequency-days,
        last-watered: none,
        times-watered: u0,
        times-missed: u0,
        current-health-status: "healthy",
        care-notes: ""
      }
    )
    
    (map-set watering-schedules
      { schedule-id: schedule-id }
      (merge schedule-data {
        plant-count: (+ new-plant-index u1)
      })
    )
    
    (ok new-plant-index)
  )
)

(define-public (record-watering-session 
  (schedule-id uint)
  (plants-watered uint)
  (emotional-state (string-ascii 64))
)
  (let (
    (schedule-data (unwrap! (map-get? watering-schedules { schedule-id: schedule-id }) ERR-NOT-FOUND))
    (success-rate (/ (* plants-watered u100) (get plant-count schedule-data)))
  )
    (asserts! (is-eq (get creator schedule-data) tx-sender) ERR-UNAUTHORIZED)
    (asserts! (get is-active schedule-data) ERR-SCHEDULE-ABANDONED)
    (asserts! (<= plants-watered (get plant-count schedule-data)) ERR-INVALID-PARAMETERS)
    
    (map-set watering-schedules
      { schedule-id: schedule-id }
      (merge schedule-data {
        successful-waterings: (+ (get successful-waterings schedule-data) plants-watered),
        total-attempts: (+ (get total-attempts schedule-data) u1)
      })
    )
    
    (log-schedule-activity schedule-id "watering" plants-watered success-rate emotional-state)
    (var-set total-watering-attempts (+ (var-get total-watering-attempts) u1))
    
    (ok success-rate)
  )
)

(define-public (record-missed-watering 
  (schedule-id uint)
  (reason (string-ascii 128))
  (guilt-level uint)
)
  (let (
    (schedule-data (unwrap! (map-get? watering-schedules { schedule-id: schedule-id }) ERR-NOT-FOUND))
    (guilt-points (* guilt-level GUILT-MULTIPLIER))
  )
    (asserts! (is-eq (get creator schedule-data) tx-sender) ERR-UNAUTHORIZED)
    (asserts! (get is-active schedule-data) ERR-SCHEDULE-ABANDONED)
    (asserts! (<= guilt-level u10) ERR-INVALID-PARAMETERS)
    
    (map-set watering-schedules
      { schedule-id: schedule-id }
      (merge schedule-data {
        missed-waterings: (+ (get missed-waterings schedule-data) u1),
        guilt-accumulated: (+ (get guilt-accumulated schedule-data) guilt-points)
      })
    )
    
    (log-schedule-activity schedule-id "missed" u0 u0 "guilty")
    (var-set total-missed-waterings (+ (var-get total-missed-waterings) u1))
    
    (ok guilt-points)
  )
)

(define-public (abandon-schedule 
  (schedule-id uint)
  (abandonment-reason (string-ascii 128))
)
  (let (
    (schedule-data (unwrap! (map-get? watering-schedules { schedule-id: schedule-id }) ERR-NOT-FOUND))
    (days-active (- stacks-block-height (get creation-date schedule-data)))
    (final-guilt (+ (get guilt-accumulated schedule-data) (* (get missed-waterings schedule-data) u10)))
  )
    (asserts! (is-eq (get creator schedule-data) tx-sender) ERR-UNAUTHORIZED)
    (asserts! (get is-active schedule-data) ERR-ALREADY-EXISTS)
    
    (map-set watering-schedules
      { schedule-id: schedule-id }
      (merge schedule-data {
        is-active: false,
        abandonment-date: (some stacks-block-height),
        abandonment-reason: (some abandonment-reason),
        guilt-accumulated: final-guilt
      })
    )
    
    (map-set schedule-analytics
      { schedule-id: schedule-id }
      (merge (unwrap-panic (map-get? schedule-analytics { schedule-id: schedule-id })) {
        final-guilt-score: final-guilt,
        lessons-learned: abandonment-reason
      })
    )
    
    (var-set total-schedules-abandoned (+ (var-get total-schedules-abandoned) u1))
    (update-user-statistics tx-sender true final-guilt)
    
    (ok final-guilt)
  )
)

(define-public (attempt-schedule-recovery 
  (schedule-id uint)
  (renewed-commitment-level uint)
)
  (let (
    (schedule-data (unwrap! (map-get? watering-schedules { schedule-id: schedule-id }) ERR-NOT-FOUND))
  )
    (asserts! (is-eq (get creator schedule-data) tx-sender) ERR-UNAUTHORIZED)
    (asserts! (not (get is-active schedule-data)) ERR-INVALID-SCHEDULE)
    (asserts! (<= renewed-commitment-level u100) ERR-INVALID-PARAMETERS)
    
    (map-set watering-schedules
      { schedule-id: schedule-id }
      (merge schedule-data {
        is-active: true,
        commitment-level: renewed-commitment-level,
        recovery-attempts: (+ (get recovery-attempts schedule-data) u1),
        abandonment-date: none,
        abandonment-reason: none
      })
    )
    
    (log-schedule-activity schedule-id "recovery" u0 u0 "hopeful")
    
    (ok (get recovery-attempts schedule-data))
  )
)

;; Read-only Functions

(define-read-only (get-schedule-info (schedule-id uint))
  (map-get? watering-schedules { schedule-id: schedule-id })
)

(define-read-only (get-user-intention-statistics (user principal))
  (map-get? user-intention-stats { user: user })
)

(define-read-only (get-schedule-analytics (schedule-id uint))
  (map-get? schedule-analytics { schedule-id: schedule-id })
)

(define-read-only (calculate-abandonment-risk (schedule-id uint))
  (let (
    (schedule-data (unwrap! (map-get? watering-schedules { schedule-id: schedule-id }) ERR-NOT-FOUND))
    (days-active (- stacks-block-height (get creation-date schedule-data)))
    (miss-rate (if (> (get total-attempts schedule-data) u0)
      (/ (* (get missed-waterings schedule-data) u100) (get total-attempts schedule-data))
      u0
    ))
  )
    (ok {
      days-active: days-active,
      miss-rate: miss-rate,
      guilt-level: (get guilt-accumulated schedule-data),
      abandonment-risk: (+ miss-rate (/ (get guilt-accumulated schedule-data) u10))
    })
  )
)

(define-read-only (get-platform-statistics)
  {
    total-schedules: (var-get total-schedules-created),
    abandoned-schedules: (var-get total-schedules-abandoned),
    total-attempts: (var-get total-watering-attempts),
    total-missed: (var-get total-missed-waterings),
    abandonment-rate: (if (> (var-get total-schedules-created) u0)
      (/ (* (var-get total-schedules-abandoned) u100) (var-get total-schedules-created))
      u0
    ),
    system-active: (var-get system-active)
  }
)

;; Admin Functions

(define-public (toggle-system-status)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    (var-set system-active (not (var-get system-active)))
    (ok (var-get system-active))
  )
)

