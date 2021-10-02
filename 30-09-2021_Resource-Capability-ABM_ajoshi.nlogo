globals [
  capability-period ; time period (number of ticks) over which the capability attainment running average is calculated; determines frequency of capability need
  max-sys-damage-this-run ; among built-systems...these are used later to calibrate the damage and recovery functions for built systems
  min-sys-damage-this-run
  max-sys-recovery-this-run
  min-sys-recovery-this-run
  sys-damage-range
  sys-recovery-range
  sample-people ; to plot the avg-capability-attainment of a few people each run
  sample-built-systems ; likewise, to plot system-state for some built systems
  num-people-expired
  communal-pool-total
  communal-pool-now
  aggr-system-damages
  aggr-system-recoveries
  aggr-capability-provided
  aggr-capability-help
  aggr-access-potential-transferred
  access-potential-initial-global-mean
  access-potential-initial-global-stdev
  access-potential-final-global-mean
  access-potential-final-global-stdev
  max-global-mean-capability-attainment
  min-global-mean-capability-attainment
  max-global-mean-system-state
  min-global-mean-system-state
  global-cap-attnm-last-two
  global-mean-cap-attnm-gradient
  global-sys-state-last-two
  global-mean-sys-state-gradient
  run-seed
]

patches-own [
  owner
]

breed [ people a-person ]
breed [ built-systems a-built-system ]
undirected-link-breed [ people-to-people-links a-person-to-person-link ]
undirected-link-breed [ people-to-sys-links a-person-to-sys-link ]

people-own [
  access-potential
  social-capital
  action-energy
  my-network
  my-built-sys-network
  capability-threshold-low
  capability-threshold-high
  capability-min-limit
  capability-attainment
  capability-attained-now
  capability-attained-this-tick
  avg-capability-attainment
  seek-capability?
  responsibility-ready?
  help-call-counter
  capability-help-received-this-tick
  access-potential-now
  access-potential-transferred-this-tick
  access-potential-received-this-tick
  share-call-counter
  capability-call-successes
  capability-call-failures
  capability-call-memory
  pooled-access-potential?
]

built-systems-own [
  system-state
  my-users ; people linked to me and who call on me to attain capability
  capability-provided-now
  capability-provided-this-tick
  capability-provided-total
  capability-call-counter
  net-system-state-change-this-tick
  system-damage-now
  system-damage-this-tick
  avg-system-damage-this-tick
  repair-call-counter
  system-recovery-now
  system-recovery-this-tick
  avg-system-recovery-this-tick
  damage-impact
  recovery-impact
  random-damage-this-tick
  random-damage-impact
]

to setup
  clear-all
  set run-seed new-seed
  random-seed run-seed
  set-default-shape people "person"
  set-default-shape built-systems "campsite"
  if fix-seed? [ random-seed behaviorspace-run-number ]
  setup-parameters
  setup-social-system
  setup-networks
  set sample-people n-of 5 people
  set access-potential-initial-global-mean mean [ access-potential ] of people
  set access-potential-initial-global-stdev standard-deviation [ access-potential ] of people
  reset-ticks
end

to setup-parameters
  set capability-period 4
  set number-of-people 200
  set number-of-built-systems 12
  set network-radius 45
  set random-damage-limit precision ( 0.1 + random-float ( 100 / 3 - 0.1 ) ) 2
  ; set random-damage-limit precision ( random-float 100 ) 2
  ; set seek-capability-when one-of [ "avg-capability-attainment < capability-low" "avg-capability-attainment < capability-high" ]
  set seek-capability-when one-of [ "avg-capability-attainment < capability-high" ]
  set share-access-potential one-of [ "no" "yes, through personal transfers" "yes, through a community fund" ]
  ; set capability-lim precision ( 0.1 + random-float ( 0.33 - 0.1 ) ) 2
  ; set capability-low precision ( capability-lim + random-float ( 0.667 - capability-lim ) ) 2
  ; set capability-high precision ( capability-low + random-float ( 1 - capability-low ) ) 2
  ; set capability-high precision ( capability-low + random-float ( 1 - 0.667 ) ) 2
  set capability-lim 0.25
  set capability-low 0.5
  set capability-high 0.75
  set built-sys-capability-output "capability-high"
  ; set built-sys-capability-output "capability-low < X < capability-high"
  ; set built-sys-capability-output one-of [ "capability-high" "capability-low < X < capability-high" ]
  set built-sys-state-min 0.3
  set built-sys-state-max 0.9
  set built-sys-operation-threshold 0.2
  ; set capability-call-help true
  ifelse random 100 >= 75 [ set capability-call-help true ] [ set capability-call-help false ]
  ; set repair-or-help-chance random 101 ; to randomize this probablity within a certain range when running BehaviorSpace experiments
  set repair-or-help-chance 100
end

to setup-social-system
  ask patches [ set pcolor 77 set owner nobody ]
  ask n-of number-of-people patches [ set-a-person ]
  ask n-of number-of-built-systems patches with [ owner = nobody ] [ set-a-built-system ]
  initialize-indicators-min-and-max
  ask patches with [ owner = nobody ] [ plant-flowers ]
end

to set-a-person
  sprout-people 1 [
    set access-potential precision ( min-access-potential + random-float ( max-access-potential - min-access-potential ) ) 2
    if set-social-capital-as = "a function of access-potential" [ set social-capital ( access-potential ^ ( 1 / 3 ) ) ]
    if set-social-capital-as = "independent of access-potential" [ set social-capital precision ( min-social-capital +
      random-float ( max-social-capital - min-social-capital ) ) 2 ]
    set access-potential-now access-potential
    set capability-threshold-low capability-low
    set capability-threshold-high capability-high
    set capability-min-limit capability-lim
    set capability-attainment n-values capability-period [ precision ( capability-min-limit + random-float ( capability-high - capability-min-limit ) ) 2 ]
    set avg-capability-attainment mean capability-attainment
    set capability-attained-this-tick avg-capability-attainment
    set my-network nobody
    set my-built-sys-network nobody
    set size 1.2 * access-potential-now ^ ( 1 / 2 )
    set pcolor 48
    set owner myself ; setting the patch variable 'owner' to the patch occupant
    if seek-capability-when = "avg-capability-attainment < capability-low" [
    ifelse avg-capability-attainment < capability-threshold-low [ set seek-capability? true ]
      [ set seek-capability? false ] ]
    if seek-capability-when = "avg-capability-attainment < capability-high" [
    ifelse avg-capability-attainment < capability-threshold-high [ set seek-capability? true ]
      [ set seek-capability? false ] ]
    ifelse avg-capability-attainment >= capability-threshold-low
    [ set responsibility-ready? true set color scale-color red ( avg-capability-attainment ^ 3 ) 1 0 ]
    [ set responsibility-ready? false set color scale-color sky ( avg-capability-attainment ^ ( 1 / 3 ) ) 1 0 ]
    set capability-call-memory n-values capability-period [ random 2 ]
  ]
end

to set-a-built-system
  sprout-built-systems 1 [
    set system-state ( built-sys-state-min + random-float ( built-sys-state-max - built-sys-state-min ) )
    set color 106
    set size 2
    set pcolor 1
    set owner myself ; setting the patch variable 'owner' to the patch occupant
  ]
end

to initialize-indicators-min-and-max
  set max-global-mean-capability-attainment mean [ avg-capability-attainment ] of people
  set min-global-mean-capability-attainment mean [ avg-capability-attainment ] of people
  set max-global-mean-system-state mean [ system-state ] of built-systems
  set min-global-mean-system-state mean [ system-state ] of built-systems
  set global-cap-attnm-last-two n-values 2 [ 0 ]
  set global-sys-state-last-two n-values 2 [ 0 ]
end

to plant-flowers
  sprout 1 [
    ifelse 0.5 >= random-float 1 [ set shape "flower" set color 45 ]
    [ set shape "plant medium" set color 64 ]
    set size 0.5
    set pcolor 77
    set owner myself
  ]
end

to setup-networks
  let world-size sqrt ( ( 2 * max-pxcor ) ^ 2 + ( 2 * max-pycor ) ^ 2 )
  let network-scale-limiter ( 0.33 / ( 1 + exp ( - 6 * ( network-radius / 100 - 1 / 2 ) ) ) ) + 0.27
  let societal-range-people ( world-size * network-scale-limiter ^ exp 1 )
  ask people [
    let my-neighbours other people with [ distance myself <= societal-range-people ]
    let num-neighbours count my-neighbours
    let num-links ( social-capital * num-neighbours )
    create-people-to-people-links-with n-of num-links my-neighbours  [
      set color 5 ;
    ]
    set my-network link-neighbors with [ breed = people ]
    ; Now set up links between the person and built system units
    ; **********************************************************************************
    let societal-range-built-systems ( world-size * network-scale-limiter )
    let built-systems-in-range built-systems with [ distance myself <= societal-range-built-systems ]
    ask built-systems-in-range [
      if [ social-capital ] of myself >= random-float 1 [ ; myself is the person agent here (not built system)
        create-a-person-to-sys-link-with myself [
          set color 37
        ]
      ]
      set my-users link-neighbors with [ breed = people ]
      set label ( word count my-users " users   " ) ; just to make the label better visible
      set label-color black
      ask myself [
        set my-built-sys-network link-neighbors with [ breed = built-systems ]
        ask my-people-to-sys-links [ hide-link ]
      ]
    ]
  ]
end

to go
  ; action sequence here
  if ticks >= 3000 [ stop ]
  if ticks > 1 and global-mean-capability-attainment <= 0.01 [ stop ]
  ask patches with [ owner = nobody ] [ plant-flowers ]
  ask people [ do-capability-metabolism ]
  ask built-systems [ impose-random-damage assess-built-system-state ]
  reset-counter-and-holder-variables
  ifelse capability-call-help = false [
    if share-access-potential = "yes, through personal transfers" [ ask people with [ responsibility-ready? = true ] [ transfer-access-potential ] ]
    if share-access-potential = "yes, through a community fund" [ ask people [ pool-access-potential ] ask people [ draw-access-potential ] ] ]
  [ set share-access-potential "no" ]
  set access-potential-final-global-mean mean [ access-potential-now ] of people
  set access-potential-final-global-stdev standard-deviation [ access-potential-now ] of people
  ask people with [ seek-capability? = true ] [ seek-capability ]
  ; ask people with [ responsibility-ready? = true ] [ ifelse repair-or-help-chance >= random-float 100 [ repair-built-systems ] [ help-my-network ] ]
  ask people with [ responsibility-ready? = true ] [ ifelse capability-call-help = true [ help-my-network repair-built-systems ] [ repair-built-systems ] ]
  update-damage-and-recovery-range
  record-max-and-min-indicator-values-this-run
  tick
end

to reset-counter-and-holder-variables
  set aggr-capability-help ( sum [ capability-help-received-this-tick ] of people + aggr-capability-help )
  set aggr-access-potential-transferred ( sum [ access-potential-transferred-this-tick ] of people + aggr-access-potential-transferred )
  ask people [
    set capability-attained-now 0
    set capability-attained-this-tick 0
    set help-call-counter 0
    set capability-help-received-this-tick 0
    set access-potential-transferred-this-tick 0
    set access-potential-received-this-tick 0
    set share-call-counter 0
    set capability-call-successes 0
    set capability-call-failures 0
    set pooled-access-potential? false
  ]
  set aggr-system-damages ( sum [ system-damage-this-tick ] of built-systems + aggr-system-damages )
  set aggr-system-recoveries ( sum [ system-recovery-this-tick ] of built-systems + aggr-system-recoveries )
  set aggr-capability-provided ( sum [ capability-provided-this-tick ] of built-systems + aggr-capability-provided )
  ask built-systems [
    set system-damage-now 0
    set system-recovery-now 0
    set capability-call-counter 0
    set repair-call-counter 0
    set capability-provided-this-tick 0
    set system-damage-this-tick 0 ; reset or reinitialize to record system damage for current tick
    set system-recovery-this-tick 0 ; reset or reinitialize to record system recovery for current tick
    set random-damage-this-tick 0
  ]
  set communal-pool-total 0
  ;; Here we calculate the rate at which the global mean values for capability attainment and built system state change tick by tick
  set global-cap-attnm-last-two lput global-mean-capability-attainment global-cap-attnm-last-two
  if length global-cap-attnm-last-two > 2 [ set global-cap-attnm-last-two but-first global-cap-attnm-last-two ]
  ifelse item 0 global-cap-attnm-last-two != 0 [
    set global-mean-cap-attnm-gradient ( item 1 global-cap-attnm-last-two - item 0 global-cap-attnm-last-two ) / item 0 global-cap-attnm-last-two ]
  [ set global-mean-cap-attnm-gradient 0 ]
  set global-sys-state-last-two lput avg-built-sys-state global-sys-state-last-two
  if length global-sys-state-last-two > 2 [ set global-sys-state-last-two but-first global-sys-state-last-two ]
  ifelse item 0 global-sys-state-last-two != 0 [
    set global-mean-sys-state-gradient ( item 1 global-sys-state-last-two - item 0 global-sys-state-last-two ) / item 0 global-sys-state-last-two ]
  [ set global-mean-sys-state-gradient 0 ]
end

to do-capability-metabolism
  ifelse capability-attained-this-tick = 0 [ set capability-call-failures capability-call-failures + 1 ]
  [ set capability-call-successes capability-call-successes + 1 ]
  set capability-attainment lput capability-attained-this-tick capability-attainment ; records capability attainment from previous tick in a list
  if length capability-attainment > capability-period [ set capability-attainment but-first capability-attainment ]
  set avg-capability-attainment mean capability-attainment
  set action-energy ( avg-capability-attainment )
  ; set action-energy ( avg-capability-attainment ^ ( 1 / 2 ) ) ; the currency/quantity 'action-energy' is a function of capability attainment running average
  ; an individual is allowed to expend up to this amount (e.g. of energy and resources) towards justice and adaptive actions in one tick
  set capability-call-memory lput capability-call-success-rate self capability-call-memory
  if length capability-call-memory > capability-period [ set capability-call-memory but-first capability-call-memory ]
  ; print capability-call-memory
  if seek-capability-when = "avg-capability-attainment < capability-low" [
    ifelse avg-capability-attainment < capability-threshold-low [ set seek-capability? true ]
      [ set seek-capability? false ] ]
  if seek-capability-when = "avg-capability-attainment < capability-high" [
    ifelse avg-capability-attainment < capability-threshold-high [ set seek-capability? true ]
      [ set seek-capability? false ] ]
  ifelse avg-capability-attainment >= capability-threshold-low
  [ set responsibility-ready? true set color scale-color red ( avg-capability-attainment ^ 3 ) 1 0 ]
  [ set responsibility-ready? false set color scale-color sky ( avg-capability-attainment ^ ( 1 / 3 ) ) 1 0 ]
  set access-potential-now access-potential
  set size 1.2 * access-potential-now ^ ( 1 / 2 )
  if people-expire? = true [ if avg-capability-attainment < capability-min-limit [
    set num-people-expired ( num-people-expired + 1 )
    set pcolor 36 set plabel "X" set owner nobody die ] ]
end

to update-damage-and-recovery-range ; to calibrate the system-state of built systems on the same scale
  let min-sys-damage-this-tick min [ system-damage-this-tick ] of built-systems
  let min-sys-recovery-this-tick min [ system-recovery-this-tick ] of built-systems
  let max-sys-damage-this-tick max [ system-damage-this-tick ] of built-systems
  let max-sys-recovery-this-tick max [ system-recovery-this-tick ] of built-systems
  if max-sys-damage-this-run < max-sys-damage-this-tick [ set max-sys-damage-this-run max-sys-damage-this-tick ]
  if min-sys-damage-this-run > min-sys-damage-this-tick [ set min-sys-damage-this-run min-sys-damage-this-tick ]
  set sys-damage-range ( max-sys-damage-this-run - min-sys-damage-this-run )
  ; print sys-damage-range
  if max-sys-recovery-this-run < max-sys-recovery-this-tick [ set max-sys-recovery-this-run max-sys-recovery-this-tick ]
  if min-sys-recovery-this-run > min-sys-recovery-this-tick [ set min-sys-recovery-this-run min-sys-recovery-this-tick ]
  set sys-recovery-range ( max-sys-recovery-this-run - min-sys-recovery-this-run )
  ; print sys-recovery-range
end

to assess-built-system-state
  ; the logistic function is f(x)= L/(1+exp^(-k(x-x0))), where L is the curve's max. value, k its growth rate or steepness, and x0 the x-value of the sigmoid's midpoint
  ; a logistic curve with no x0 term will only have a [0.5,1] range for +ve system damage and recovery values, as we have
  ; to cover the range [0,1], we need to shift the logistic curve to the right by introducing the correction x0
  ifelse system-damage-this-tick = 0 [ set damage-impact 0 ]
  [ set damage-impact 1 / ( 1 + exp ( - ( system-damage-this-tick - ( min-sys-damage-this-run + sys-damage-range / 2 ) ) ) ) ]
  ifelse system-recovery-this-tick = 0 [ set recovery-impact 0 ]
  [ set recovery-impact 1 / ( 1 + exp ( - ( system-recovery-this-tick - ( min-sys-damage-this-run + sys-damage-range / 2 ) ) ) ) ]
  ; ifelse random-damage-this-tick = 0 [ set random-damage-impact 0 ]
  ; [ set random-damage-impact 1 / ( 1 + exp ( - ( random-damage-this-tick - ( min-sys-damage-this-run + sys-damage-range / 2 ) ) ) ) ]
  set random-damage-impact random-damage-this-tick
  set net-system-state-change-this-tick ( - damage-impact + recovery-impact - random-damage-impact )
  ifelse net-system-state-change-this-tick >= 0 [ set system-state ( system-state + ( 1 - system-state ) * net-system-state-change-this-tick / 100 ) ]
  [ set system-state ( system-state * ( 1 - ( - net-system-state-change-this-tick ) / 100 ) ) ]
  set label ( word precision system-state 2 "       " )
  ifelse system-state <= built-sys-operation-threshold [ set color scale-color black system-state 1 0 ]
  [ set color 106 ]
end

to impose-random-damage
  ; introduce a random damage amount each tick to systems (in proportion to their system-state value); this may be thought of as climate change impact
  ; without this, built systems that reach system-state 1 will suffer no damage at all from that point onward when providing capability, which is unrealistic
  ; set random-damage-this-tick precision ( system-state * sys-damage-range * random-float random-damage-limit / 100 ) 2
  ; set random-damage-this-tick precision ( system-state * random-float random-damage-limit / 100 ) 2
  set random-damage-this-tick precision ( random-float random-damage-limit / 100 ) 2
end

to seek-capability
  ifelse my-built-sys-network != nobody [
    let built-sys-sorted-list sort-on [ ( - system-state ) ] my-built-sys-network ; to call built-systems in descending order of their system-state attribute value
    let num-built-sys-sorted-list length built-sys-sorted-list
    let loop-limit 0
    let user-potential access-potential-now
    while [ capability-attained-now = 0 and loop-limit < num-built-sys-sorted-list ]
    [
      let built-sys-unit-to-call item loop-limit built-sys-sorted-list
      set loop-limit loop-limit + 1
      if built-sys-unit-to-call != nobody [
        ask built-sys-unit-to-call [
          if system-state >= built-sys-operation-threshold [
            if ( user-potential * system-state ^ ( 1 / 2 ) ) >= random-float 1 [
              ask myself [
                if built-sys-capability-output = "capability-high" [ set capability-attained-now capability-threshold-high ]
                if built-sys-capability-output = "capability-low < X < capability-high" [ set capability-attained-now ( capability-threshold-low +
                  precision ( random-float capability-threshold-high - capability-threshold-low ) 2 ) ]
                set capability-attained-this-tick ( capability-attained-now + capability-attained-this-tick )
              ]
              set capability-provided-now [ capability-attained-now ] of myself
              set capability-provided-this-tick ( capability-provided-now + capability-provided-this-tick )
              set capability-provided-total ( capability-provided-now + capability-provided-total )
              set system-damage-now ( capability-provided-now * ( 1 - system-state ^ ( 1 / 2 ) ) )
              set system-damage-this-tick ( system-damage-now + system-damage-this-tick )
              set capability-call-counter ( capability-call-counter + 1 )
            ]
          ]
        ]
      ]
    ]
  ]
  [
    ; code to seek capability for those without links to built systems
    set capability-attained-now 0
  ]
end

to repair-built-systems
  let loop-limit 0
  let my-built-sys-network-size 0
  if my-built-sys-network != nobody [ set my-built-sys-network-size count my-built-sys-network ]
  while [ action-energy > 0 and loop-limit < my-built-sys-network-size ]
  [
    set loop-limit loop-limit + 1
    ifelse my-built-sys-network != nobody [
      let sys-maintain-contribution action-energy
      ; let built-sys-to-repair one-of my-built-sys-network
      ; let built-sys-to-repair min-one-of my-built-sys-network [ system-state ]
      let built-sys-to-repair min-one-of my-built-sys-network with [ system-recovery-this-tick < system-damage-this-tick + random-damage-this-tick ]
      [ ( - system-damage-this-tick + system-recovery-this-tick - random-damage-this-tick ) ]
      if built-sys-to-repair != nobody [
        ask built-sys-to-repair [
          if system-recovery-this-tick < system-damage-this-tick [
            set system-recovery-now precision ( sys-maintain-contribution * system-state ^ ( 1 / 2 ) ) 4
            set system-recovery-this-tick ( system-recovery-now + system-recovery-this-tick )
            set repair-call-counter repair-call-counter + 1
            ask myself [ set action-energy ( action-energy - sys-maintain-contribution ) ]
          ]
        ]
      ]
    ]
    [
      ; code for other action in case person is not (directly) linked to a built system
    ]
  ]
end

to help-my-network
   ifelse action-energy > 0 and my-network != nobody [
    let network-people-in-need my-network with [ avg-capability-attainment < capability-threshold-low ]
    if network-people-in-need != nobody [
      let num-network-people-in-need count network-people-in-need
      let user-potential access-potential-now
      let cap-helper self
      ; let loop-limit 0
      ; while [ action-energy > 0 and loop-limit <= num-network-people-in-need ]
      ; [
        ; set loop-limit loop-limit + 1
        ; let network-person-to-help min-one-of network-people-in-need [ avg-capability-attainment ]
        let network-person-to-help min-one-of network-people-in-need [ capability-attained-this-tick ]
        if network-person-to-help != nobody and [ capability-attained-this-tick ] of network-person-to-help < capability-threshold-low [
          let capability-help-sought ( [ capability-threshold-low ] of network-person-to-help - [ capability-attained-this-tick ] of network-person-to-help +
          precision random-float ( [ capability-threshold-high ] of network-person-to-help - [ capability-threshold-low ] of network-person-to-help ) 2 )
          ; print [ capability-attained-this-tick ] of network-person-to-help
          ; print capability-help-sought
          if my-built-sys-network != nobody [
            let built-sys-unit-for-help-call max-one-of my-built-sys-network with [ system-state >= built-sys-state-min ] [ system-state ]
            if built-sys-unit-for-help-call != nobody [
              ask built-sys-unit-for-help-call [
                ; if ( user-potential * system-state ^ ( 1 / 3 ) ) >= random-float 1 [
                if ( [ action-energy ] of myself * system-state ^ ( 1 / 2 ) ) >= random-float 1 [
                ; if ( user-potential * system-state ^ ( 1 / 2 ) ) >= random-float 1 [
                  ask network-person-to-help [
                    ; set capability-help-sought capability-threshold-high
                    ifelse [ action-energy ] of cap-helper >= capability-help-sought [
                      set capability-attained-now capability-help-sought
                      set capability-attained-this-tick ( capability-attained-now + capability-attained-this-tick )
                      set capability-help-received-this-tick ( capability-attained-now + capability-help-received-this-tick )
                      set help-call-counter help-call-counter + 1
                      ask cap-helper [ set action-energy ( action-energy - capability-help-sought ) ]
                    ]
                    [
                      set capability-attained-now [ action-energy ] of cap-helper
                      set capability-attained-this-tick ( capability-attained-now + capability-attained-this-tick )
                      set capability-help-received-this-tick ( capability-attained-now + capability-help-received-this-tick )
                      set help-call-counter help-call-counter + 1
                      ask cap-helper [ set action-energy 0 ]
                    ]
                  ]
                  set capability-provided-now [ capability-attained-now ] of network-person-to-help
                  set capability-provided-this-tick ( capability-provided-now + capability-provided-this-tick )
                  set capability-provided-total ( capability-provided-now + capability-provided-total )
                  set system-damage-now ( capability-provided-now * ( 1 - system-state ^ ( 1 / 2 ) ) )
                  set system-damage-this-tick ( system-damage-now + system-damage-this-tick )
                  set capability-call-counter ( capability-call-counter + 1 )
                ]
              ]
            ]
          ]
        ]
      ; ]
    ]
  ]
  [
    ; else condition
  ]
end

to transfer-access-potential
  ifelse my-network != nobody [
    let transfer-extent precision ( ( avg-access-potential-now + access-potential-now ) / 2 ) 2
    ; let network-person-to-share-with min-one-of my-network with [ avg-capability-attainment < capability-threshold-low and access-potential-now < transfer-extent ]
    ; [ access-potential-now ] ; use my own threshold as reference
    let network-person-to-share-with min-one-of my-network with [ avg-capability-attainment < capability-threshold-low and access-potential-now < transfer-extent ]
    [ avg-capability-attainment ]
    if network-person-to-share-with != nobody [
      let my-avg-cap-attainment avg-capability-attainment
      let my-cap-threshold-low capability-threshold-low
      ask network-person-to-share-with [
        ; let share-scaling-factor capability-call-success-rate myself
        let share-scaling-factor mean capability-call-memory
        ; print share-scaling-factor
        let access-potential-half-difference ( [ access-potential-now ] of myself - access-potential-now ) / 2 ; share or transfer upto half the difference
        let access-potential-to-share 0
        ; ifelse my-avg-cap-attainment >= global-mean-capability-attainment [ set access-potential-to-share access-potential-half-difference ]
        ; [ set access-potential-to-share 0 ]
        ; ifelse my-avg-cap-attainment >= my-cap-threshold-low [ set access-potential-to-share access-potential-half-difference ]
        ifelse my-avg-cap-attainment >= my-cap-threshold-low [ set access-potential-to-share ( access-potential-half-difference * share-scaling-factor ) ]
        [ set access-potential-to-share 0 ]
        set access-potential-now ( access-potential-to-share + access-potential-now )
        set access-potential-received-this-tick ( access-potential-received-this-tick + access-potential-to-share )
        ask myself [
          set access-potential-now ( access-potential-now - access-potential-to-share )
          set access-potential-transferred-this-tick ( access-potential-transferred-this-tick + access-potential-to-share ) ; measure this and the call counter below only for
          set share-call-counter ( share-call-counter + 1 )
        ]
      ]
    ]
  ]
  [ ; else condition
  ]
end

to pool-access-potential
  set communal-pool-total ( access-potential-now + communal-pool-total )
  set communal-pool-now communal-pool-total
  set access-potential-now 0
  set pooled-access-potential? true
end

to draw-access-potential
  if communal-pool-now > 0 [
    let my-share-to-draw ( communal-pool-total / num-people )
    set access-potential-now my-share-to-draw
    set communal-pool-now ( communal-pool-now - my-share-to-draw )
    set access-potential-transferred-this-tick access-potential-initial-global-stdev
  ]
end

to record-max-and-min-indicator-values-this-run
  if global-mean-capability-attainment > max-global-mean-capability-attainment [ set max-global-mean-capability-attainment global-mean-capability-attainment ]
  if global-mean-capability-attainment < min-global-mean-capability-attainment [ set min-global-mean-capability-attainment global-mean-capability-attainment ]
  if avg-built-sys-state > max-global-mean-system-state [ set max-global-mean-system-state avg-built-sys-state ]
  if avg-built-sys-state < min-global-mean-system-state [ set min-global-mean-system-state avg-built-sys-state ]
end

to-report num-people
  report count people
end

to-report num-built-systems
  report count built-systems
end

to-report sum-access-potential
  report sum [ access-potential ] of people
end

to-report avg-network-size
  ifelse num-people = 0 [ report 0 ] [ report mean [ count my-network ] of people ]
end

to-report stdev-global-capability-attainment
  ifelse num-people < 2 [ report 0 ] [ report standard-deviation [ avg-capability-attainment ] of people ]
end

to-report global-mean-capability-attainment
  ifelse num-people = 0 [ report 0 ] [ report mean [ avg-capability-attainment ] of people ]
end

to-report global-mean-access-potential
  ifelse num-people = 0 [ report 0 ] [ report mean [ access-potential-now ] of people ]
end

to-report avg-action-energy
  ifelse num-people = 0 [ report 0 ] [ report mean [ action-energy ] of people ]
end

to-report total-people-to-sys-links
  report count people-to-sys-links
end

to-report total-people-to-people-links
  report count people-to-people-links
end

to-report avg-built-sys-links-per-person
  ifelse num-people = 0 [ report 0 ] [ report total-people-to-sys-links / num-people ]
end

to-report capability-acceptable-level-%
  ifelse num-people = 0 [ report 0 ] [ report ( count people with [ avg-capability-attainment < capability-threshold-low and avg-capability-attainment >= capability-min-limit] / num-people ) * 100 ]
end

to-report capability-good-level-%
  ifelse num-people = 0 [ report 0 ] [ report ( count people with [ avg-capability-attainment >= capability-threshold-low ] / num-people ) * 100 ]
end

to-report capability-unacceptable-level-%
  ifelse num-people = 0 [ report 0 ] [ report ( count people with [ avg-capability-attainment < capability-min-limit ] / num-people ) * 100 ]
end

to-report %-people-expired
  report ( num-people-expired / number-of-people ) * 100
end

to-report avg-built-sys-state
  ifelse num-built-systems = 0 [ report 0 ] [ report mean [ system-state ] of built-systems ]
end

to-report avg-capability-provided-this-tick
  ifelse num-built-systems = 0 [ report 0 ] [ report mean [ capability-provided-this-tick ] of built-systems ]
end

to-report avg-sys-damage-this-tick
  ifelse num-built-systems = 0 [ report 0 ] [ report mean [ system-damage-this-tick ] of built-systems ]
end

to-report avg-sys-recovery-this-tick
  ifelse num-built-systems = 0 [ report 0 ] [ report mean [ system-recovery-this-tick ] of built-systems ]
end

to-report avg-net-system-state-change-this-tick
  ifelse num-built-systems = 0 [ report 0 ] [ report mean [ net-system-state-change-this-tick ] of built-systems ]
end

to-report avg-random-damage-this-tick
  ifelse num-built-systems = 0 [ report 0 ] [ report mean [ random-damage-this-tick ] of built-systems ]
end

to-report total-system-damages-per-tick
  report sum [ system-damage-this-tick ] of built-systems
end

to-report total-system-recovery-per-tick
  report sum [ system-recovery-this-tick ] of built-systems
end

to-report total-capability-calls-this-tick
  report sum [ capability-call-counter ] of built-systems
end

to-report total-repair-calls-this-tick
  report sum [ repair-call-counter ] of built-systems
end

to-report total-capability-help-calls-this-tick
  report sum [ help-call-counter ] of people
end

to-report total-share-calls-this-tick
  report sum [ share-call-counter ] of people
end

to-report avg-capability-help-this-tick
  ifelse num-people = 0 [ report 0 ] [ report mean [ capability-help-received-this-tick ] of people ]
end

to-report %-built-systems-above-limit
  report count built-systems with [ system-state >= built-sys-operation-threshold ] / num-built-systems
end

to-report %-built-systems-below-limit
  report count built-systems with [ system-state < built-sys-operation-threshold ] / num-built-systems
end

to-report sum-access-potential-now
  report sum [ access-potential-now ] of people
end

to-report sum-access-potential-transferred-this-tick
  report sum [ access-potential-transferred-this-tick ] of people
end

to-report sum-access-potential-received-this-tick
  report sum [ access-potential-received-this-tick ] of people
end

to-report avg-access-potential-now
  ifelse num-people = 0 [ report 0 ] [ report mean [ access-potential-now ] of people ]
end

to-report stdev-access-potential-now
  ifelse num-people < 2 [ report 0 ] [ report standard-deviation [ access-potential-now ] of people ]
end

to-report avg-access-potential-transferred-this-tick
  ifelse num-people = 0 [ report 0 ] [ report mean [ access-potential-transferred-this-tick ] of people ]
end

to-report avg-access-potential-received-this-tick
  ifelse num-people = 0 [ report 0 ] [ report mean [ access-potential-received-this-tick ] of people ]
end

to-report avg-damage-impact
  ifelse num-built-systems = 0 [ report 0 ] [ report mean [ damage-impact ] of built-systems ]
end

to-report avg-recovery-impact
  ifelse num-built-systems = 0 [ report 0 ] [ report mean [ recovery-impact ] of built-systems ]
end

to-report avg-random-damage-impact
  ifelse num-built-systems = 0 [ report 0 ] [ report mean [ random-damage-impact ] of built-systems ]
end

to-report avg-net-system-state-impact
  report ( - avg-damage-impact + avg-recovery-impact )
end

to-report variance-net-system-state-change
  report variance [ net-system-state-change-this-tick ] of built-systems
end

to-report stdev-built-sys-state
  report standard-deviation [ system-state ] of built-systems
end

to-report capability-call-success-rate [ who-this-is ]
  let successes [ capability-call-successes ] of who-this-is
  let failures [ capability-call-failures ] of who-this-is
  ifelse ( successes + failures ) = 0 [ report 0 ]
  [ report precision ( successes / ( successes + failures ) ) 2 ]
end

to-report model-run-duration
  report ticks
end
@#$#@#$#@
GRAPHICS-WINDOW
292
10
728
447
-1
-1
12.97
1
10
1
1
1
0
0
0
1
-16
16
-16
16
0
0
1
ticks
1.0

BUTTON
9
10
92
43
NIL
setup
NIL
1
T
OBSERVER
NIL
Q
NIL
NIL
1

BUTTON
104
10
187
43
tick
go
NIL
1
T
OBSERVER
NIL
A
NIL
NIL
1

BUTTON
199
10
282
43
go
go
T
1
T
OBSERVER
NIL
S
NIL
NIL
1

SWITCH
489
619
582
652
fix-seed?
fix-seed?
1
1
-1000

SLIDER
9
136
165
169
min-access-potential
min-access-potential
0
1
0.0
0.01
1
NIL
HORIZONTAL

MONITOR
737
10
831
55
total-access-pot.
sum-access-potential
2
1
11

MONITOR
737
66
831
111
avg-network-size
avg-network-size
1
1
11

SLIDER
172
381
283
414
capability-low
capability-low
0
1
0.5
0.01
1
NIL
HORIZONTAL

SLIDER
172
424
283
457
capability-high
capability-high
capability-low
1
0.75
0.01
1
NIL
HORIZONTAL

SLIDER
594
457
729
490
built-sys-operation-threshold
built-sys-operation-threshold
0
1
0.2
0.01
1
NIL
HORIZONTAL

PLOT
839
10
1054
133
mean capability attainment & action energy
ticks
cap-units
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"global" 1.0 0 -16777216 true "" "plot global-mean-capability-attainment"
"enrgy/2" 1.0 2 -1184463 true "" "plot avg-action-energy / 2"
"sd-cap" 1.0 1 -11221820 true "" "plot stdev-global-capability-attainment"
"cap-aid" 1.0 2 -15302303 true "" "plot avg-capability-help-this-tick"
"acp-xfer" 1.0 2 -7773779 true "" "plot avg-access-potential-transferred-this-tick"
"pen-5" 1.0 0 -2064490 true "" "plot global-mean-cap-attnm-gradient"

MONITOR
737
121
831
166
avg-sys-links-pp
avg-built-sys-links-per-person
1
1
11

PLOT
839
141
1054
264
capability attainments
ticks
% people
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"good" 1.0 2 -2139308 true "" "plot capability-good-level-%"
"acceptable" 1.0 2 -10649926 true "" "plot capability-acceptable-level-%"
"unaccept." 1.0 2 -12895429 true "" "plot capability-unacceptable-level-%"
"exp." 1.0 2 -7500403 true "" "plot %-people-expired"

PLOT
840
273
1055
396
built systems activity
ticks
sys-units
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"damages" 1.0 1 -682149 true "" "plot avg-sys-damage-this-tick"
"repairs" 1.0 2 -6459832 true "" "plot avg-sys-recovery-this-tick"
"cap-outp" 1.0 2 -2139308 true "" "plot avg-capability-provided-this-tick"

PLOT
1061
10
1276
133
built systems state
ticks
sys-state
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"avg." 1.0 2 -4699768 true "" "plot avg-built-sys-state"
"> lim%" 1.0 2 -11221820 true "" "plot %-built-systems-above-limit"
"< lim%" 1.0 2 -12895429 true "" "plot %-built-systems-below-limit"
"sd" 1.0 2 -8630108 true "" "plot stdev-built-sys-state"
"acp-avg" 1.0 2 -11085214 true "" "plot avg-access-potential-now"
"pen-5" 1.0 2 -4079321 true "" "plot global-mean-sys-state-gradient"

PLOT
1061
141
1276
264
societal interactions
ticks
# of calls
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"cap-att" 1.0 2 -16777216 true "" "plot total-capability-calls-this-tick"
"repairs" 1.0 2 -6459832 true "" "plot total-repair-calls-this-tick"
"cap-aid" 1.0 2 -15302303 true "" "plot total-capability-help-calls-this-tick"
"acp-xfer" 1.0 2 -4539718 true "" "plot total-share-calls-this-tick"

PLOT
1062
273
1277
396
capability distribution
avg. capability attainment
# of people
0.0
1.0
0.0
10.0
true
false
"" ""
PENS
"default" 0.05 1 -16777216 true "" "histogram [ avg-capability-attainment ] of people"

SLIDER
172
466
283
499
capability-lim
capability-lim
0
capability-low
0.25
0.01
1
NIL
HORIZONTAL

PLOT
1283
141
1498
264
impact on system-state
ticks
sys-units
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"damage" 1.0 1 -10649926 true "" "plot avg-damage-impact"
"recovery" 1.0 2 -11085214 true "" "plot avg-recovery-impact"
"rand-dmg" 1.0 2 -1184463 true "" "plot avg-random-damage-impact"

SLIDER
9
220
165
253
repair-or-help-chance
repair-or-help-chance
0
100
100.0
1
1
%
HORIZONTAL

SLIDER
9
178
165
211
max-access-potential
max-access-potential
min-access-potential
1
1.0
0.01
1
NIL
HORIZONTAL

SLIDER
291
457
426
490
built-sys-state-min
built-sys-state-min
0
1
0.3
0.01
1
NIL
HORIZONTAL

SLIDER
442
457
577
490
built-sys-state-max
built-sys-state-max
built-sys-state-min
1
0.9
0.01
1
NIL
HORIZONTAL

PLOT
1283
10
1498
133
built sys. state distribution
system-state
# systems
0.0
1.0
0.0
10.0
true
false
"" ""
PENS
"default" 0.05 1 -4699768 true "" "histogram [ system-state ] of built-systems"

SLIDER
172
136
283
169
random-damage-limit
random-damage-limit
0
2
7.84
0.001
1
%
HORIZONTAL

MONITOR
737
176
831
221
help-calls-now
sum [help-call-counter] of people
0
1
11

CHOOSER
9
262
165
307
built-sys-capability-output
built-sys-capability-output
"capability-high" "capability-low < X < capability-high"
0

TEXTBOX
12
311
172
367
The capability amount a person may obtain, or consume, from a built system unit at each call.
11
0.0
1

TEXTBOX
173
215
288
376
Likelihood of a responsibility-ready person (one with a satisfactory capability attainment, higher than the capability-low threshold) choosing to repair built systems damages vs helping others attain the capability at each tick.
11
0.0
1

PLOT
1284
273
1499
396
access-potential distribution
access-potential
# of people
0.0
1.0
0.0
10.0
true
false
"" ""
PENS
"pen-0" 0.05 1 -15637942 true "" "histogram [ access-potential-now ] of people"

MONITOR
737
231
831
276
share-calls-now
total-share-calls-this-tick
0
1
11

TEXTBOX
1222
105
1280
123
(of people)
10
0.0
1

TEXTBOX
12
408
163
456
If on, people will seek to re-distribute some of their access-potential each tick.
11
0.0
1

TEXTBOX
172
173
295
215
Limit on random damage to built systems. 
11
0.0
1

TEXTBOX
12
453
167
562
Set capability thresholds and starting distribution with these three sliders. Capability-lim is the minimum tolerable capability for an individual, while capability-low is the threshold for capability attainment. 
11
0.0
1

TEXTBOX
173
88
289
130
Network-radius helps determine the extent of societal networks.
11
0.0
1

TEXTBOX
352
496
678
532
Set the starting system-state distribution for built-systems and their operational threshold here.
11
0.0
1

CHOOSER
292
531
475
576
set-social-capital-as
set-social-capital-as
"a function of access-potential" "independent of access-potential"
0

SLIDER
488
531
613
564
min-social-capital
min-social-capital
0
1
0.28
0.01
1
NIL
HORIZONTAL

SLIDER
488
575
613
608
max-social-capital
max-social-capital
min-social-capital
1
0.83
0.01
1
NIL
HORIZONTAL

PLOT
840
406
1055
529
sample capability attainments
ticks
cap-units
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"pen-0" 1.0 2 -7500403 true "" "ask sample-people \n [ create-temporary-plot-pen (word who)\n   set-plot-pen-color who\n   plotxy ticks avg-capability-attainment\n ]"

SLIDER
9
52
165
85
number-of-people
number-of-people
0
300
200.0
1
1
NIL
HORIZONTAL

SLIDER
9
94
165
127
number-of-built-systems
number-of-built-systems
1
number-of-people / 5
12.0
1
1
NIL
HORIZONTAL

SLIDER
172
52
283
85
network-radius
network-radius
1
100
45.0
1
1
%
HORIZONTAL

TEXTBOX
620
528
807
570
If you set social-capital to be an independent attribute, set its distribution here.
11
0.0
1

MONITOR
737
286
831
331
repair-calls-now
total-repair-calls-this-tick
0
1
11

SWITCH
292
586
411
619
people-expire?
people-expire?
1
1
-1000

TEXTBOX
293
623
443
679
If on, people with a capability attainment running average less than capability-lim will expire.
11
0.0
1

CHOOSER
9
557
244
602
seek-capability-when
seek-capability-when
"avg-capability-attainment < capability-low" "avg-capability-attainment < capability-high"
1

TEXTBOX
12
607
226
677
A person will try to call on a built system unit to attain the capability when their capability attainment running average goes below this threshold.
11
0.0
1

MONITOR
737
341
831
386
# of ticks
model-run-duration
0
1
11

MONITOR
737
396
831
441
NIL
run-seed
17
1
11

CHOOSER
10
358
166
403
share-access-potential
share-access-potential
"no" "yes, through personal transfers" "yes, through a community fund"
0

SWITCH
622
575
764
608
capability-call-help
capability-call-help
1
1
-1000

@#$#@#$#@
## THE RESOURCE-CAPABILITY SYSTEM AGENT-BASED MODEL

Please refer to the Overview, Design concepts, and Details (ODD) document provided at https://github.com/aashisjoshi/resource-capability-ABM

## CREDITS AND REFERENCES

Authors: Aashis Joshi (a.r.joshi@tudelft.nl)
Copyright: Aashis Joshi (2021)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/ or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

building institution
false
0
Rectangle -7500403 true true 0 60 300 270
Rectangle -16777216 true false 130 196 168 256
Rectangle -16777216 false false 0 255 300 270
Polygon -7500403 true true 0 60 150 15 300 60
Polygon -16777216 false false 0 60 150 15 300 60
Circle -1 true false 135 26 30
Circle -16777216 false false 135 25 30
Rectangle -16777216 false false 0 60 300 75
Rectangle -16777216 false false 218 75 255 90
Rectangle -16777216 false false 218 240 255 255
Rectangle -16777216 false false 224 90 249 240
Rectangle -16777216 false false 45 75 82 90
Rectangle -16777216 false false 45 240 82 255
Rectangle -16777216 false false 51 90 76 240
Rectangle -16777216 false false 90 240 127 255
Rectangle -16777216 false false 90 75 127 90
Rectangle -16777216 false false 96 90 121 240
Rectangle -16777216 false false 179 90 204 240
Rectangle -16777216 false false 173 75 210 90
Rectangle -16777216 false false 173 240 210 255
Rectangle -16777216 false false 269 90 294 240
Rectangle -16777216 false false 263 75 300 90
Rectangle -16777216 false false 263 240 300 255
Rectangle -16777216 false false 0 240 37 255
Rectangle -16777216 false false 6 90 31 240
Rectangle -16777216 false false 0 75 37 90
Line -16777216 false 112 260 184 260
Line -16777216 false 105 265 196 265

building store
false
0
Rectangle -7500403 true true 30 45 45 240
Rectangle -16777216 false false 30 45 45 165
Rectangle -7500403 true true 15 165 285 255
Rectangle -16777216 true false 120 195 180 255
Line -7500403 true 150 195 150 255
Rectangle -16777216 true false 30 180 105 240
Rectangle -16777216 true false 195 180 270 240
Line -16777216 false 0 165 300 165
Polygon -7500403 true true 0 165 45 135 60 90 240 90 255 135 300 165
Rectangle -7500403 true true 0 0 75 45
Rectangle -16777216 false false 0 0 75 45

bus
false
0
Polygon -7500403 true true 15 206 15 150 15 120 30 105 270 105 285 120 285 135 285 206 270 210 30 210
Rectangle -16777216 true false 36 126 231 159
Line -7500403 false 60 135 60 165
Line -7500403 false 60 120 60 165
Line -7500403 false 90 120 90 165
Line -7500403 false 120 120 120 165
Line -7500403 false 150 120 150 165
Line -7500403 false 180 120 180 165
Line -7500403 false 210 120 210 165
Line -7500403 false 240 135 240 165
Rectangle -16777216 true false 15 174 285 182
Circle -16777216 true false 48 187 42
Rectangle -16777216 true false 240 127 276 205
Circle -16777216 true false 195 187 42
Line -7500403 false 257 120 257 207

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

campsite
false
0
Polygon -7500403 true true 150 11 30 221 270 221
Polygon -16777216 true false 151 90 92 221 212 221
Line -7500403 true 150 30 150 225

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

chess rook
false
0
Rectangle -7500403 true true 90 255 210 300
Line -16777216 false 75 255 225 255
Rectangle -16777216 false false 90 255 210 300
Polygon -7500403 true true 90 255 105 105 195 105 210 255
Polygon -16777216 false false 90 255 105 105 195 105 210 255
Rectangle -7500403 true true 75 90 120 60
Rectangle -7500403 true true 75 84 225 105
Rectangle -7500403 true true 135 90 165 60
Rectangle -7500403 true true 180 90 225 60
Polygon -16777216 false false 90 105 75 105 75 60 120 60 120 84 135 84 135 60 165 60 165 84 179 84 180 60 225 60 225 105

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

factory
false
0
Rectangle -7500403 true true 76 194 285 270
Rectangle -7500403 true true 36 95 59 231
Rectangle -16777216 true false 90 210 270 240
Line -7500403 true 90 195 90 255
Line -7500403 true 120 195 120 255
Line -7500403 true 150 195 150 240
Line -7500403 true 180 195 180 255
Line -7500403 true 210 210 210 240
Line -7500403 true 240 210 240 240
Line -7500403 true 90 225 270 225
Circle -1 true false 37 73 32
Circle -1 true false 55 38 54
Circle -1 true false 96 21 42
Circle -1 true false 105 40 32
Circle -1 true false 129 19 42
Rectangle -7500403 true true 14 228 78 270

fire department
false
0
Polygon -7500403 true true 150 55 180 60 210 75 240 45 210 45 195 30 165 15 135 15 105 30 90 45 60 45 90 75 120 60
Polygon -7500403 true true 55 150 60 120 75 90 45 60 45 90 30 105 15 135 15 165 30 195 45 210 45 240 75 210 60 180
Polygon -7500403 true true 245 150 240 120 225 90 255 60 255 90 270 105 285 135 285 165 270 195 255 210 255 240 225 210 240 180
Polygon -7500403 true true 150 245 180 240 210 225 240 255 210 255 195 270 165 285 135 285 105 270 90 255 60 255 90 225 120 240
Circle -7500403 true true 60 60 180
Circle -16777216 false false 75 75 150

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

house efficiency
false
0
Rectangle -7500403 true true 180 90 195 195
Rectangle -7500403 true true 90 165 210 255
Rectangle -16777216 true false 165 195 195 255
Rectangle -16777216 true false 105 202 135 240
Polygon -7500403 true true 225 165 75 165 150 90
Line -16777216 false 75 165 225 165

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

molecule hydrogen
true
0
Circle -1 true false 138 108 84
Circle -16777216 false false 138 108 84
Circle -1 true false 78 108 84
Circle -16777216 false false 78 108 84

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

petals
false
0
Circle -7500403 true true 117 12 66
Circle -7500403 true true 116 221 67
Circle -7500403 true true 41 41 67
Circle -7500403 true true 11 116 67
Circle -7500403 true true 41 191 67
Circle -7500403 true true 191 191 67
Circle -7500403 true true 221 116 67
Circle -7500403 true true 191 41 67
Circle -7500403 true true 60 60 180

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

plant medium
false
0
Rectangle -7500403 true true 135 165 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 165 120 120 150 90 180 120 165 165

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

tank
true
0
Rectangle -7500403 true true 144 0 159 105
Rectangle -6459832 true false 195 45 255 255
Rectangle -16777216 false false 195 45 255 255
Rectangle -6459832 true false 45 45 105 255
Rectangle -16777216 false false 45 45 105 255
Line -16777216 false 45 75 255 75
Line -16777216 false 45 105 255 105
Line -16777216 false 45 60 255 60
Line -16777216 false 45 240 255 240
Line -16777216 false 45 225 255 225
Line -16777216 false 45 195 255 195
Line -16777216 false 45 150 255 150
Polygon -7500403 true true 90 60 60 90 60 240 120 255 180 255 240 240 240 90 210 60
Rectangle -16777216 false false 135 105 165 120
Polygon -16777216 false false 135 120 105 135 101 181 120 225 149 234 180 225 199 182 195 135 165 120
Polygon -16777216 false false 240 90 210 60 211 246 240 240
Polygon -16777216 false false 60 90 90 60 89 246 60 240
Polygon -16777216 false false 89 247 116 254 183 255 211 246 211 237 89 236
Rectangle -16777216 false false 90 60 210 90
Rectangle -16777216 false false 143 0 158 105

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tile log
false
0
Rectangle -7500403 true true 0 0 300 300
Line -16777216 false 0 30 45 15
Line -16777216 false 45 15 120 30
Line -16777216 false 120 30 180 45
Line -16777216 false 180 45 225 45
Line -16777216 false 225 45 165 60
Line -16777216 false 165 60 120 75
Line -16777216 false 120 75 30 60
Line -16777216 false 30 60 0 60
Line -16777216 false 300 30 270 45
Line -16777216 false 270 45 255 60
Line -16777216 false 255 60 300 60
Polygon -16777216 false false 15 120 90 90 136 95 210 75 270 90 300 120 270 150 195 165 150 150 60 150 30 135
Polygon -16777216 false false 63 134 166 135 230 142 270 120 210 105 116 120 88 122
Polygon -16777216 false false 22 45 84 53 144 49 50 31
Line -16777216 false 0 180 15 180
Line -16777216 false 15 180 105 195
Line -16777216 false 105 195 180 195
Line -16777216 false 225 210 165 225
Line -16777216 false 165 225 60 225
Line -16777216 false 60 225 0 210
Line -16777216 false 300 180 264 191
Line -16777216 false 255 225 300 210
Line -16777216 false 16 196 116 211
Line -16777216 false 180 300 105 285
Line -16777216 false 135 255 240 240
Line -16777216 false 240 240 300 255
Line -16777216 false 135 255 105 285
Line -16777216 false 180 0 240 15
Line -16777216 false 240 15 300 0
Line -16777216 false 0 300 45 285
Line -16777216 false 45 285 45 270
Line -16777216 false 45 270 0 255
Polygon -16777216 false false 150 270 225 300 300 285 228 264
Line -16777216 false 223 209 255 225
Line -16777216 false 179 196 227 183
Line -16777216 false 228 183 266 192

tile stones
false
0
Polygon -7500403 true true 0 240 45 195 75 180 90 165 90 135 45 120 0 135
Polygon -7500403 true true 300 240 285 210 270 180 270 150 300 135 300 225
Polygon -7500403 true true 225 300 240 270 270 255 285 255 300 285 300 300
Polygon -7500403 true true 0 285 30 300 0 300
Polygon -7500403 true true 225 0 210 15 210 30 255 60 285 45 300 30 300 0
Polygon -7500403 true true 0 30 30 0 0 0
Polygon -7500403 true true 15 30 75 0 180 0 195 30 225 60 210 90 135 60 45 60
Polygon -7500403 true true 0 105 30 105 75 120 105 105 90 75 45 75 0 60
Polygon -7500403 true true 300 60 240 75 255 105 285 120 300 105
Polygon -7500403 true true 120 75 120 105 105 135 105 165 165 150 240 150 255 135 240 105 210 105 180 90 150 75
Polygon -7500403 true true 75 300 135 285 195 300
Polygon -7500403 true true 30 285 75 285 120 270 150 270 150 210 90 195 60 210 15 255
Polygon -7500403 true true 180 285 240 255 255 225 255 195 240 165 195 165 150 165 135 195 165 210 165 255

train
false
0
Rectangle -7500403 true true 30 105 240 150
Polygon -7500403 true true 240 105 270 30 180 30 210 105
Polygon -7500403 true true 195 180 270 180 300 210 195 210
Circle -7500403 true true 0 165 90
Circle -7500403 true true 240 225 30
Circle -7500403 true true 90 165 90
Circle -7500403 true true 195 225 30
Rectangle -7500403 true true 0 30 105 150
Rectangle -16777216 true false 30 60 75 105
Polygon -7500403 true true 195 180 165 150 240 150 240 180
Rectangle -7500403 true true 135 75 165 105
Rectangle -7500403 true true 225 120 255 150
Rectangle -16777216 true false 30 203 150 218

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment-29July2021-3modes-higherRDs-help" repetitions="2000" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="3000"/>
    <metric>number-of-people</metric>
    <metric>number-of-built-systems</metric>
    <metric>max-access-potential</metric>
    <metric>min-access-potential</metric>
    <metric>built-sys-state-min</metric>
    <metric>built-sys-state-max</metric>
    <metric>random-damage-limit</metric>
    <metric>network-radius</metric>
    <metric>seek-capability-when</metric>
    <metric>share-access-potential</metric>
    <metric>capability-call-help</metric>
    <metric>capability-high</metric>
    <metric>capability-low</metric>
    <metric>capability-lim</metric>
    <metric>built-sys-capability-output</metric>
    <metric>built-sys-operation-threshold</metric>
    <metric>sum-access-potential</metric>
    <metric>avg-network-size</metric>
    <metric>avg-built-sys-links-per-person</metric>
    <metric>global-mean-capability-attainment</metric>
    <metric>stdev-global-capability-attainment</metric>
    <metric>capability-good-level-%</metric>
    <metric>capability-acceptable-level-%</metric>
    <metric>capability-unacceptable-level-%</metric>
    <metric>avg-built-sys-state</metric>
    <metric>stdev-built-sys-state</metric>
    <metric>aggr-system-damages</metric>
    <metric>aggr-system-recoveries</metric>
    <metric>aggr-capability-provided</metric>
    <metric>aggr-capability-help</metric>
    <metric>aggr-access-potential-transferred</metric>
    <metric>access-potential-initial-global-mean</metric>
    <metric>access-potential-initial-global-stdev</metric>
    <metric>max-global-mean-capability-attainment</metric>
    <metric>min-global-mean-capability-attainment</metric>
    <metric>max-global-mean-system-state</metric>
    <metric>min-global-mean-system-state</metric>
    <metric>access-potential-final-global-mean</metric>
    <metric>access-potential-final-global-stdev</metric>
  </experiment>
  <experiment name="experiment-25Sept2021" repetitions="1000" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="3000"/>
    <metric>number-of-people</metric>
    <metric>number-of-built-systems</metric>
    <metric>max-access-potential</metric>
    <metric>min-access-potential</metric>
    <metric>built-sys-state-min</metric>
    <metric>built-sys-state-max</metric>
    <metric>random-damage-limit</metric>
    <metric>network-radius</metric>
    <metric>seek-capability-when</metric>
    <metric>share-access-potential</metric>
    <metric>capability-call-help</metric>
    <metric>capability-high</metric>
    <metric>capability-low</metric>
    <metric>capability-lim</metric>
    <metric>built-sys-capability-output</metric>
    <metric>built-sys-operation-threshold</metric>
    <metric>sum-access-potential</metric>
    <metric>avg-network-size</metric>
    <metric>avg-built-sys-links-per-person</metric>
    <metric>global-mean-capability-attainment</metric>
    <metric>stdev-global-capability-attainment</metric>
    <metric>capability-good-level-%</metric>
    <metric>capability-acceptable-level-%</metric>
    <metric>capability-unacceptable-level-%</metric>
    <metric>avg-built-sys-state</metric>
    <metric>stdev-built-sys-state</metric>
    <metric>aggr-system-damages</metric>
    <metric>aggr-system-recoveries</metric>
    <metric>aggr-capability-provided</metric>
    <metric>aggr-capability-help</metric>
    <metric>aggr-access-potential-transferred</metric>
    <metric>access-potential-initial-global-mean</metric>
    <metric>access-potential-initial-global-stdev</metric>
    <metric>max-global-mean-capability-attainment</metric>
    <metric>min-global-mean-capability-attainment</metric>
    <metric>max-global-mean-system-state</metric>
    <metric>min-global-mean-system-state</metric>
    <metric>access-potential-final-global-mean</metric>
    <metric>access-potential-final-global-stdev</metric>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
