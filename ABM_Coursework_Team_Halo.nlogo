;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Basic Network Settings;;
;;;;;;;;;;;;;;;;;;;;;;;;;;


;;Set the properties that each turtle has.
turtles-own
[
  infected?
  resistant?
  clarifier?
  ;;There are four types of people: the susceptible; the infected; the resistant
  ;;and the clarifier.
  rumor-check-timer
  ;;The rumor-check-timer is a timer, used in do-checks function.
]

to setup
  clear-all
  set-default-shape turtles "person"
  ;;After resetting, set the shape of each node to person.
  make-node nobody
  make-node turtle 0
  ;;Create two nodes, one of them has the nobody property
  ;;because there is no old node.
  reset-ticks
  ;;Reset the ticks.
end

to go
  ask links [ set color gray ]
  ;;Make the colour of old links become gray.
  make-node find-partner
  ;;Use the make-node and find-partner functions to add
  ;;a new node to an old one.
  if layout? [ layout ]
  ;;If the switch of "layout" is on, run the function"layout".
  tick
  ;;Tick + 1.
end

;;Define the make-node function
;;whose paremeter is an existing old node.
to make-node [old-node]
  create-turtles 1
  [
    set color blue
    set infected? false
    set resistant? false
    set clarifier? false
    ;;Create one new node which is a suscepetible person.
    set size 2
    ;;Its size is 2.
    if old-node != nobody
      [ create-link-with old-node [ set color green ]
        ;;The if statement is to set the link of each new node to green
        ;;in addition to the first node which do not have a link.
        move-to old-node
        fd 8
        ;;Locate the new node near its partner.
      ]
  ]
end

;;The more connected a node is, the more likely it is to receive new links.
;;It is the core of Preferential attachment.
to-report find-partner
  report [one-of both-ends] of one-of links
end

;;;;;;;;;;;;
;; Layout ;;
;;;;;;;;;;;;


;;The result is the laying out of the whole network in a way
;;which highlights relationships among the nodes
;;and at the same time is crowded less and is visually pleasing.
to layout
  repeat 3 [
  ;;The number 3 is a parameter. More repetitions slows down the
  ;;model, but too few gives poor layouts.
    let factor sqrt count turtles
    ;;Because the inputs of springs depends on the number of turtles,
    ;;account the factor first.
    layout-spring turtles links (1 / factor) (7 / factor) (1 / factor)
    ;;The three parameters of layout-spring are spring's constant; length and repulsion-constant.

    ;;spring-constant:the force the spring would exert if it's length were changed by 1 unit.

    ;;spring-length:the length which all springs try to achieve either.
    ;;by pushing out their nodes or pulling them in.

    ;;repulsion-constant:the force that 2 nodes at a distance of 1 unit will exert on each other.
    display
    ;;Causes the view to be updated immediately.
  ]
  ;;The model uses a bounded topology,
  ;;some additional layout code keeps the nodes from staying at the view boundaries.
  let x-offset max [xcor] of turtles + min [xcor] of turtles
  let y-offset max [ycor] of turtles + min [ycor] of turtles
  set x-offset limit-magnitude x-offset 0.1
  set y-offset limit-magnitude y-offset 0.1
  ;;Only adjust a little each time,  make display smoothly.
  ask turtles [ setxy (xcor - x-offset / 2) (ycor - y-offset / 2) ]
end

to-report limit-magnitude [number limit]
  ;;Two parameters: number; limit.
  if number > limit [ report limit ]
  if number < (- limit) [ report (- limit) ]
  report number
  ;;To keep x-offset and y-offset 0.
end

;;;;;;;;;;;;;;;;;;;;;;;;
;;Rumor model settings;;
;;;;;;;;;;;;;;;;;;;;;;;;

;;Define four types of people
to become-infected
  set infected? true
  set resistant? false
  set clarifier? false
  set color red
end

;;clarifiers are also the resistant. they are stronger.
to become-clarifier
  set infected? false
  set resistant? true
  set clarifier? true
  set color yellow
end

to become-susceptible
  set infected? false
  set resistant? false
  set clarifier? false
  set color blue
end

to become-resistant
  set infected? false
  set resistant? true
  set clarifier? false
  set color gray
end

;;Set up settings
to setup_rumors
  ask n-of initial-outbreak-size turtles
    [ become-infected ]
  ;;Make n of random turtles into rumour spreaders.
  reset-ticks
  clear-all-plots
  ;;Reset the ticks and plots to analyse better.
end

to setup_clarifiers
  ask n-of initial-clarifier-size turtles with [not infected?]
    [ become-clarifier ]
  ;;Make n of random turtles which is not infected into rumour spreaders.
  reset-ticks
  clear-all-plots
  ;;Reset the ticks and plots to analyse better.
end

;;Spread settings
to spread-rumors
  if all? turtles [not infected?]
    [ stop ]
  ;;Stop when there is no person infected.
  ask turtles
  [
     set rumor-check-timer rumor-check-timer + 1
     if rumor-check-timer >= check-frequency
       [ set rumor-check-timer 0 ]
  ]
  ;;Timer+1. When the number of timer reach to a certain number, set it zero.
  ;;To make a repetitive cycle.
  spread-rumor
  do-checks
  ;;Run these functions.
  tick
end

to spread-rumor
  ask turtles with [infected?]
  ;;Take the turtles which are infected.
    [ ask link-neighbors with [not resistant? and not clarifier? and not infected?]
    ;;Take all suspectible link-neighbors.
        [ if random-float 100 < rumor-spread-chance
            [ become-infected ] ] ]
        ;;They have a certain chance of transforming,
        ;;which is determined by rumor-spread-chance.
end

to spread-clarifiers
  if all? turtles [not infected?]
    [ stop ]
  ;;Stop when there is no person infected.
  ask turtles
  [
     set rumor-check-timer rumor-check-timer + 1
     if rumor-check-timer >= check-frequency
       [ set rumor-check-timer 0 ]
  ]
  ;;Timer+1. When the number of timer reach to a certain number, set it zero.
  ;;To make a repetitive cycle.
  spread-clarifier
  do-checks
  ;;Run these functions.
  tick
end

to spread-clarifier
  ask turtles with [clarifier?]
  ;;Take the turtles which are clarifiers.
    [ ask link-neighbors with [not resistant? and not clarifier?]
    ;;Take all suspectible and infected link-neighbors.
        [ if random-float 100 < clarifier-spread-chance
            [ become-resistant ] ] ]
        ;;They have a certain chance of transforming,
        ;;which is determined by clarifier-spread-chance.
end

to spread-super-clarifier
  ask turtles with [clarifier?]
  ;;Take the turtles which are clarifiers.
    [ ask link-neighbors with [not clarifier?]
    ;;Take all suspectible resistant and infected link-neighbors.
        [ if random-float 100 < super-clarifier-spread-chance
            [ become-clarifier ] ] ]
        ;;They have a certain chance of transforming,
        ;;which is determined by super-clarifier-spread-chance.
end

;;Spread clarifier and rumor together.
to spread-r-c-together
  if all? turtles [not infected?]
    [ stop ]
  ask turtles
  [
     set rumor-check-timer rumor-check-timer + 1
     if rumor-check-timer >= check-frequency
       [ set rumor-check-timer 0 ]
  ]
  spread-rumor
  spread-clarifier
  do-checks
  tick
end

;;Spread super-clarifier and rumor together.
to spread-r-sc-together
  if all? turtles [not infected?]
    [ stop ]
  ask turtles
  [
     set rumor-check-timer rumor-check-timer + 1
     if rumor-check-timer >= check-frequency
       [ set rumor-check-timer 0 ]
  ]
  spread-rumor
  spread-super-clarifier
  do-checks
  tick
end

;;This function is to determine if some of the susceptible people have the knowledge to immunity rumours
;;and become resistant from suspectible.
to do-checks
  ask turtles with [not infected? and not resistant? and not clarifier? and rumor-check-timer = 0]
  ;;Take the suspectible when their timers is zero.
  [
     if random 100 < gain-resistance-chance
      [ become-resistant ]
     ;;They have a certain chance of transforming, which is determined by gain-resistance-chance.
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;
;;Some useful functions;;
;;;;;;;;;;;;;;;;;;;;;;;;;


;; resize-nodes, change back and forth from size based on degree to a size of 2.
to resize-nodes
  ifelse all? turtles [size <= 2]
  [
    ask turtles [ set size sqrt count link-neighbors ]
    ;;using SQRT makes the person's area proportional to its degree.
  ]
  [
    ask turtles [ set size 2 ]
    ;;Return to original condition.

  ]
end

;;Make every turtle become susceptible.
to set-all-susceptible
  ask turtles [
    become-susceptible
  ]
end

;;Make every turtle which is infected become susceptible.
to remove-infected
    ask turtles with [color = red][
    become-susceptible
  ]
end

;;Used for Behaviourspace
to-report infected_n
  report count turtles with [color = red]
end

to-report clarifier_n
  report count turtles with [color = yellow]
end

to-report resistant_n
  report count turtles with [color = gray]
end

to-report susceptible_n
  report count turtles with [color = blue]
end


;;Button
;;Button go-thousand: repeat the function go 998 time to make 1000 nodes in the word

;;Monitors
;;Number of people: the number of nodes.
;;Number of clarifier: the number of nodes which are yellow.
;;Number of infected: the number of nodes which are red.
;;Number of resistant: the number of nodes which are gray.
;;Number of susceptible: the number of nodes which are blue.

;;Plots
;;The first:The DEGREE DISTRIBUTION plot shows the number of nodes with each degree value.
            ;;This is a power law distribution.
;;The second:The log plot of the first plot
;;The third: Number of four types of people

;;Switches
;;layout: whether run the layout function while going
;;plot: whether update the plots
@#$#@#$#@
GRAPHICS-WINDOW
674
25
1296
648
-1
-1
6.08
1
10
1
1
1
0
0
0
1
-50
50
-50
50
0
0
1
ticks
30.0

BUTTON
11
26
77
59
setup
setup\n
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
186
27
249
60
go
go\n
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
262
27
370
60
go-thousand
repeat 998 [ go ]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
13
553
121
586
redo layout
layout
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
140
553
254
586
resize nodes
resize-nodes
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SWITCH
1295
29
1398
62
plot?
plot?
0
1
-1000

SWITCH
275
553
381
586
layout?
layout?
0
1
-1000

BUTTON
11
114
125
147
setup-rumors
setup_rumors\n
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
286
114
407
147
spread-rumors
spread-rumors
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
11
158
206
191
initial-outbreak-size
initial-outbreak-size
0
50
15.0
1
1
NIL
HORIZONTAL

SLIDER
501
132
673
165
check-frequency
check-frequency
0
14
13.0
1
1
NIL
HORIZONTAL

SLIDER
214
158
409
191
rumor-spread-chance
rumor-spread-chance
0
100
10.0
1
1
%
HORIZONTAL

SLIDER
500
184
673
217
gain-resistance-chance
gain-resistance-chance
0
100
5.0
1
1
%
HORIZONTAL

BUTTON
158
594
321
627
set-all-susceptible
set-all-susceptible
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
13
593
148
626
remove-infected
remove-infected
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
12
282
214
315
initial-clarifier-size
initial-clarifier-size
0
100
5.0
1
1
NIL
HORIZONTAL

BUTTON
12
233
154
266
setup-clarifiers
setup_clarifiers
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
349
233
498
267
spread-clarifiers
spread-clarifiers
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

MONITOR
507
273
649
318
Number of people
count turtles
17
1
11

MONITOR
508
343
648
388
Number of clarifier
clarifier_n
17
1
11

MONITOR
507
412
646
457
Number of infected
infected_n
17
1
11

PLOT
1295
68
1576
253
Degree Distribution
Degree
Numer of nodes
1.0
100.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "if not plot? [ stop ]\nlet max-degree max [count link-neighbors] of turtles\nplot-pen-reset  ;; erase what we plotted before\nset-plot-x-range 1 (max-degree + 1)  ;; + 1 to make room for the width of the last bar\nhistogram [count link-neighbors] of turtles"

PLOT
1295
267
1577
438
Degree Distribution (log-log)
Log(degree)
Log(Number of nodes)
0.0
0.3
0.0
0.3
true
false
"" ""
PENS
"default" 1.0 2 -16777216 true "" "if not plot? [ stop ]\nlet max-degree max [count link-neighbors] of turtles\n;; for this plot, the axes are logarithmic, so we can't\n;; use \"histogram-from\"; we have to plot the points\n;; ourselves one at a time\nplot-pen-reset  ;; erase what we plotted before\n;; the way we create the network there is never a zero degree node,\n;; so start plotting at degree one\nlet degree 1\nwhile [degree <= max-degree] [\n  let matches turtles with [count link-neighbors = degree]\n  if any? matches\n    [ plotxy log degree 10\n             log (count matches) 10 ]\n  set degree degree + 1\n]"

BUTTON
127
114
283
147
spread-rumors-once
spread-rumors
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
159
233
343
266
spread-clarifiers-once
spread-clarifiers
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

MONITOR
506
478
646
523
Number of resistant
resistant_n
17
1
11

BUTTON
10
352
207
385
spread-r-c-together-once
spread-r-c-together
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
216
352
379
385
spread-r-c-together
spread-r-c-together
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
219
283
442
316
clarifier-spread-chance
clarifier-spread-chance
0
100
9.0
1
1
%
HORIZONTAL

BUTTON
12
431
230
464
spread-r-sc-together-once
spread-r-sc-together
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
237
431
421
464
spread-r-sc-together
spread-r-sc-together
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

PLOT
1296
449
1579
638
Network Status
time
% of nodes
0.0
52.0
0.0
100.0
true
true
"" ""
PENS
"Susceptible" 1.0 0 -13345367 true "" "if not plot? [ stop ]\nplot (count turtles with [not infected? and not resistant? and not clarifier?]) / (count turtles) * 100"
"Infected" 1.0 0 -2674135 true "" "if not plot? [ stop ]\nplot (count turtles with [infected?]) / (count turtles) * 100"
"Clarifier" 1.0 0 -1184463 true "" "if not plot? [ stop ]\nplot (count turtles with [clarifier?]) / (count turtles) * 100"
"Resistant" 1.0 0 -7500403 true "" "if not plot? [ stop ]\nplot (count turtles with [resistant? and not clarifier?]) / (count turtles) * 100"

SLIDER
12
473
283
506
super-clarifier-spread-chance
super-clarifier-spread-chance
0
50
1.5
0.5
1
%
HORIZONTAL

TEXTBOX
20
85
170
103
Add rumors
12
0.0
1

TEXTBOX
22
211
172
229
Add wisers
12
0.0
1

TEXTBOX
21
330
289
356
Spread rumors and common wisers together
12
0.0
1

TEXTBOX
20
401
355
427
Spread rumors, wisers, super wisers together
12
0.0
1

TEXTBOX
507
25
657
103
This is the slider of how often to determine if some of the susceptible people have the knowledge to immunity rumours
12
105.0
1

TEXTBOX
24
522
174
540
Some functions
12
0.0
1

TEXTBOX
511
242
661
260
Monitors
12
105.0
1

MONITOR
505
544
648
589
Number of susceptible
susceptible_n
17
1
11

BUTTON
92
27
172
60
go-once
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

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

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

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
NetLogo 6.2.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="rumor-spread-chance(1 3 31)(R)" repetitions="5" runMetricsEveryStep="true">
    <setup>setup
repeat 998 [ go ] 
setup_rumors</setup>
    <go>spread-rumors</go>
    <timeLimit steps="600"/>
    <exitCondition>not any? turtles with [color = blue]</exitCondition>
    <metric>infected_n</metric>
    <metric>clarifier_n</metric>
    <metric>resistant_n</metric>
    <metric>susceptible_n</metric>
    <enumeratedValueSet variable="initial-outbreak-size">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-clarifier-size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gain-resistance-chance">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="layout?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="super-clarifier-spread-chance">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="clarifier-spread-chance">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="plot?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="check-frequency">
      <value value="14"/>
    </enumeratedValueSet>
    <steppedValueSet variable="rumor-spread-chance" first="1" step="3" last="31"/>
  </experiment>
  <experiment name="gain-resistance-chance(1 2 21)(R)" repetitions="5" runMetricsEveryStep="true">
    <setup>setup
repeat 998 [ go ] 
setup_rumors</setup>
    <go>spread-rumors</go>
    <timeLimit steps="600"/>
    <exitCondition>not any? turtles with [color = blue]</exitCondition>
    <metric>infected_n</metric>
    <metric>clarifier_n</metric>
    <metric>resistant_n</metric>
    <metric>susceptible_n</metric>
    <enumeratedValueSet variable="initial-outbreak-size">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-clarifier-size">
      <value value="5"/>
    </enumeratedValueSet>
    <steppedValueSet variable="gain-resistance-chance" first="1" step="2" last="21"/>
    <enumeratedValueSet variable="layout?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="super-clarifier-spread-chance">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="clarifier-spread-chance">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="plot?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="check-frequency">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rumor-spread-chance">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="rumor-spread-chance(1 3 31)(C_R)" repetitions="5" runMetricsEveryStep="true">
    <setup>setup
repeat 998 [ go ] 
setup_rumors
setup_clarifiers</setup>
    <go>spread-r-c-together</go>
    <timeLimit steps="600"/>
    <exitCondition>not any? turtles with [color = blue]</exitCondition>
    <metric>infected_n</metric>
    <metric>clarifier_n</metric>
    <metric>resistant_n</metric>
    <metric>susceptible_n</metric>
    <enumeratedValueSet variable="initial-outbreak-size">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-clarifier-size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gain-resistance-chance">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="layout?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="super-clarifier-spread-chance">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="clarifier-spread-chance">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="plot?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="check-frequency">
      <value value="14"/>
    </enumeratedValueSet>
    <steppedValueSet variable="rumor-spread-chance" first="1" step="3" last="31"/>
  </experiment>
  <experiment name="clarifier-spread-chance(1 2 21)(C_R)" repetitions="5" runMetricsEveryStep="true">
    <setup>setup
repeat 998 [ go ] 
setup_rumors
setup_clarifiers</setup>
    <go>spread-r-c-together</go>
    <timeLimit steps="600"/>
    <exitCondition>not any? turtles with [color = blue]</exitCondition>
    <metric>infected_n</metric>
    <metric>clarifier_n</metric>
    <metric>resistant_n</metric>
    <metric>susceptible_n</metric>
    <enumeratedValueSet variable="initial-outbreak-size">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-clarifier-size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gain-resistance-chance">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="layout?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="super-clarifier-spread-chance">
      <value value="1.5"/>
    </enumeratedValueSet>
    <steppedValueSet variable="clarifier-spread-chance" first="1" step="2" last="21"/>
    <enumeratedValueSet variable="plot?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="check-frequency">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rumor-spread-chance">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="rumor-spread-chance(1 3 31)(SC_R)" repetitions="5" runMetricsEveryStep="true">
    <setup>setup
repeat 998 [ go ] 
setup_rumors
setup_clarifiers</setup>
    <go>spread-r-sc-together</go>
    <timeLimit steps="600"/>
    <exitCondition>not any? turtles with [color = blue]</exitCondition>
    <metric>infected_n</metric>
    <metric>clarifier_n</metric>
    <metric>resistant_n</metric>
    <metric>susceptible_n</metric>
    <enumeratedValueSet variable="initial-outbreak-size">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-clarifier-size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gain-resistance-chance">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="layout?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="super-clarifier-spread-chance">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="clarifier-spread-chance">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="plot?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="check-frequency">
      <value value="14"/>
    </enumeratedValueSet>
    <steppedValueSet variable="rumor-spread-chance" first="1" step="3" last="31"/>
  </experiment>
  <experiment name="super-clarifier-spread-chance(0.1 0.2 2.1)(SC_R)" repetitions="5" runMetricsEveryStep="true">
    <setup>setup
repeat 998 [ go ] 
setup_rumors
setup_clarifiers</setup>
    <go>spread-r-sc-together</go>
    <timeLimit steps="600"/>
    <exitCondition>not any? turtles with [color = blue]</exitCondition>
    <metric>infected_n</metric>
    <metric>clarifier_n</metric>
    <metric>resistant_n</metric>
    <metric>susceptible_n</metric>
    <enumeratedValueSet variable="initial-outbreak-size">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-clarifier-size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gain-resistance-chance">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="layout?">
      <value value="true"/>
    </enumeratedValueSet>
    <steppedValueSet variable="super-clarifier-spread-chance" first="0.1" step="0.2" last="2.1"/>
    <enumeratedValueSet variable="clarifier-spread-chance">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="plot?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="check-frequency">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rumor-spread-chance">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="gain-resistance-chance(1 2 21)(C_R)" repetitions="5" runMetricsEveryStep="true">
    <setup>setup
repeat 998 [ go ] 
setup_rumors
setup_clarifiers</setup>
    <go>spread-r-c-together</go>
    <timeLimit steps="600"/>
    <exitCondition>not any? turtles with [color = blue]</exitCondition>
    <metric>infected_n</metric>
    <metric>clarifier_n</metric>
    <metric>resistant_n</metric>
    <metric>susceptible_n</metric>
    <enumeratedValueSet variable="initial-outbreak-size">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-clarifier-size">
      <value value="5"/>
    </enumeratedValueSet>
    <steppedValueSet variable="gain-resistance-chance" first="1" step="2" last="21"/>
    <enumeratedValueSet variable="layout?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="super-clarifier-spread-chance">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="clarifier-spread-chance">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="plot?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="check-frequency">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rumor-spread-chance">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="check-frequency(1 2 15)(C_R)" repetitions="5" runMetricsEveryStep="true">
    <setup>setup
repeat 998 [ go ] 
setup_rumors
setup_clarifiers</setup>
    <go>spread-r-c-together</go>
    <timeLimit steps="600"/>
    <exitCondition>not any? turtles with [color = blue]</exitCondition>
    <metric>infected_n</metric>
    <metric>clarifier_n</metric>
    <metric>resistant_n</metric>
    <metric>susceptible_n</metric>
    <enumeratedValueSet variable="initial-outbreak-size">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-clarifier-size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gain-resistance-chance">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="layout?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="super-clarifier-spread-chance">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="clarifier-spread-chance">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="plot?">
      <value value="true"/>
    </enumeratedValueSet>
    <steppedValueSet variable="check-frequency" first="1" step="2" last="15"/>
    <enumeratedValueSet variable="rumor-spread-chance">
      <value value="10"/>
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
