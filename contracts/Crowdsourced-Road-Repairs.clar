(define-data-var next-project-id uint u1)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-PARAMS (err u101))
(define-constant ERR-BAD-STATE (err u102))
(define-constant ERR-NOT-FOUND (err u103))
(define-constant STATUS-PROPOSED u0)
(define-constant STATUS-ACTIVE u1)
(define-constant STATUS-FUNDED u2)
(define-constant STATUS-COMPLETED u3)
(define-constant STATUS-CANCELED u4)
(define-constant STATUS-EXPIRED u5)
(define-map projects
    { id: uint }
    {
        proposer: principal,
        title: (buff 64),
        location: (buff 64),
        goal: uint,
        pledged: uint,
        deadline: uint,
        status: uint,
        contractor: (optional principal),
        created-at: uint,
        updated-at: uint,
    }
)
(define-map contributions
    {
        id: uint,
        sender: principal,
    }
    {
        amount: uint,
        refunded: bool,
        contributed-at: uint,
    }
)
(define-data-var total-projects uint u0)
(define-data-var total-pledged uint u0)
(define-data-var total-completed uint u0)
(define-data-var total-canceled uint u0)
(define-data-var total-expired uint u0)
(define-read-only (now)
    stacks-block-height
)
(define-read-only (get-project (project-id uint))
    (match (map-get? projects { id: project-id })
        proj (ok proj)
        ERR-NOT-FOUND
    )
)
(define-read-only (get-contribution
        (project-id uint)
        (who principal)
    )
    (match (map-get? contributions {
        id: project-id,
        sender: who,
    })
        c (ok c)
        ERR-NOT-FOUND
    )
)
(define-read-only (get-status (project-id uint))
    (match (map-get? projects { id: project-id })
        p (ok (get status p))
        ERR-NOT-FOUND
    )
)
(define-read-only (is-owner
        (project-id uint)
        (who principal)
    )
    (match (map-get? projects { id: project-id })
        p (ok (is-eq who (get proposer p)))
        (ok false)
    )
)
(define-read-only (is-active (project-id uint))
    (match (map-get? projects { id: project-id })
        p (ok (is-eq (get status p) STATUS-ACTIVE))
        (ok false)
    )
)
(define-read-only (is-funded (project-id uint))
    (match (map-get? projects { id: project-id })
        p (ok (is-eq (get status p) STATUS-FUNDED))
        (ok false)
    )
)
(define-read-only (is-completed (project-id uint))
    (match (map-get? projects { id: project-id })
        p (ok (is-eq (get status p) STATUS-COMPLETED))
        (ok false)
    )
)
(define-read-only (is-canceled (project-id uint))
    (match (map-get? projects { id: project-id })
        p (ok (is-eq (get status p) STATUS-CANCELED))
        (ok false)
    )
)
(define-read-only (is-expired (project-id uint))
    (match (map-get? projects { id: project-id })
        p (let (
                (dl (get deadline p))
                (st (get status p))
            )
            (ok (and (>= stacks-block-height dl) (or (is-eq st STATUS-ACTIVE) (is-eq st STATUS-PROPOSED))))
        )
        (ok false)
    )
)
(define-private (ensure-project-exists (project-id uint))
    (match (map-get? projects { id: project-id })
        proj (ok true)
        ERR-NOT-FOUND
    )
)
(define-private (assert-condition
        (cond bool)
        (err-res (response bool uint))
    )
    (if cond
        (ok true)
        err-res
    )
)
(define-public (create-project
        (title (buff 64))
        (location (buff 64))
        (goal uint)
        (deadline uint)
    )
    (begin
        (unwrap! (assert-condition (> (len title) u0) ERR-INVALID-PARAMS)
            ERR-INVALID-PARAMS
        )
        (unwrap! (assert-condition (> (len location) u0) ERR-INVALID-PARAMS)
            ERR-INVALID-PARAMS
        )
        (unwrap! (assert-condition (> goal u0) ERR-INVALID-PARAMS)
            ERR-INVALID-PARAMS
        )
        (unwrap!
            (assert-condition (> deadline stacks-block-height) ERR-INVALID-PARAMS)
            ERR-INVALID-PARAMS
        )
        (let (
                (pid (var-get next-project-id))
                (now-height stacks-block-height)
            )
            (map-set projects { id: pid } {
                proposer: tx-sender,
                title: title,
                location: location,
                goal: goal,
                pledged: u0,
                deadline: deadline,
                status: STATUS-ACTIVE,
                contractor: none,
                created-at: now-height,
                updated-at: now-height,
            })
            (var-set total-projects (+ (var-get total-projects) u1))
            (var-set next-project-id (+ pid u1))
            (ok pid)
        )
    )
)
(define-public (update-contractor
        (project-id uint)
        (who principal)
    )
    (begin
        (unwrap!
            (assert-condition (not (is-eq who 'SP000000000000000000002Q6VF78))
                ERR-INVALID-PARAMS
            )
            ERR-INVALID-PARAMS
        )
        (unwrap! (ensure-project-exists project-id) ERR-NOT-FOUND)
        (match (map-get? projects { id: project-id })
            p (begin
                (unwrap!
                    (assert-condition (is-eq tx-sender (get proposer p))
                        ERR-NOT-AUTHORIZED
                    )
                    ERR-NOT-AUTHORIZED
                )
                (unwrap!
                    (assert-condition
                        (or (is-eq (get status p) STATUS-ACTIVE) (is-eq (get status p) STATUS-FUNDED))
                        ERR-BAD-STATE
                    )
                    ERR-BAD-STATE
                )
                (map-set projects { id: project-id } {
                    proposer: (get proposer p),
                    title: (get title p),
                    location: (get location p),
                    goal: (get goal p),
                    pledged: (get pledged p),
                    deadline: (get deadline p),
                    status: (get status p),
                    contractor: (some who),
                    created-at: (get created-at p),
                    updated-at: stacks-block-height,
                })
                (ok true)
            )
            ERR-NOT-FOUND
        )
    )
)
(define-public (cancel-project (project-id uint))
    (begin
        (unwrap! (ensure-project-exists project-id) ERR-NOT-FOUND)
        (match (map-get? projects { id: project-id })
            p (begin
                (unwrap!
                    (assert-condition (is-eq tx-sender (get proposer p))
                        ERR-NOT-AUTHORIZED
                    )
                    ERR-NOT-AUTHORIZED
                )
                (unwrap!
                    (assert-condition
                        (or (is-eq (get status p) STATUS-ACTIVE) (is-eq (get status p) STATUS-PROPOSED))
                        ERR-BAD-STATE
                    )
                    ERR-BAD-STATE
                )
                (map-set projects { id: project-id } {
                    proposer: (get proposer p),
                    title: (get title p),
                    location: (get location p),
                    goal: (get goal p),
                    pledged: (get pledged p),
                    deadline: (get deadline p),
                    status: STATUS-CANCELED,
                    contractor: (get contractor p),
                    created-at: (get created-at p),
                    updated-at: stacks-block-height,
                })
                (var-set total-canceled (+ (var-get total-canceled) u1))
                (ok true)
            )
            ERR-NOT-FOUND
        )
    )
)
(define-public (expire-project (project-id uint))
    (begin
        (unwrap! (ensure-project-exists project-id) ERR-NOT-FOUND)
        (match (map-get? projects { id: project-id })
            p (let (
                    (st (get status p))
                    (dl (get deadline p))
                    (pl (get pledged p))
                    (gl (get goal p))
                )
                (unwrap!
                    (assert-condition
                        (or (is-eq st STATUS-ACTIVE) (is-eq st STATUS-PROPOSED))
                        ERR-BAD-STATE
                    )
                    ERR-BAD-STATE
                )
                (unwrap!
                    (assert-condition (>= stacks-block-height dl) ERR-BAD-STATE)
                    ERR-BAD-STATE
                )
                (unwrap! (assert-condition (< pl gl) ERR-BAD-STATE) ERR-BAD-STATE)
                (map-set projects { id: project-id } {
                    proposer: (get proposer p),
                    title: (get title p),
                    location: (get location p),
                    goal: (get goal p),
                    pledged: pl,
                    deadline: dl,
                    status: STATUS-EXPIRED,
                    contractor: (get contractor p),
                    created-at: (get created-at p),
                    updated-at: stacks-block-height,
                })
                (var-set total-expired (+ (var-get total-expired) u1))
                (ok true)
            )
            ERR-NOT-FOUND
        )
    )
)
(define-public (contribute
        (project-id uint)
        (amount uint)
    )
    (begin
        (unwrap! (assert-condition (> amount u0) ERR-INVALID-PARAMS)
            ERR-INVALID-PARAMS
        )
        (unwrap! (ensure-project-exists project-id) ERR-NOT-FOUND)
        (match (map-get? projects { id: project-id })
            p (let (
                    (st (get status p))
                    (dl (get deadline p))
                    (now-height stacks-block-height)
                    (prev (map-get? contributions {
                        id: project-id,
                        sender: tx-sender,
                    }))
                )
                (unwrap!
                    (assert-condition
                        (or (is-eq st STATUS-ACTIVE) (is-eq st STATUS-PROPOSED))
                        ERR-BAD-STATE
                    )
                    ERR-BAD-STATE
                )
                (unwrap! (assert-condition (< now-height dl) ERR-BAD-STATE)
                    ERR-BAD-STATE
                )
                (match prev
                    existing (let (
                            (prev-amount (get amount existing))
                            (prev-pledged (get pledged p))
                            (new-contrib-amount (+ prev-amount amount))
                            (new-pledged (+ prev-pledged amount))
                        )
                        (unwrap!
                            (assert-condition (>= new-contrib-amount prev-amount)
                                ERR-INVALID-PARAMS
                            )
                            ERR-INVALID-PARAMS
                        )
                        (unwrap!
                            (assert-condition (>= new-pledged prev-pledged)
                                ERR-INVALID-PARAMS
                            )
                            ERR-INVALID-PARAMS
                        )
                        (map-set contributions {
                            id: project-id,
                            sender: tx-sender,
                        } {
                            amount: new-contrib-amount,
                            refunded: false,
                            contributed-at: now-height,
                        })
                        (map-set projects { id: project-id } {
                            proposer: (get proposer p),
                            title: (get title p),
                            location: (get location p),
                            goal: (get goal p),
                            pledged: new-pledged,
                            deadline: (get deadline p),
                            status: st,
                            contractor: (get contractor p),
                            created-at: (get created-at p),
                            updated-at: now-height,
                        })
                        (var-set total-pledged (+ (var-get total-pledged) amount))
                        (ok new-pledged)
                    )
                    (let (
                            (prev-pledged (get pledged p))
                            (new-pledged (+ prev-pledged amount))
                        )
                        (unwrap!
                            (assert-condition (>= new-pledged prev-pledged)
                                ERR-INVALID-PARAMS
                            )
                            ERR-INVALID-PARAMS
                        )
                        (map-set contributions {
                            id: project-id,
                            sender: tx-sender,
                        } {
                            amount: amount,
                            refunded: false,
                            contributed-at: now-height,
                        })
                        (map-set projects { id: project-id } {
                            proposer: (get proposer p),
                            title: (get title p),
                            location: (get location p),
                            goal: (get goal p),
                            pledged: new-pledged,
                            deadline: (get deadline p),
                            status: st,
                            contractor: (get contractor p),
                            created-at: (get created-at p),
                            updated-at: now-height,
                        })
                        (var-set total-pledged (+ (var-get total-pledged) amount))
                        (ok new-pledged)
                    )
                )
            )
            ERR-NOT-FOUND
        )
    )
)
(define-public (mark-funded (project-id uint))
    (begin
        (unwrap! (ensure-project-exists project-id) ERR-NOT-FOUND)
        (match (map-get? projects { id: project-id })
            p (let (
                    (st (get status p))
                    (pl (get pledged p))
                    (gl (get goal p))
                )
                (unwrap!
                    (assert-condition (is-eq tx-sender (get proposer p))
                        ERR-NOT-AUTHORIZED
                    )
                    ERR-NOT-AUTHORIZED
                )
                (unwrap!
                    (assert-condition
                        (or (is-eq st STATUS-ACTIVE) (is-eq st STATUS-PROPOSED))
                        ERR-BAD-STATE
                    )
                    ERR-BAD-STATE
                )
                (unwrap! (assert-condition (>= pl gl) ERR-BAD-STATE)
                    ERR-BAD-STATE
                )
                (map-set projects { id: project-id } {
                    proposer: (get proposer p),
                    title: (get title p),
                    location: (get location p),
                    goal: gl,
                    pledged: pl,
                    deadline: (get deadline p),
                    status: STATUS-FUNDED,
                    contractor: (get contractor p),
                    created-at: (get created-at p),
                    updated-at: stacks-block-height,
                })
                (ok true)
            )
            ERR-NOT-FOUND
        )
    )
)
(define-public (mark-completed (project-id uint))
    (begin
        (unwrap! (ensure-project-exists project-id) ERR-NOT-FOUND)
        (match (map-get? projects { id: project-id })
            p (let ((st (get status p)))
                (unwrap!
                    (assert-condition
                        (or (is-eq tx-sender (get proposer p)) (is-eq (some tx-sender) (get contractor p)))
                        ERR-NOT-AUTHORIZED
                    )
                    ERR-NOT-AUTHORIZED
                )
                (unwrap!
                    (assert-condition
                        (or (is-eq st STATUS-FUNDED) (is-eq st STATUS-ACTIVE))
                        ERR-BAD-STATE
                    )
                    ERR-BAD-STATE
                )
                (map-set projects { id: project-id } {
                    proposer: (get proposer p),
                    title: (get title p),
                    location: (get location p),
                    goal: (get goal p),
                    pledged: (get pledged p),
                    deadline: (get deadline p),
                    status: STATUS-COMPLETED,
                    contractor: (get contractor p),
                    created-at: (get created-at p),
                    updated-at: stacks-block-height,
                })
                (var-set total-completed (+ (var-get total-completed) u1))
                (ok true)
            )
            ERR-NOT-FOUND
        )
    )
)
(define-public (refund (project-id uint))
    (begin
        (unwrap! (ensure-project-exists project-id) ERR-NOT-FOUND)
        (match (map-get? projects { id: project-id })
            p (let (
                    (st (get status p))
                    (rec (map-get? contributions {
                        id: project-id,
                        sender: tx-sender,
                    }))
                )
                (unwrap!
                    (assert-condition
                        (or (is-eq st STATUS-CANCELED) (is-eq st STATUS-EXPIRED))
                        ERR-BAD-STATE
                    )
                    ERR-BAD-STATE
                )
                (match rec
                    c (begin
                        (unwrap!
                            (assert-condition (not (get refunded c))
                                ERR-BAD-STATE
                            )
                            ERR-BAD-STATE
                        )
                        (map-set contributions {
                            id: project-id,
                            sender: tx-sender,
                        } {
                            amount: (get amount c),
                            refunded: true,
                            contributed-at: (get contributed-at c),
                        })
                        (ok (get amount c))
                    )
                    ERR-NOT-FOUND
                )
            )
            ERR-NOT-FOUND
        )
    )
)
(define-read-only (stats)
    {
        total-projects: (var-get total-projects),
        total-pledged: (var-get total-pledged),
        total-completed: (var-get total-completed),
        total-canceled: (var-get total-canceled),
        total-expired: (var-get total-expired),
    }
)
(define-read-only (project-progress (project-id uint))
    (match (map-get? projects { id: project-id })
        p
        {
            pledged: (get pledged p),
            goal: (get goal p),
        }
        {
            pledged: u0,
            goal: u0,
        }
    )
)
(define-read-only (has-contributed
        (project-id uint)
        (who principal)
    )
    (match (map-get? contributions {
        id: project-id,
        sender: who,
    })
        c (ok (> (get amount c) u0))
        (ok false)
    )
)
(define-read-only (get-contributor-amount
        (project-id uint)
        (who principal)
    )
    (match (map-get? contributions {
        id: project-id,
        sender: who,
    })
        c (ok (get amount c))
        (ok u0)
    )
)
(define-read-only (can-refund
        (project-id uint)
        (who principal)
    )
    (match (map-get? projects { id: project-id })
        p (match (map-get? contributions {
            id: project-id,
            sender: who,
        })
            c (ok (and (or (is-eq (get status p) STATUS-CANCELED) (is-eq (get status p) STATUS-EXPIRED)) (not (get refunded c))))
            (ok false)
        )
        (ok false)
    )
)
(define-read-only (project-expired (project-id uint))
    (match (map-get? projects { id: project-id })
        p (ok (and (>= stacks-block-height (get deadline p)) (< (get pledged p) (get goal p))))
        (ok false)
    )
)
(define-read-only (project-funded (project-id uint))
    (match (map-get? projects { id: project-id })
        p (ok (>= (get pledged p) (get goal p)))
        (ok false)
    )
)
(define-read-only (get-next-project-id)
    (ok (var-get next-project-id))
)
(define-read-only (get-remaining-funds (project-id uint))
    (match (map-get? projects { id: project-id })
        p (let (
                (goal (get goal p))
                (pledged (get pledged p))
            )
            (if (>= pledged goal)
                (ok u0)
                (ok (- goal pledged))
            )
        )
        (ok u0)
    )
)
(define-read-only (get-funding-percentage (project-id uint))
    (match (map-get? projects { id: project-id })
        p (let (
                (goal (get goal p))
                (pledged (get pledged p))
            )
            (if (> goal u0)
                (ok (/ (* pledged u100) goal))
                (ok u0)
            )
        )
        (ok u0)
    )
)
(define-map update-counters
    { id: uint }
    { next: uint }
)
(define-map project-updates
    {
        id: uint,
        seq: uint,
    }
    {
        author: principal,
        message: (buff 160),
        created-at: uint,
    }
)
(define-public (post-update
        (project-id uint)
        (message (buff 160))
    )
    (begin
        (unwrap! (ensure-project-exists project-id) ERR-NOT-FOUND)
        (match (map-get? projects { id: project-id })
            p (let (
                    (st (get status p))
                    (auth-ok (or (is-eq tx-sender (get proposer p)) (is-eq (some tx-sender) (get contractor p))))
                    (allowed-state (or
                        (is-eq st STATUS-ACTIVE)
                        (is-eq st STATUS-FUNDED)
                        (is-eq st STATUS-COMPLETED)
                    ))
                    (now-height stacks-block-height)
                    (counter (map-get? update-counters { id: project-id }))
                )
                (unwrap! (assert-condition auth-ok ERR-NOT-AUTHORIZED)
                    ERR-NOT-AUTHORIZED
                )
                (unwrap! (assert-condition allowed-state ERR-BAD-STATE)
                    ERR-BAD-STATE
                )
                (match counter
                    c (let ((seq (get next c)))
                        (map-set project-updates {
                            id: project-id,
                            seq: seq,
                        } {
                            author: tx-sender,
                            message: message,
                            created-at: now-height,
                        })
                        (map-set update-counters { id: project-id } { next: (+ seq u1) })
                        (ok seq)
                    )
                    (let ((seq u0))
                        (map-set project-updates {
                            id: project-id,
                            seq: seq,
                        } {
                            author: tx-sender,
                            message: message,
                            created-at: now-height,
                        })
                        (map-set update-counters { id: project-id } { next: u1 })
                        (ok seq)
                    )
                )
            )
            ERR-NOT-FOUND
        )
    )
)
(define-read-only (get-update-count (project-id uint))
    (match (map-get? update-counters { id: project-id })
        c (ok (get next c))
        (ok u0)
    )
)
(define-read-only (get-update
        (project-id uint)
        (seq uint)
    )
    (match (map-get? project-updates {
        id: project-id,
        seq: seq,
    })
        u (ok u)
        ERR-NOT-FOUND
    )
)
