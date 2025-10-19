;; Plant Identification App Usage vs Mortality Rate Contract
;; Correlates the frequency of 'Is my plant dying?' searches with inevitable plant obituary writing

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-EXISTS (err u102))
(define-constant ERR-INVALID-PLANT-TYPE (err u103))
(define-constant ERR-INVALID-SEARCH-COUNT (err u104))
(define-constant MAX-SEARCH-COUNT u1000)
(define-constant MAX-STRING-LENGTH u128)

;; Data Variables
(define-data-var next-plant-id uint u1)
(define-data-var total-plants-recorded uint u0)
(define-data-var total-dead-plants uint u0)
(define-data-var total-searches uint u0)
(define-data-var platform-active bool true)

;; Data Maps
(define-map plants 
  { plant-id: uint }
  {
    owner: principal,
    plant-type: (string-ascii 64),
    plant-name: (string-ascii 64),
    acquisition-date: uint,
    search-count: uint,
    last-search-date: uint,
    is-alive: bool,
    death-date: (optional uint),
    death-cause: (optional (string-ascii 128)),
    desperation-level: uint,
    guilt-score: uint
  }
)

(define-map user-stats
  { user: principal }
  {
    total-plants: uint,
    dead-plants: uint,
    total-searches: uint,
    average-plant-lifespan: uint,
    guilt-level: uint,
    recovery-attempts: uint
  }
)

(define-map plant-searches
  { plant-id: uint, search-id: uint }
  {
    search-date: uint,
    search-query: (string-ascii 128),
    urgency-level: uint,
    result-helpful: bool,
    follow-up-needed: bool
  }
)

(define-map mortality-statistics
  { plant-type: (string-ascii 64) }
  {
    total-recorded: uint,
    total-deaths: uint,
    average-searches-before-death: uint,
    common-death-causes: (list 5 (string-ascii 64))
  }
)

;; Private Functions

(define-private (is-valid-plant-type (plant-type (string-ascii 64)))
  (and 
    (> (len plant-type) u0)
    (<= (len plant-type) u64)
  )
)

(define-private (calculate-guilt-score (searches uint) (days-alive uint))
  (if (is-eq days-alive u0)
    u100
    (/ (* searches u10) days-alive)
  )
)

(define-private (update-user-statistics (user principal) (plant-died bool) (search-count uint))
  (let (
    (current-stats (default-to 
      { total-plants: u0, dead-plants: u0, total-searches: u0, 
        average-plant-lifespan: u0, guilt-level: u0, recovery-attempts: u0 }
      (map-get? user-stats { user: user })
    ))
  )
    (map-set user-stats 
      { user: user }
      {
        total-plants: (+ (get total-plants current-stats) u1),
        dead-plants: (if plant-died (+ (get dead-plants current-stats) u1) (get dead-plants current-stats)),
        total-searches: (+ (get total-searches current-stats) search-count),
        average-plant-lifespan: (get average-plant-lifespan current-stats),
        guilt-level: (if plant-died (+ (get guilt-level current-stats) u10) (get guilt-level current-stats)),
        recovery-attempts: (get recovery-attempts current-stats)
      }
    )
  )
)

(define-private (increment-mortality-stats (plant-type (string-ascii 64)) (search-count uint) (death-cause (string-ascii 128)))
  (let (
    (current-stats (default-to
      { total-recorded: u0, total-deaths: u0, average-searches-before-death: u0, 
        common-death-causes: (list) }
      (map-get? mortality-statistics { plant-type: plant-type })
    ))
  )
    (map-set mortality-statistics
      { plant-type: plant-type }
      {
        total-recorded: (+ (get total-recorded current-stats) u1),
        total-deaths: (+ (get total-deaths current-stats) u1),
        average-searches-before-death: (/ (+ (* (get average-searches-before-death current-stats) (get total-deaths current-stats)) search-count) (+ (get total-deaths current-stats) u1)),
        common-death-causes: (get common-death-causes current-stats)
      }
    )
  )
)

;; Public Functions

(define-public (register-new-plant 
  (plant-type (string-ascii 64)) 
  (plant-name (string-ascii 64))
)
  (let (
    (plant-id (var-get next-plant-id))
  )
    (asserts! (var-get platform-active) ERR-UNAUTHORIZED)
    (asserts! (is-valid-plant-type plant-type) ERR-INVALID-PLANT-TYPE)
    (asserts! (> (len plant-name) u0) ERR-INVALID-PLANT-TYPE)
    
    (map-set plants
      { plant-id: plant-id }
      {
        owner: tx-sender,
        plant-type: plant-type,
        plant-name: plant-name,
        acquisition-date: stacks-block-height,
        search-count: u0,
        last-search-date: u0,
        is-alive: true,
        death-date: none,
        death-cause: none,
        desperation-level: u0,
        guilt-score: u0
      }
    )
    
    (var-set next-plant-id (+ plant-id u1))
    (var-set total-plants-recorded (+ (var-get total-plants-recorded) u1))
    (update-user-statistics tx-sender false u0)
    
    (ok plant-id)
  )
)

(define-public (record-plant-search 
  (plant-id uint) 
  (search-query (string-ascii 128))
  (urgency-level uint)
)
  (let (
    (plant-data (unwrap! (map-get? plants { plant-id: plant-id }) ERR-NOT-FOUND))
    (new-search-count (+ (get search-count plant-data) u1))
    (new-desperation-level (+ (get desperation-level plant-data) urgency-level))
  )
    (asserts! (is-eq (get owner plant-data) tx-sender) ERR-UNAUTHORIZED)
    (asserts! (get is-alive plant-data) ERR-NOT-FOUND)
    (asserts! (<= new-search-count MAX-SEARCH-COUNT) ERR-INVALID-SEARCH-COUNT)
    (asserts! (<= urgency-level u10) ERR-INVALID-SEARCH-COUNT)
    
    (map-set plants 
      { plant-id: plant-id }
      (merge plant-data {
        search-count: new-search-count,
        last-search-date: stacks-block-height,
        desperation-level: new-desperation-level
      })
    )
    
    (map-set plant-searches
      { plant-id: plant-id, search-id: new-search-count }
      {
        search-date: stacks-block-height,
        search-query: search-query,
        urgency-level: urgency-level,
        result-helpful: false,
        follow-up-needed: true
      }
    )
    
    (var-set total-searches (+ (var-get total-searches) u1))
    (ok new-search-count)
  )
)

(define-public (record-plant-death 
  (plant-id uint) 
  (death-cause (string-ascii 128))
)
  (let (
    (plant-data (unwrap! (map-get? plants { plant-id: plant-id }) ERR-NOT-FOUND))
    (days-alive (- stacks-block-height (get acquisition-date plant-data)))
    (final-guilt-score (calculate-guilt-score (get search-count plant-data) days-alive))
  )
    (asserts! (is-eq (get owner plant-data) tx-sender) ERR-UNAUTHORIZED)
    (asserts! (get is-alive plant-data) ERR-ALREADY-EXISTS)
    (asserts! (> (len death-cause) u0) ERR-INVALID-PLANT-TYPE)
    
    (map-set plants 
      { plant-id: plant-id }
      (merge plant-data {
        is-alive: false,
        death-date: (some stacks-block-height),
        death-cause: (some death-cause),
        guilt-score: final-guilt-score
      })
    )
    
    (var-set total-dead-plants (+ (var-get total-dead-plants) u1))
    (update-user-statistics tx-sender true (get search-count plant-data))
    (increment-mortality-stats (get plant-type plant-data) (get search-count plant-data) death-cause)
    
    (ok final-guilt-score)
  )
)

(define-public (update-search-result 
  (plant-id uint) 
  (search-id uint) 
  (was-helpful bool)
)
  (let (
    (plant-data (unwrap! (map-get? plants { plant-id: plant-id }) ERR-NOT-FOUND))
    (search-data (unwrap! (map-get? plant-searches { plant-id: plant-id, search-id: search-id }) ERR-NOT-FOUND))
  )
    (asserts! (is-eq (get owner plant-data) tx-sender) ERR-UNAUTHORIZED)
    
    (map-set plant-searches
      { plant-id: plant-id, search-id: search-id }
      (merge search-data {
        result-helpful: was-helpful,
        follow-up-needed: (not was-helpful)
      })
    )
    
    (ok true)
  )
)

;; Read-only Functions

(define-read-only (get-plant-info (plant-id uint))
  (map-get? plants { plant-id: plant-id })
)

(define-read-only (get-user-statistics (user principal))
  (map-get? user-stats { user: user })
)

(define-read-only (get-mortality-rate (plant-type (string-ascii 64)))
  (let (
    (stats (unwrap! (map-get? mortality-statistics { plant-type: plant-type }) ERR-NOT-FOUND))
  )
    (ok (/ (* (get total-deaths stats) u100) (get total-recorded stats)))
  )
)

(define-read-only (get-platform-statistics)
  {
    total-plants: (var-get total-plants-recorded),
    total-deaths: (var-get total-dead-plants),
    total-searches: (var-get total-searches),
    overall-mortality-rate: (if (> (var-get total-plants-recorded) u0)
      (/ (* (var-get total-dead-plants) u100) (var-get total-plants-recorded))
      u0
    ),
    platform-active: (var-get platform-active)
  }
)

(define-read-only (calculate-desperation-correlation (plant-id uint))
  (let (
    (plant-data (unwrap! (map-get? plants { plant-id: plant-id }) ERR-NOT-FOUND))
  )
    (ok {
      search-count: (get search-count plant-data),
      desperation-level: (get desperation-level plant-data),
      is-alive: (get is-alive plant-data),
      correlation-score: (if (get is-alive plant-data) u0 (get guilt-score plant-data))
    })
  )
)

;; Admin Functions (Contract Owner Only)

(define-public (toggle-platform-status)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    (var-set platform-active (not (var-get platform-active)))
    (ok (var-get platform-active))
  )
)

