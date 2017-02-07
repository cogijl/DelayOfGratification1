;; TO DO
;; add cooperation and defection costs
;; add storage behaviors



globals [
  last_regrow
]


links-own[
  affect
]

patches-own[
  p_resources_init
  p_resources
]

turtles-own[
  my_resources
  stored_resources
  panic
]


to go
  if count turtles <= 1 [stop]
  spoil
  move
  panic_check
  extract_resources ;unfinished
  update_patch_color
  regrow
  death
  doplots
  tick
end

to setup
  ask patches [
    set p_resources_init random Max_Resources
    set p_resources p_resources_init
  ]
  ask n-of Population patches [
    sprout 1 [
      set color one-of base-colors
      set my_resources 10
      set panic "false"
      set stored_resources 0
    ]
  ]
  update_patch_color
  set last_regrow 0
  reset-ticks
end

to move
  ask turtles [
    ifelse panic = "true" [
      set heading towards one-of neighbors with-max [p_resources]
      forward jump_distance
      set my_resources my_resources - jump_distance
    ][
    set heading random 360
    forward jump_distance
    set my_resources my_resources - jump_distance
    ]
  ]
end

to spoil
  ask turtles[
    set stored_resources stored_resources * 1 + (Spoil_Rate / 100)
    if stored_resources >= Storage_Limit [
      set stored_resources Storage_Limit
    ]
  ]
end


to regrow
  ;; set itup so that patches periodically regrow new resources
  if (last_regrow + ticks)>= RegrowthRate [
    ask patches [
      set p_resources p_resources_init
    ]
  ]

end

to extract_resources
  ask patches with [count turtles-here <= 1][
    ask turtles-here[
      if (Future_Forcasting? = false) or (panic = "true") [
        set my_resources my_resources + [p_resources] of patch-here
        ask patch-here [
          set p_resources 0
        ]
      ]
      if Future_Forcasting? = true [
        let resources2extract ([p_resources] of patch-here * .15)
        set my_resources my_resources + resources2extract
        ask patch-here [
          set p_resources p_resources - resources2extract
        ]
        if panic = "false" [
          let storables (my_resources - threshold * 1.2)
          set my_resources my_resources - storables
          set stored_resources stored_resources + storables
        ]

        if panic = "true" [
          let use_stored []
          ifelse (stored_resources + my_resources) <= threshold [
            set use_stored stored_resources][
            set use_stored stored_resources * .25
            ]
            set my_resources my_resources + use_stored
        ]
      ]
      if (my_resources + stored_resources) >= threshold * 1.25[
        set panic "false"
      ]

      if my_resources >= Agent_CC [
        set my_resources Agent_CC
      ]
    ]
  ]
  ask patches with [count turtles-here >= 2][
    ask turtles-here[
      interact
    ]
  ]

end

to interact
  ;; if future discounting is on have them work together for longterm gain
  ;; if its off, have them work together for immeidate gain
  ;; if its is beneficial for them to work together, have them create a link.
  ;; if they are in panic mode, have them kill links
  let otheragent []
  let otherresources []
  let resources2take []
  let mynum self
  let mynum2 who
  if (Future_Forcasting? = false) or (panic = "true") [
    ifelse [p_resources] of patch-here >= 0 [
      set my_resources my_resources + [p_resources] of patch-here
      ask patch-here [
        set p_resources 0
      ]
    ][
    ask one-of other turtles-here [
      set otheragent myself
      create-link-from otheragent
      ]
    ask link otheragent mynum2 [
      set affect "Neg"
    ]
    ask turtle otheragent [
      set otherresources my_resources
      set resources2take (otherresources * .25)
      set my_resources (my_resources - resources2take)
    ]
    set my_resources (my_resources + resources2take)

    ; make negative link from him to self
    ; take their resources.

    ;; have them take all the resources here, or steal from the other agent
  ]
  ]
  if (Future_Forcasting? = true) and (panic = "false") [
    ;; have them work together for longterm gain
  ]


  ;;; I should try and find a way to add both within group conflict measures
  ;; and between group conflict measures.
end



to create_connection? [turtle_num]
  if cooperation_cost > defection_cost[
    create-link-to turtle_num
  ]
end


to-report cooperation_cost
  ;; calculate the cost/benefit of cooperating with the agent
end

to-report defection_cost
  ;; calculate the cost/benefit of defection with the agent

end






to update_patch_color
  ask patches [
    set pcolor scale-color green p_resources 0 Max_Resources
  ]
end



to death
  ask turtles[
    if my_resources <= 0[
      die
    ]
  ]
end





to delete_connection [turtle_num]
  ask link who turtle_num [
    die
  ]
end

to panic_check
  ask turtles[
    ifelse (my_resources + stored_resources) <= threshold[
      set panic "true"
    ][
    set panic "false"
    ]
  ]
end



to-report neighborcolors
  let n_color []
  ask neighbors [
    set n_color lput pcolor n_color
  ]
  report n_color
end

to-report average_resources
  let resourcepool []
  ask turtles [
    set resourcepool lput my_resources resourcepool
  ]
  ifelse empty? resourcepool[
    report 0][
    report mean resourcepool
    ]
end



to-report turtleresources
  let resourcevec []
  ask turtles[
    set resourcevec lput my_resources resourcevec
  ]
  report resourcevec
end

to-report pop_count
  report count turtles
end

to-report num_in_panic
  report count turtles with [panic = "True"]
end



to doplots
set-current-plot "Average Resources-Global"
set-current-plot-pen "default"
plot average_resources

set-current-plot "Count in Panic"
set-current-plot-pen "default"
plot count turtles with [panic = "true"]

set-current-plot "Resource Distribution"
set-current-plot-pen "default"
histogram turtleresources

set-current-plot "Count of Agents"
set-current-plot-pen "default"
plot count turtles

set-current-plot "Links by type"
set-current-plot-pen "Neg"
plot count links with [affect = "Neg"]
set-current-plot-pen "Pos"
plot count links with [affect = "Pos"]

end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
640
461
10
10
20.0
1
10
1
1
1
0
1
1
1
-10
10
-10
10
0
0
1
ticks
30.0

BUTTON
8
10
103
65
Setup
clear-all\nsetup
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
109
71
205
104
Go
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

BUTTON
107
11
207
64
Go Cont.
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

SLIDER
10
110
205
143
Population
Population
0
100
100
1
1
People
HORIZONTAL

BUTTON
9
70
103
103
Clear
clear-all
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
9
186
204
219
threshold
threshold
0
100
30
1
1
NIL
HORIZONTAL

SLIDER
10
245
206
278
jump_distance
jump_distance
1
10
1
1
1
squares
HORIZONTAL

PLOT
646
10
1078
230
Average Resources-Global
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" "plot average_resources"
PENS
"default" 1.0 0 -16777216 true "" "plot average_resources"

SWITCH
11
284
206
317
Future_Forcasting?
Future_Forcasting?
1
1
-1000

SLIDER
9
148
205
181
Max_Resources
Max_Resources
0
100
45
1
1
NIL
HORIZONTAL

PLOT
646
235
1078
461
Count in panic
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count turtles with [panic = \"True\"]"

PLOT
1084
10
1517
230
Resource Distribution
NIL
NIL
0.0
100.0
0.0
100.0
true
false
"" "histogram turtleresources"
PENS
"default" 1.0 1 -16777216 true "" "histogram turtleresources"

SLIDER
11
322
203
355
RegrowthRate
RegrowthRate
0
90
45
30
1
days
HORIZONTAL

PLOT
1085
236
1517
462
Count of Agents
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count turtles"

PLOT
647
466
1079
616
Links by type
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Neg" 1.0 0 -2674135 true "" "plot count turtles"
"Pos" 1.0 0 -13345367 true "" ""

SLIDER
12
404
184
437
Storage_Limit
Storage_Limit
0
100
75
1
1
Units
HORIZONTAL

SLIDER
12
444
185
477
Spoil_Rate
Spoil_Rate
0
100
25
.25
1
percent
HORIZONTAL

SLIDER
12
364
184
397
Agent_CC
Agent_CC
0
100
50
1
1
Units
HORIZONTAL

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
NetLogo 5.3
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment-test-1" repetitions="15" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1500"/>
    <exitCondition>count turtles &lt;= 1</exitCondition>
    <metric>pop_count</metric>
    <metric>num_in_panic</metric>
    <metric>average_resources</metric>
    <steppedValueSet variable="Population" first="25" step="25" last="100"/>
    <steppedValueSet variable="Spoil_Rate" first="5" step="5" last="25"/>
    <steppedValueSet variable="Agent_CC" first="10" step="10" last="50"/>
    <enumeratedValueSet variable="Future_Forcasting?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <steppedValueSet variable="Max_Resources" first="15" step="10" last="45"/>
    <steppedValueSet variable="threshold" first="10" step="10" last="30"/>
    <enumeratedValueSet variable="jump_distance">
      <value value="1"/>
      <value value="3"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RegrowthRate">
      <value value="45"/>
      <value value="90"/>
    </enumeratedValueSet>
    <steppedValueSet variable="Storage_Limit" first="25" step="25" last="100"/>
  </experiment>
  <experiment name="experiment-test-2-longevity" repetitions="15" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1500"/>
    <exitCondition>count turtles &lt;= 1</exitCondition>
    <metric>ticks</metric>
    <metric>pop_count</metric>
    <metric>num_in_panic</metric>
    <metric>average_resources</metric>
    <steppedValueSet variable="Population" first="25" step="25" last="100"/>
    <steppedValueSet variable="Spoil_Rate" first="5" step="5" last="25"/>
    <steppedValueSet variable="Agent_CC" first="10" step="10" last="50"/>
    <enumeratedValueSet variable="Future_Forcasting?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <steppedValueSet variable="Max_Resources" first="15" step="10" last="45"/>
    <steppedValueSet variable="threshold" first="10" step="10" last="30"/>
    <enumeratedValueSet variable="jump_distance">
      <value value="1"/>
      <value value="3"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RegrowthRate">
      <value value="45"/>
      <value value="90"/>
    </enumeratedValueSet>
    <steppedValueSet variable="Storage_Limit" first="25" step="25" last="100"/>
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
