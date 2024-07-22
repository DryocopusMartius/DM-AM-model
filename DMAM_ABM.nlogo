; Author:   Tillman Reuter
; Date:     21.07.2024

;##############################################################################################

globals [
  initial-number-caves
  number-bwps
  number-target-patches
  cave-mortality
  caves-per-bwp
]

breed [bwps bwp]                                                                               ;Black Woodpecker pair (Dryocopus martius)
breed [hbs hb]                                                                                 ;Western Honey Bee swarm (Apis mellifera)
breed [hives hive]                                                                             ;Domesticated Honey Bee hive
breed [caves cave]                                                                             ;Tree cavity produced by Black Woodpecker

breed [dates date]                                                                             ;helper breed to create date display in upper right

patches-own [forest? target?]                                                                  ;all variables that end with ? are of data type boolean

bwps-own [target]
hbs-own [pot-homes target parent]
hives-own [free? grade mortality-rate]
caves-own [free? grade mortality-rate age]


;##############################################################################################

;##############################################################################################
;## SETUP ## SETUP ## SETUP ## SETUP ## SETUP ## SETUP ## SETUP ## SETUP ## SETUP ## SETUP ####
;##############################################################################################

;##############################################################################################

to setup                                                                                       ;main setup
  clear-all
  setup-grid
  setup-bwps
  setup-hives
  setup-caves
  setup-date
  reset-ticks
end

;##############################################################################################

to setup-grid
  ask patches [
    set pcolor 48                                                                              ;first, make everything non-forest land
    set forest? false
  ]
  ask patches with [(pycor <= 15 AND pycor >= -15) AND (pxcor <= 15 AND pxcor >= -15)] [        ;patches inside square a=31, patches are turned to forest
    set pcolor 56
    set forest? true
  ]
end

;##############################################################################################

to setup-bwps
  set number-bwps round (bwp-density * 9.61)                                                   ;computing integer of bwp pairs using forest area
  create-bwps number-bwps [                                                                    ;woodpeckers are initialized to be located in the forest
    set shape "dmam-bwp"
    set size 7
    set color black
    setxy random-float 30 - 15 random-float 30 - 15
  ]
end

;##############################################################################################

to setup-hives
  let target-patches patches with [forest? = false]                                            ;non-forest patches are selected as possible locations for hives
  ask n-of number-beekeepers patches with [not forest?] [set target? true]                     ;of those, x are the homes of the beekeepers
  ask patches with [target? = true] [
    ask patches in-radius 3 [set target? true]                                                 ;in a radius of 300m the beekeepers have their hives
  ]

  ask patches with [target? = true] [
    ask patches with [forest? = true] [                                                        ;the patches within 300m can't lie in the forest, and are therefore removed from the possible hive spots
      set target? false
    ]
  ]
  set number-target-patches count patches with [target? = true]                                ;helper variable to determine, how many of the possible spots are selected to sprout a hive

  ask patches with [target? = true] [
    if random 100 > (100 * number-hives / number-target-patches) [set target? false]           ;stochastic process to determine which of the possible spots sprout hives
  ]

  ask patches with [target? = true] [                                                          ;selected patches sprout 1 hive each
    sprout-hives 1 [
      set size 3
      set free? false
      set shape "dmam-hive-occupied"
      set grade 30
    ]
  ]
end

;##############################################################################################

to setup-caves
  set initial-number-caves round (number-bwps * 9.3 - number-bwps ^ 2 * 0.42)                                 ;the initial number of caves are calculated using parameters from a prior fitted
                                                                                                              ;quadratic linear model
  set cave-mortality (cave-prod-prob / initial-number-caves * number-bwps)                                    ;the cave-mortality is then directly coupled to the cave-prod-prob
                                                                                                              ;of a pair of Black Woodpeckers and the caves per woodpecker pair
  create-caves initial-number-caves [
    set shape "dmam-cave-free"
    set size 3
    setxy (random 30 - 15)                                                                     ;free caves are placed inside forest with a random age
          (random 30 - 15)
    set age random-exponential (1 / cave-mortality)                                            ;initial age distribution is set like it would emerge after long time
    set grade 35 * grade-misestimation                                                        ;because the grade is calculated later in the year, than it is needed,
    set free? true                                                                             ;it is set to the longterm average 35 for the first year
  ]
end

;##############################################################################################

to setup-date
  create-dates 1 [                                                                             ;date agent is placed in upper right; because sim starts with beginning of the year, first shape is January
    set size 5
    set color black
    set shape "m-jan"
    setxy 22 23
  ]
end

;##############################################################################################

;##############################################################################################
;## GO ## GO ## GO ## GO ## GO ## GO ## GO ## GO ## GO ## GO ## GO ## GO ## GO ## GO ## GO ####
;##############################################################################################

;##############################################################################################

to go                                                                                          ;main go
  proceed-date
  (ifelse
    ticks mod 12 = 0 [bee-mortality]                                                           ;January: bees die of freezing
    ticks mod 12 = 3 [produce-caves]                                                           ;April: Woodpeckers produce caves
    ticks mod 12 = 4 OR ticks mod 12 = 5 [swarm]                                               ;May and June: Honey bees swarm
    ticks mod 12 = 9 [weathering]                                                              ;October: Caves weather
    ticks mod 12 = 11 [destroy]                                                                ;December: Caves get destroyed during winter storms
  [ ])
  display-labels
  tick
  if ticks = 1199 [ask hives [die]]                                                            ;to check the main hypothesis (is honey bee pop viable), the hives are removed after 100 years
                                                                                               ;If pop is viable, it should hold without being fed with swarms from outside
  if count (turtle-set caves with [not free?] hives with [not free?]) = 0 [stop]               ;sim stops if no colonies are alive in either caves nor hives
end

;##############################################################################################

to proceed-date                                                                                ;every tick (month) the symbol in the upper right changes according to the month of the year
  ask dates [
    (ifelse
    ticks mod 12 = 0 [set shape "m-jan"]
    ticks mod 12 = 1 [set shape "m-feb"]
    ticks mod 12 = 2 [set shape "m-mar"]
    ticks mod 12 = 3 [set shape "m-apr"]
    ticks mod 12 = 4 [set shape "m-may"]
    ticks mod 12 = 5 [set shape "m-jun"]
    ticks mod 12 = 6 [set shape "m-jul"]
    ticks mod 12 = 7 [set shape "m-aug"]
    ticks mod 12 = 8 [set shape "m-sep"]
    ticks mod 12 = 9 [set shape "m-oct"]
    ticks mod 12 = 10 [set shape "m-nov"]
    ticks mod 12 = 11 [set shape "m-dec"]
    [ ])
  ]
end

;##############################################################################################

to bee-mortality
  ask hives with [not free?] [
    set mortality-rate (100 - grade)                                                           ;simple estimation is used to determine the mortality-rate
    if random 100 < mortality-rate [
      set free? true                                                                           ;hive parameters are changed to unoccupied
      set shape "dmam-hive-free"
    ]
  ]

  ask caves with [not free?] [
    set mortality-rate (100 - grade)
    if random 100 < mortality-rate [
      set free? true
      set shape "dmam-cave-free"
    ]
  ]
end

;##############################################################################################

to produce-caves
  ask bwps [
    set target one-of patches with [forest?]                                                   ;all woodpeckers move to a random forest patch
    face target
    move-to target
    if random (1 / cave-prod-prob) < 1 [                                                       ;with a specified probability, each pair produces a new empty cave with its base variables
      hatch-caves 1 [
        set shape "dmam-cave-free"
        set size 3
        set age 0
        set grade 50
        set free? true
      ]
    ]
  ]
end

;##############################################################################################

to swarm
  let index ticks mod 12 - 3                                                                   ;variable that determines if this is the first (May) or second (June) swarm of the year

  if index = 1 [
    ask hives with [free?] [                                                                   ;95% of hives, whose colony died in winter get refilled by beekeepers using a freshly fertilized queen
      if random 100 < 95 [
        set free? false
        set shape "dmam-hive-occupied"
      ]
    ]
  ]

  ask (turtle-set caves with [not free?] hives with [not free?]) [                             ;all occupied caves and trees have the probability to swarm based on their grade (half for June swarm)
    if random 100 < ( grade / index ) [
      hatch-hbs 1 [
        set shape "dmam-hb"
        set size 3
        set parent myself                                                                      ;the colony from which the swarm originates is noted as a variable for later needed returning of the swarm
        (ifelse member? myself caves [set color yellow] [set color black])                     ;swarms from caves get colored yellow, so their swarm line is drewn in yellow, for hives black
      ]
    ]
  ]

  repeat 3 [                                                                                    ;the following process is repeated 3 times, because swarms compete for new homes, and if two swarms want to
                                                                                                ;move into the same home, one can't and has to find itself another still available home
    ask hbs [
      set pot-homes (turtle-set hives caves) in-radius (max-swarming-distance / 100)            ;potential homes are ones, that are inside a circle of the maximum distance
      set pot-homes pot-homes with [distance myself > (min-swarming-distance / 100)]            ;and outside a circle of minimum distance
      set pot-homes pot-homes with [free?]                                                      ;pot homes have to still be available

      ifelse any? pot-homes [
        set target min-one-of pot-homes [abs (distance self - (prf-swarming-distance / 100))]   ;the one closest to the preferred swarming distance is selected as target
      ][
        set target nobody
      ]
    ]

    ask hbs [
      draw                                                                                      ;draw swarming lines if draw-swarming-lines is on
      if target != nobody [
        face target                                                                             ;swarms face their desired new home and move there
        fd distance target
      ]
      pen-up
    ]

    ask hives with [free?] [
      let candidates hbs in-radius 0.1                                                          ;all swarms located directly on top of a free home are selected to be candidates to move in
      let chosen1 one-of candidates                                                             ;one is randomly selected
      if any? candidates [
        set shape "dmam-hive-occupied"
        set free? false
        ask chosen1 [die]                                                                       ;because the swarm is now a colony in the home, the swarm dies
      ]
    ]

    ask caves with [free?] [
      let candidates hbs in-radius 0.1
      let chosen1 one-of candidates
      if any? candidates [
        set shape "dmam-cave-occupied"
        set free? false
        ask chosen1 [die]
      ]
    ]

    ask hbs [
      draw
      face parent                                                                              ;because in the next iteration of the loop, the selection of potential homes has to be repeated, the swarms
      fd distance parent                                                                       ;are moved back to their parent
      pen-up
    ]
  ]                                                                                            ;end of the repeat loop

  ask hbs [die]                                                                                ;all swarms, that haven't found a home die
end

;##############################################################################################

to draw
  if draw-swarming-lines? [                                                                    ;put pen down if switch is on
    pen-down
  ]
end

;##############################################################################################

to weathering
  ask caves [set age age + 1]                                                                  ;all caves age by 1 year
  ask caves with [age < 11] [set grade 40]
  ask caves with [age > 10 AND age < 21] [set grade age * 4]                                   ;nonlinear function, that holds the grade of a cave from age 0 to 10, increases it linearly until 20
  ask caves with [age > 20] [set grade 80]
  ask caves with [age > 30 AND age < 46] [set grade age * -4 + 200]                            ;holds it again until 30, and decreases it linearly again until 45
  ask caves [set grade grade * grade-misestimation]
end

;##############################################################################################

to destroy
  ask caves [
    if random (1 / cave-mortality) < 1 [die]                                                   ;every year, there is a 2% chance of dying for every cave
  ]
end

;##############################################################################################

to display-labels                                                                              ;was used to monitor variables for bugfixing
  ;ask caves [set label age]
end

;##############################################################################################
@#$#@#$#@
GRAPHICS-WINDOW
208
10
879
682
-1
-1
13.0
1
10
1
1
1
0
0
0
1
-25
25
-25
25
0
0
1
ticks
30.0

BUTTON
30
145
85
178
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
87
145
142
178
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
878
83
1246
233
Number of caves and occupied caves
Years since start of simulation
Count
0.0
100.0
0.0
0.0
true
true
"" ""
PENS
"occupied caves" 1.0 0 -1184463 true "" "if ticks mod 12 = 1 [plot count caves with [free? = false]]"
"all caves" 1.0 0 -14454117 true "" "if ticks mod 12 = 1 [plot count caves]"
"hives are removed" 1.0 1 -6759204 true "" "if ticks mod 12 = 0 [ifelse ticks = 1200 [plot initial-number-caves * 1.1] [plot 0]]"

SLIDER
28
357
199
390
number-hives
number-hives
1
60
46.0
1
1
NIL
HORIZONTAL

SLIDER
28
428
200
461
max-swarming-distance
max-swarming-distance
0
2000
2000.0
100
1
m
HORIZONTAL

TEXTBOX
1376
165
1580
374
worldsize = 5.1km * 5.1km = 26.01 km^2\narea forest = 3.1km * 3.1km = 9.61 km^2\narea not forest 16.4 km^2\npatchsize = 100m\n\ncave density ~ 1.7 - 5.4 /km^2 \n\t16 - 52 caves\nbwp density ~ 0.1 - 1.1 / km^2\n\t1 - 11 pairs\ncaves produced ~ 0.1 - 0.2 / a\n\nhive density in Germany 2.8 / km^2\n\t46 hives\nbeekeeper density in Germany 0.38 / km^2\n\t6 beekeepers
10
0.0
1

PLOT
878
232
1246
382
Ratio of caves occupied
Years since start of simulation
Ratio
0.0
100.0
0.0
1.0
true
true
"" ""
PENS
"occupied caves" 1.0 0 -16777216 true "" "if ticks mod 12 = 1 [plot count caves with [free? = false] / count caves]"
"total" 1.0 0 -7500403 true "" "if ticks mod 12 = 1 [plot 1]"
"hives are removed" 1.0 1 -6759204 true "" "if ticks mod 12 = 0 [ifelse ticks = 1200 [plot 1] [plot 0]]"

SLIDER
28
462
200
495
prf-swarming-distance
prf-swarming-distance
0
1200
450.0
50
1
m
HORIZONTAL

SLIDER
28
395
200
428
min-swarming-distance
min-swarming-distance
0
1000
200.0
50
1
m
HORIZONTAL

SLIDER
28
498
199
531
cave-prod-prob
cave-prod-prob
0.1
0.2
0.15
0.05
1
NIL
HORIZONTAL

BUTTON
145
145
200
178
NIL
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
954
52
1139
85
draw-swarming-lines?
draw-swarming-lines?
1
1
-1000

SLIDER
28
327
199
360
number-beekeepers
number-beekeepers
3
10
6.0
1
1
NIL
HORIZONTAL

TEXTBOX
1145
11
1254
90
If draw-swarming-lines is activated, every swarm attempt is drawn. Swarm attempts by swarms that originated from hives are drawn in black, those from caves in yellow.
8
0.0
1

TEXTBOX
26
10
198
72
DM-AM model
25
0.0
1

TEXTBOX
30
48
218
148
An Agent-Based Model to investigate the influence of the density of Dryocopus martius\non the viability of a population of Apis mellifera
13
0.0
1

MONITOR
28
277
200
322
Number of caves
count caves
17
1
11

MONITOR
28
530
200
575
NIL
cave-mortality
3
1
11

MONITOR
28
233
200
278
NIL
initial-number-caves
17
1
11

SLIDER
28
580
200
613
grade-misestimation
grade-misestimation
0.75
1.25
1.0
0.125
1
NIL
HORIZONTAL

MONITOR
954
12
1139
53
Feral HB population density [1/km^2]
count caves with [not free?] / 9.61
2
1
10

MONITOR
878
10
953
83
YEAR
(floor (ticks / 12) + 1)
17
1
18

SLIDER
28
190
121
223
bwp-density
bwp-density
0.1040583
1.1446413
0.6243498
0.1040583
1
/ km^2
HORIZONTAL

MONITOR
121
186
202
231
NIL
number-bwps
17
1
11

MONITOR
1163
164
1277
209
Years without hives
(floor (ticks / 12) + 1) - 100
0
1
11

@#$#@#$#@
# ODD-Protocol for the DM-AM model


## Purpose

The purpose of the DM-AM model is to determine the density of Black Woodpeckers that is necessary to supply enough caves for a population of feral Western Honey Bees to be viable in an average german forest.


## ENTITIES, STATE-VARIABLES, and SCALES

### Entities

- bwps: Pairs of Black Woodpeckers (Dryocopus martius L.)
- hbs: Swarms of Western Honey Bees (Apis mellifera L.)
- hives: Boxes, in which Honey Bee colonies are held domestically by beekeepers
- caves: Tree cavities built by bwps


### State-variables

#### bwps

- target: possible patches to fly to and potentially build next cave


#### hbs

- pot-homes: all unoccupied caves or hives, that are at least the minimum swarming distance and at most the maximum swarming distance away
- target: the 1 potential home, that lies closest to the preferred swarming distance
- parent: the hive or cave, the swarm originates from


#### hives

- free?: determines, if a hive is free or occupied
- grade: quality of the hive from a bee colonies perspective
- mortality-rate: probability of a colony to die (determined by grade)


#### caves

same as hives +

- age: time since the cave was produced (determines the grade)


### Scales

#### Temporal

- Grain: 1 month
- Extent: until Honey Bees have gone extinct


#### Spatial

- Grain: 1 ha (100 m * 100 m)
- Extent: 26 km^2 (5.1 km * 5.1 km)


## PROCESS OVERVIEW and SCHEDULING

Because processes happen in a yearly cycle, ticks are assigned months. Following this, processes happen only in specific months. The model starts with January (tick 0). Which agent sets are affected by which process is described in Chapter Sub-models.

- **January:** bee-mortality
- **April:** cave-producing
- **May:** swarm
- **June:** swarm
- **October:** weathering
- **December:** destroy

The simulation stops when the Honey Bee population has gone extinct.


## DESIGN CONCEPTS

### Basic Principles

The DM-AM model features essentially two relationships:

- The relationship of the Woodpecker density on the density of tree cavities
- The relationship of the density of tree cavities on the viability of the feral Honey Bee population.

Both relationships are coupled in this model through A -> B -> C.

The validity of the model depends on the hypothesis, that caves are at the moment the main limiting factor of feral Honey Bee viability. All other limiting factors like food resources and parasitic load (Varroa destructor) have therefore been neglected from the model. Both could later be implemented using a density regulation.


### Emergence
The results show that, as expected, with more Woodpeckers, more caves emerge, and therefore the Honey Bee population is more viable.

For the model results to be interpreted properly, a follow up population viability analysis (PVA) has to be done. The goal is to find the density of Woodpeckers, for which at least 95% of Honey Bee populations last for at least 100 years after all hives have been removed.

### Sensing
Sensing appears in the form of the swarms finding possible homes around them.
In reality, scouting bees would explore the surrounding and lead the swarm to the best fit based on a democratic process. This is modelled by assuming, the swarm senses all possible homes within the maximum swarming distance (and outside the minimum swarming distance).

### Interaction
Swarms interact only indirectly by competing for possible homes to move into. In denser areas, the competition is higher by logic, because multiple swarms select the same free homes and have the same ones close to their preferred distance.

### Stochasticity
The following processes are chosen randomly:

#### During initialisation
- Where woodpeckers and caves are placed (inside the forest)
- Where beekeepers are located (outside the forest)
- Which of their surrounding cells contain a hive
- The starting ages of caves

#### During simulation run
- Which one out of multiple candidates moves into a free home
- If a cave gets destroyed in December
- If a cave or hive releases a swarm

Except for the ages of initial caves, which are drawn from an exponential distribution, all random processes are drawn from the uniform distribution.

### Observation
- In the upper right corner of the arena and right next to it, there are a month and a year counter, to track when changes are happening. (Those counters are realized via a helper agent-set and and a common monitor respectively)
- Two plots are used to monitor the amount of caves in total and those who are occupied, and the ratio of occupied over all caves. In both, a vertical line is drawn at the moment when the hives are removed
- The shape of hives and caves is determined by their state of occupation (free?) and shows a big Honey Bee on top of it if occupied
- If a switch is activated, lines are drawn, were swarms fly. Swarms originating from hives draw black lines, from caves yellow lines

## INITIALIZATION

#### Patches
The forest is a square of side length 3.1km placed in the center of the arena. All area around the forest (ring of width 1km) is farmland / urban. This is realized using a boolean forest? and the patch color.

#### Parameters
The following parameters are needed for initialization:

- Density of woodpecker pairs
- Number of beekeepers (derived from average beekeeper density in Germany)
- Number of beehives (derived from average beehive density in Germany
- Minimum swarming distance
- Maximum swarming distance
- Preferred swarming distance (all derived from swarming preferences in Seeley & Morse, 1977 and Kohl & Rutschmann 2018)
- Probability of a woodpecker pair to produce a cave per year (Abs et al 1980)

###### Induced parameters
- Out of the density of woodpecker pairs, an absolute number is calculated using the area of the forest.

- The initial number of caves distributed in the forest is induced by the number of woodpeckers using the following quadratic equation:

> f(x) = -0.42x<sup>2</sup>+9.3x

- To guarantee, that the increment and the decay of caves are balanced out, the cave mortality is induced from the cave production probability per woodpecker pair, and the caves per woodpecker using the following equation:

> cave-mortality = (cave-prod-prob / initial-number-caves * number-bwps)


#### Patterns
- Woodpeckers and caves are placed in the forest
- Beekeepers and therefore the hives are placed in the farmland / urban area
- The hives are distributed as clusters of radius 300m around the beekeepers but strictly outside the forest


#### Distributions

The age distribution of caves follows the exponential distribution parameterized using the cave mortality)


## Submodels

#### bee-mortality
Honey Bee colonies die of harsh conditions with a probability determined by the grade of their hive or cave by the following equation:

> mortality-rate [%] = 100 - grade


#### cave-producing
All Woodpeckers fly to a random forest patch and with a specified probability (described in Initialisation) produce a new empty cave.

#### swarm
In May, the swarm procedure works as follows:
- 95% of hives whose colony has died in the most recent January get restocked with a new colony (common practice in bee-keeping).
- All caves and hives release a swarm with the probability [%] of their grade.
- Now all swarms look for possible free homes in a range of specified distances (described in Initialisation). They select the one possible free home that is closest to their preferred swarming distance and fly there. If only one swarm flew to this free home, it can move in. If multiple swarms candidate for this home, one gets chosen randomly to move in. All others return back to their origin for then possible free homes are recalculated and the next most preferred free home is flewn to. This process repeats 3 times. Swarms, that at this point still haven't found a home to move into, die.

In June, the swarm-procedure skips the first step. In the second step, the probability to release a swarm is halved. The rest is the same.

#### weathering
All caves age by 1 year. Using that age a grade is calculated following a below shown hump-shaped non-linear relationship.

![Example](file:Rplot4.png)

Hives don't weather and therefore keep a constant grade

#### destroy
With a probabity of `cave-mortality`, every cave gets destroyed during a winter storm. 

## Sources

- Kohl, P. L. and B. Rutschmann (2018). “The neglected bee trees: European beech forests as a home for feral honey bee colonies”. en. In: PeerJ 6. Publisher: PeerJ
- Seeley, T. D. and R. A. Morse (1977). “Dispersal Behavior of Honey Bee Swarms”. en.
In: Psyche: A Journal of Entomology 84. Publisher: Hindawi, pp. 199–209.



@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

dmam-bwp
true
0
Polygon -1 false false 0 120 45 120 120 135 90 135 120 120 120 75 135 75 120 105 135 45 150 105 135 75 150 75 150 120 180 135 150 135 225 120 270 120 240 135 270 135 240 150 255 150 270 165 240 165 255 180 225 180 240 195 180 210 150 195 150 255 135 270 120 255 120 195 90 210 30 195 45 180 15 180 30 165 0 165 15 150 30 150 0 135 30 135
Polygon -1 false false 0 120 45 120 120 135 90 135 120 120 120 75 135 75 120 105 135 45 150 105 135 75 150 75 150 120 180 135 150 135 225 120 270 120 240 135 270 135 240 150 255 150 270 165 240 165 255 180 225 180 240 195 180 210 150 195 150 255 135 270 120 255 120 195 90 210 30 195 45 180 15 180 30 165 0 165 15 150 30 150 0 135 30 135
Polygon -7500403 true true 120 75 150 75 150 135 120 135
Polygon -1 true false 120 90 150 90 135 105
Polygon -7500403 true true 135 45 150 105 135 75 150 75 150 120 150 120 180 135 180 135 150 135 225 120 270 120 240 135 270 135 240 150 255 150 270 165 240 165 255 180 225 180 240 195 180 210 150 195 150 195 150 255 135 270 120 255 120 195 120 195 90 210 30 195 45 180 15 180 30 165 0 165 15 150 30 150 0 135 30 135 0 120 45 120 120 135 90 135 120 120 120 120 120 90 120 75 135 75 120 105 135 45 135 45
Polygon -2674135 true false 135 75 120 105 135 120 135 120 150 105
Polygon -7500403 true true 45 120 120 135 150 135 225 120 225 150 45 150
Polygon -7500403 true true 150 90 180 90 180 150 150 150
Polygon -1 true false 150 105 180 105 165 120
Polygon -1 false false 30 135 75 135 150 150 120 150 150 135 150 90 165 90 150 120 165 60 180 120 165 90 180 90 180 135 210 150 180 150 255 135 300 135 270 150 300 150 270 165 285 165 300 180 270 180 285 195 255 195 270 210 210 225 180 210 180 270 165 285 150 270 150 210 120 225 60 210 75 195 45 195 60 180 30 180 45 165 60 165 30 150 60 150
Polygon -7500403 true true 165 60 180 120 165 90 180 90 180 135 180 135 210 150 210 150 180 150 255 135 300 135 270 150 300 150 270 165 285 165 300 180 270 180 285 195 255 195 270 210 210 225 180 210 180 210 180 270 165 285 150 270 150 210 150 210 120 225 60 210 75 195 45 195 60 180 30 180 45 165 60 165 30 150 60 150 30 135 75 135 150 150 120 150 150 135 150 135 150 105 150 90 165 90 150 120 165 60 165 60
Polygon -7500403 true true 75 135 150 150 180 150 255 135 255 165 75 165
Polygon -2674135 true false 165 90 150 120 165 135 165 135 180 120

dmam-cave-free
false
0
Polygon -6459832 true false 75 255 75 255 45 270 75 270 75 285 105 270 105 285 135 270 150 285 165 270 195 285 195 270 225 285 225 270 255 270 225 255 180 240 165 225 165 180 195 150 225 135 285 165 270 135 225 120 180 135 210 90 240 75 270 90 240 60 195 75 180 105 180 75 195 45 195 15 180 45 165 60 165 90 150 75 150 45 150 0 135 30 75 30 120 45 135 60 135 90 105 60 60 45 45 60 45 75 60 60 90 75 105 90 120 120 90 120 60 75 60 105 30 105 75 120 30 135 15 165 45 150 90 135 120 150 135 165 135 180 90 165 105 180 135 195 135 225 120 240
Polygon -16777216 true false 150 105 165 120 165 150 150 165 135 150 135 120
Polygon -16777216 false false 45 270 75 270 75 285 105 270 105 285 135 270 150 285 165 270 195 285 195 270 225 285 225 270 255 270 225 255 180 240 165 225 165 180 195 150 225 135 285 165 270 135 225 120 180 135 210 90 240 75 270 90 240 60 195 75 180 105 180 90 180 75 195 45 195 30 195 15 180 45 165 60 165 75 165 90 150 75 150 60 150 45 150 30 150 0 135 30 120 30 75 30 120 45 135 60 135 75 135 90 120 75 105 60 60 45 45 60 45 75 60 60 90 75 105 90 120 120 105 120 90 120 60 75 60 90 60 105 45 105 30 105 75 120 30 135 15 165 45 150 90 135 120 150 135 165 135 180 90 165 105 180 135 195 135 210 135 225 120 240 75 255
Polygon -10899396 true false 30 60 15 75 0 105 15 120 0 135 0 165 15 180 45 180 60 150 75 180 105 180 120 165 120 150 105 135 120 135 120 105 105 75 135 90 150 75 165 105 210 90 195 105 180 120 195 150 195 165 210 180 240 165 240 180 270 195 300 180 300 150 285 120 285 105 285 90 270 75 255 45 240 30 225 15 210 15 180 0 150 0 120 0 90 15 60 15 45 30 30 45
Polygon -16777216 false false 15 180 45 180 60 150 75 180 105 180 120 165 120 150 105 135 120 135 120 105 105 75 135 90 150 75 165 105 210 90 180 120 195 150 195 165 210 180 240 165 240 180 270 195 300 180 300 150 285 120 285 90 270 75 255 45 225 15 210 15 180 0 120 0 90 15 60 15 30 45 30 60 15 75 0 105 15 120 0 135 0 165

dmam-cave-occupied
false
0
Polygon -6459832 true false 75 255 75 255 45 270 75 270 75 285 105 270 105 285 135 270 150 285 165 270 195 285 195 270 225 285 225 270 255 270 225 255 180 240 165 225 165 180 195 150 225 135 285 165 270 135 225 120 180 135 210 90 240 75 270 90 240 60 195 75 180 105 180 75 195 45 195 15 180 45 165 60 165 90 150 75 150 45 150 0 135 30 75 30 120 45 135 60 135 90 105 60 60 45 45 60 45 75 60 60 90 75 105 90 120 120 90 120 60 75 60 105 30 105 75 120 30 135 15 165 45 150 90 135 120 150 135 165 135 180 90 165 105 180 135 195 135 225 120 240
Polygon -16777216 true false 150 105 165 120 165 150 150 165 135 150 135 120
Polygon -16777216 false false 45 270 75 270 75 285 105 270 105 285 135 270 150 285 165 270 195 285 195 270 225 285 225 270 255 270 225 255 180 240 165 225 165 180 195 150 225 135 285 165 270 135 225 120 180 135 210 90 240 75 270 90 240 60 195 75 180 105 180 90 180 75 195 45 195 30 195 15 180 45 165 60 165 75 165 90 150 75 150 60 150 45 150 30 150 0 135 30 120 30 75 30 120 45 135 60 135 75 135 90 120 75 105 60 60 45 45 60 45 75 60 60 90 75 105 90 120 120 105 120 90 120 60 75 60 90 60 105 45 105 30 105 75 120 30 135 15 165 45 150 90 135 120 150 135 165 135 180 90 165 105 180 135 195 135 210 135 225 120 240 75 255
Polygon -10899396 true false 30 60 15 75 0 105 15 120 0 135 0 165 15 180 45 180 60 150 75 180 105 180 120 165 120 150 105 135 120 135 120 105 105 75 135 90 150 75 165 105 210 90 195 105 180 120 195 150 195 165 210 180 240 165 240 180 270 195 300 180 300 150 285 120 285 105 285 90 270 75 255 45 240 30 225 15 210 15 180 0 150 0 120 0 90 15 60 15 45 30 30 45
Polygon -16777216 false false 15 180 45 180 60 150 75 180 105 180 120 165 120 150 105 135 120 135 120 105 105 75 135 90 150 75 165 105 210 90 180 120 195 150 195 165 210 180 240 165 240 180 270 195 300 180 300 150 285 120 285 90 270 75 255 45 225 15 210 15 180 0 120 0 90 15 60 15 30 45 30 60 15 75 0 105 15 120 0 135 0 165
Polygon -16777216 true false 150 75 195 105 195 105 195 105 195 195 195 195 150 210 150 210 105 195 105 105 105 105
Polygon -1184463 true false 105 105 195 105 195 150 105 150
Polygon -1184463 true false 105 195 195 195 150 225
Polygon -16777216 false false 105 105 105 195 150 225 195 195 195 105 150 75
Polygon -1 true false 195 120 240 165 210 210 195 135
Polygon -1 true false 105 120 60 165 90 210 105 135
Polygon -16777216 false false 105 120 60 165 90 210 105 135
Polygon -16777216 false false 195 120 240 165 210 210 195 135

dmam-hb
true
0
Polygon -1184463 true false 225 120 210 105 195 105 180 105 165 120 180 135 210 135 225 120
Polygon -1 true false 225 75 195 75 180 105 225 75
Polygon -1 true false 240 105 225 90 180 105
Polygon -1184463 true false 75 180 90 165 105 165 120 165 135 180 120 195 90 195 75 180
Polygon -16777216 true false 90 195 90 165 105 195 105 165 120 195
Polygon -1 true false 75 135 105 135 120 165 75 135
Polygon -1 true false 60 165 75 150 120 165
Polygon -1184463 true false 150 240 165 225 180 225 195 225 210 240 195 255 165 255 150 240
Polygon -16777216 true false 165 255 165 225 180 255 180 225 195 255
Polygon -1 true false 150 195 180 195 195 225 150 195
Polygon -1 true false 135 225 150 210 195 225
Polygon -1 true false 90 45 120 45 135 75 90 45
Polygon -1 true false 75 75 90 60 135 75
Polygon -1184463 true false 90 90 105 75 120 75 135 75 150 90 135 105 105 105 90 90
Polygon -16777216 true false 210 135 210 105 195 135 195 105 180 135
Polygon -16777216 true false 105 105 105 75 120 105 120 75 135 105
Polygon -1184463 true false 270 180 255 165 240 165 225 165 210 180 225 195 255 195 270 180
Polygon -1 true false 285 165 270 150 225 165
Polygon -1 true false 270 135 240 135 225 165 270 135
Polygon -16777216 true false 255 195 255 165 240 195 240 165 225 195

dmam-hive-free
false
10
Polygon -11221820 true false 150 285 285 225 285 75 150 135
Polygon -11221820 true false 15 75 15 225 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75
Line -16777216 false 150 285 150 135
Polygon -16777216 true false 165 255 270 210 270 195 165 240 165 240 165 255
Line -16777216 false 15 120 150 180
Line -16777216 false 285 120 150 180
Line -16777216 false 15 165 150 225
Line -16777216 false 285 165 150 225
Polygon -7500403 true false 285 75 285 75 285 75 150 15 15 75 0 90 135 150 165 150 300 90
Polygon -16777216 false false 0 90 135 150 165 150 300 90 285 75 150 15 15 75
Polygon -16777216 false false 15 75 150 135 135 150 150 135 165 150 150 135 285 75 150 135
Polygon -16777216 false false 15 105 15 225 150 285 285 225 285 105 285 120 150 180 15 120

dmam-hive-occupied
false
10
Polygon -11221820 true false 150 285 285 225 285 75 150 135
Polygon -11221820 true false 15 75 15 225 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75
Line -16777216 false 150 285 150 135
Polygon -16777216 true false 165 255 270 210 270 195 165 240 165 240 165 255
Line -16777216 false 15 120 150 180
Line -16777216 false 285 120 150 180
Line -16777216 false 15 165 150 225
Line -16777216 false 285 165 150 225
Polygon -7500403 true false 285 75 285 75 285 75 150 15 15 75 0 90 135 150 165 150 300 90
Polygon -16777216 false false 0 90 135 150 165 150 300 90 285 75 150 15 15 75
Polygon -16777216 false false 15 75 150 135 135 150 150 135 165 150 150 135 285 75 150 135
Polygon -1184463 true false 150 60 195 90 195 180 150 210 105 180 105 90
Polygon -16777216 true false 105 90 195 90 150 60
Polygon -16777216 true false 105 180 195 180 195 135 105 135
Polygon -1 true false 105 105 60 150 90 195 105 135
Polygon -1 true false 195 105 240 150 210 195 195 135
Polygon -16777216 false false 105 90 105 105 60 150 90 195 105 135 105 180 150 210 195 180 195 135 210 195 240 150 195 105 195 90 150 60
Polygon -16777216 false false 15 105 15 225 150 285 285 225 285 105 285 225 150 285 15 225

m-apr
false
0
Polygon -7500403 true true 195 210 195 60 240 60 255 75 210 75 210 105 240 105 240 75 255 75 255 105 240 120 255 135 255 210 240 210 240 135 210 135 210 210
Polygon -7500403 true true 45 210 45 75 60 60 90 60 105 75 60 75 60 120 90 120 90 75 105 75 105 210 90 210 90 135 60 135 60 210
Polygon -7500403 true true 120 210 120 60 165 60 180 75 135 75 135 120 165 120 165 75 180 75 180 120 165 135 135 135 135 210

m-aug
false
0
Polygon -7500403 true true 45 210 45 75 60 60 90 60 105 75 60 75 60 120 90 120 90 75 105 75 105 210 90 210 90 135 60 135 60 210
Polygon -7500403 true true 120 60 120 195 135 210 165 210 180 195 180 60 165 60 165 195 135 195 135 60
Polygon -7500403 true true 240 90 255 90 255 75 240 60 210 60 195 75 195 195 210 210 240 210 255 195 255 120 225 120 225 135 240 135 240 195 210 195 210 75 240 75

m-dec
false
0
Polygon -7500403 true true 120 60 120 210 180 210 180 195 135 195 135 135 165 135 165 120 135 120 135 75 180 75 180 60
Polygon -7500403 true true 45 60 90 60 105 75 105 195 90 210 45 210 45 75 90 75 90 195 60 195 60 75 45 75
Polygon -7500403 true true 255 90 255 75 240 60 210 60 195 75 195 195 210 210 240 210 255 195 255 180 240 180 240 195 210 195 210 75 240 75 240 90

m-feb
false
0
Polygon -7500403 true true 45 210 45 60 105 60 105 75 60 75 60 120 90 120 90 135 60 135 60 210
Polygon -7500403 true true 120 210 120 60 180 60 180 75 135 75 135 120 165 120 165 135 135 135 135 195 180 195 180 210
Polygon -7500403 true true 195 60 195 210 240 210 255 195 255 135 255 135 210 135 210 195 240 195 240 135 255 135 255 135 240 120 255 105 210 105 210 75 240 75 240 105 255 105 255 75 240 60

m-jan
false
0
Polygon -7500403 true true 45 60 105 60 105 195 90 210 60 210 45 195 45 180 60 180 60 195 90 195 90 75 45 75
Polygon -7500403 true true 195 210 195 60 225 60 240 195 240 60 255 60 255 210 225 210 210 75 210 210
Polygon -7500403 true true 120 210 120 75 135 60 150 60 165 60 180 75 180 105 165 105 165 75 135 75 135 120 165 120 165 105 180 105 180 210 165 210 165 135 135 135 135 210

m-jul
false
0
Polygon -7500403 true true 45 60 105 60 105 195 90 210 60 210 45 195 45 180 60 180 60 195 90 195 90 75 45 75
Polygon -7500403 true true 120 60 120 195 135 210 165 210 180 195 180 60 165 60 165 195 135 195 135 60
Polygon -7500403 true true 195 60 195 210 255 210 255 195 210 195 210 60 195 60

m-jun
false
0
Polygon -7500403 true true 45 60 105 60 105 195 90 210 60 210 45 195 45 180 60 180 60 195 90 195 90 75 45 75
Polygon -7500403 true true 195 210 195 60 225 60 240 195 240 60 255 60 255 210 225 210 210 75 210 210
Polygon -7500403 true true 120 60 120 195 135 210 165 210 180 195 180 60 165 60 165 195 135 195 135 60

m-mar
false
0
Polygon -7500403 true true 45 210 45 60 60 60 75 105 90 60 105 60 105 210 90 210 90 120 75 135 60 120 60 210 45 210
Polygon -7500403 true true 195 210 195 60 240 60 255 75 210 75 210 105 240 105 240 75 255 75 255 105 240 120 255 135 255 210 240 210 240 135 210 135 210 210
Polygon -7500403 true true 120 210 120 75 135 60 165 60 180 75 135 75 135 105 165 105 165 75 180 75 180 210 165 210 165 120 135 120 135 210

m-may
false
0
Polygon -7500403 true true 45 210 45 60 60 60 75 105 90 60 105 60 105 210 90 210 90 120 75 135 60 120 60 210 45 210
Polygon -7500403 true true 120 210 120 75 135 60 165 60 180 75 135 75 135 105 165 105 165 75 180 75 180 210 165 210 165 120 135 120 135 210
Polygon -7500403 true true 195 60 195 105 210 120 240 120 240 180 240 195 210 195 210 180 195 180 195 195 210 210 240 210 255 195 255 60 240 60 240 105 210 105 210 60

m-nov
false
0
Polygon -7500403 true true 45 210 45 60 75 60 90 195 90 60 105 60 105 210 75 210 60 75 60 210
Polygon -7500403 true true 135 60 120 75 165 75 165 195 135 195 135 75 120 75 120 195 135 210 165 210 180 195 180 75 165 60
Polygon -7500403 true true 195 60 195 165 210 210 240 210 255 165 255 60 240 60 240 150 225 195 210 150 210 60

m-oct
false
0
Polygon -7500403 true true 105 75 90 60 45 60 30 75 90 75 90 195 45 195 45 75 30 75 30 195 45 210 90 210 105 195
Polygon -7500403 true true 180 90 180 75 165 60 135 60 120 75 120 195 135 210 165 210 180 195 180 180 165 180 165 195 135 195 135 75 165 75 165 90
Polygon -7500403 true true 195 60 255 60 255 75 240 75 240 210 210 210 210 75 195 75

m-sep
false
0
Polygon -7500403 true true 195 210 195 60 240 60 255 75 210 75 210 120 240 120 240 75 255 75 255 120 240 135 210 135 210 210
Polygon -7500403 true true 120 60 120 210 180 210 180 195 135 195 135 135 165 135 165 120 135 120 135 75 180 75 180 60
Polygon -7500403 true true 105 90 105 75 90 60 60 60 45 75 45 120 60 135 90 135 90 195 60 195 60 180 45 180 45 195 60 210 90 210 105 195 105 135 90 120 60 120 60 75 90 75 90 90
@#$#@#$#@
NetLogo 6.3.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="20" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="7200"/>
    <metric>ticks</metric>
    <enumeratedValueSet variable="prf-swarming-distance">
      <value value="450"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-hives">
      <value value="46"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-swarming-distance">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-bwps">
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
      <value value="6"/>
      <value value="7"/>
      <value value="8"/>
      <value value="9"/>
      <value value="10"/>
      <value value="11"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="misestimation-factor">
      <value value="0.8"/>
      <value value="1"/>
      <value value="1.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-swarming-distance">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-beekeepers">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cave-prod-prob">
      <value value="0.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-swarming-lines?">
      <value value="false"/>
    </enumeratedValueSet>
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
