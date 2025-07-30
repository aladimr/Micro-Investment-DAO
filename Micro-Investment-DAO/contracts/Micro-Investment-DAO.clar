;; Micro-Investment DAO Smart Contract
;; Aggregates small investments to fund community projects with proportional governance

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-insufficient-funds (err u103))
(define-constant err-invalid-amount (err u104))
(define-constant err-project-not-active (err u105))
(define-constant err-voting-closed (err u106))
(define-constant err-already-voted (err u107))
(define-constant err-unauthorized (err u108))

;; Data Variables
(define-data-var next-project-id uint u1)
(define-data-var total-dao-funds uint u0)
(define-data-var min-investment uint u1000000) ;; 1 STX minimum

;; Data Maps
(define-map investments 
    principal 
    { amount: uint, join-block: uint }
)

(define-map projects 
    uint 
    {
        title: (string-ascii 100),
        description: (string-ascii 500),
        funding-goal: uint,
        current-funding: uint,
        creator: principal,
        status: (string-ascii 20), ;; "active", "funded", "completed", "cancelled"
        created-at: uint,
        deadline: uint
    }
)

(define-map project-votes 
    { project-id: uint, voter: principal }
    { vote: bool, voting-power: uint, voted-at: uint }
)

(define-map project-voting-status
    uint
    {
        yes-votes: uint,
        no-votes: uint,
        total-voting-power: uint,
        voting-deadline: uint,
        is-open: bool
    }
)

(define-map project-investments
    { project-id: uint, investor: principal }
    { amount: uint, invested-at: uint }
)

;; Read-only functions
(define-read-only (get-investment (investor principal))
    (map-get? investments investor)
)

(define-read-only (get-project (project-id uint))
    (map-get? projects project-id)
)

(define-read-only (get-total-dao-funds)
    (var-get total-dao-funds)
)

(define-read-only (get-voting-power (investor principal))
    (match (map-get? investments investor)
        investment (get amount investment)
        u0
    )
)

(define-read-only (get-project-vote (project-id uint) (voter principal))
    (map-get? project-votes { project-id: project-id, voter: voter })
)

(define-read-only (get-voting-status (project-id uint))
    (map-get? project-voting-status project-id)
)

(define-read-only (calculate-voting-threshold (project-id uint))
    (let ((voting-status (unwrap-panic (get-voting-status project-id))))
        (/ (* (get total-voting-power voting-status) u51) u100) ;; 51% threshold
    )
)

;; Public functions

;; Join DAO by investing STX
(define-public (join-dao (amount uint))
    (let (
        (current-investment (default-to { amount: u0, join-block: u0 } 
                           (map-get? investments tx-sender)))
    )
        (asserts! (>= amount (var-get min-investment)) err-invalid-amount)
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
        
        (var-set total-dao-funds (+ (var-get total-dao-funds) amount))
        
        (map-set investments tx-sender {
            amount: (+ (get amount current-investment) amount),
            join-block: (if (> (get amount current-investment) u0) 
                           (get join-block current-investment) 
                           block-height)
        })
        
        (ok true)
    )
)

;; Create a new project proposal
(define-public (create-project 
    (title (string-ascii 100))
    (description (string-ascii 500))
    (funding-goal uint)
    (deadline uint))
    (let ((project-id (var-get next-project-id)))
        (asserts! (> funding-goal u0) err-invalid-amount)
        (asserts! (> deadline block-height) err-invalid-amount)
        
        (map-set projects project-id {
            title: title,
            description: description,
            funding-goal: funding-goal,
            current-funding: u0,
            creator: tx-sender,
            status: "active",
            created-at: block-height,
            deadline: deadline
        })
        
        ;; Initialize voting for the project
        (map-set project-voting-status project-id {
            yes-votes: u0,
            no-votes: u0,
            total-voting-power: (var-get total-dao-funds),
            voting-deadline: (+ block-height u144), ;; ~24 hours
            is-open: true
        })
        
        (var-set next-project-id (+ project-id u1))
        (ok project-id)
    )
)

;; Vote on a project proposal
(define-public (vote-on-project (project-id uint) (vote bool))
    (let (
        (voter-power (get-voting-power tx-sender))
        (voting-status (unwrap! (get-voting-status project-id) err-not-found))
        (existing-vote (get-project-vote project-id tx-sender))
    )
        (asserts! (> voter-power u0) err-unauthorized)
        (asserts! (get is-open voting-status) err-voting-closed)
        (asserts! (<= block-height (get voting-deadline voting-status)) err-voting-closed)
        (asserts! (is-none existing-vote) err-already-voted)
        
        ;; Record the vote
        (map-set project-votes 
            { project-id: project-id, voter: tx-sender }
            { vote: vote, voting-power: voter-power, voted-at: block-height }
        )
        
        ;; Update voting status
        (map-set project-voting-status project-id
            (if vote
                (merge voting-status { yes-votes: (+ (get yes-votes voting-status) voter-power) })
                (merge voting-status { no-votes: (+ (get no-votes voting-status) voter-power) })
            )
        )
        
        (ok true)
    )
)

;; Finalize voting and fund project if approved
(define-public (finalize-project-voting (project-id uint))
    (let (
        (project (unwrap! (get-project project-id) err-not-found))
        (voting-status (unwrap! (get-voting-status project-id) err-not-found))
        (threshold (calculate-voting-threshold project-id))
    )
        (asserts! (get is-open voting-status) err-voting-closed)
        (asserts! (> block-height (get voting-deadline voting-status)) err-voting-closed)
        
        ;; Close voting
        (map-set project-voting-status project-id
            (merge voting-status { is-open: false })
        )
        
        ;; Check if project is approved (yes votes > threshold)
        (if (> (get yes-votes voting-status) threshold)
            (begin
                ;; Project approved - fund it
                (try! (as-contract (stx-transfer? 
                    (get funding-goal project) 
                    tx-sender 
                    (get creator project))))
                
                (var-set total-dao-funds 
                    (- (var-get total-dao-funds) (get funding-goal project)))
                
                (map-set projects project-id
                    (merge project { 
                        status: "funded",
                        current-funding: (get funding-goal project)
                    })
                )
                (ok "approved")
            )
            (begin
                ;; Project rejected
                (map-set projects project-id
                    (merge project { status: "cancelled" })
                )
                (ok "rejected")
            )
        )
    )
)

;; Invest in a specific funded project
(define-public (invest-in-project (project-id uint) (amount uint))
    (let ((project (unwrap! (get-project project-id) err-not-found)))
        (asserts! (is-eq (get status project) "funded") err-project-not-active)
        (asserts! (> amount u0) err-invalid-amount)
        
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
        
        ;; Record project investment
        (map-set project-investments 
            { project-id: project-id, investor: tx-sender }
            { amount: amount, invested-at: block-height }
        )
        
        (ok true)
    )
)

;; Mark project as completed (only creator)
(define-public (complete-project (project-id uint))
    (let ((project (unwrap! (get-project project-id) err-not-found)))
        (asserts! (is-eq tx-sender (get creator project)) err-unauthorized)
        (asserts! (is-eq (get status project) "funded") err-project-not-active)
        
        (map-set projects project-id
            (merge project { status: "completed" })
        )
        
        (ok true)
    )
)

;; Emergency functions (owner only)
(define-public (set-min-investment (new-min uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (var-set min-investment new-min)
        (ok true)
    )
)

(define-public (emergency-pause-voting (project-id uint))
    (let ((voting-status (unwrap! (get-voting-status project-id) err-not-found)))
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        
        (map-set project-voting-status project-id
            (merge voting-status { is-open: false })
        )
        
        (ok true)
    )
)