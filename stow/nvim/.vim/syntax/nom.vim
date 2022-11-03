" Vim syntax file
" Language: JIPCAD (formerly NOM)
" Maintainer: Max Vogel <max-v@berkeley.edu>

"if exists("b:current_syntax")
"  finish
"endif


syn keyword nomTodo contained TODO FIXME XXX NOTE
syn match nomComment "#.*$" contains=nomTodo 
syn region nomComment start="[(][*]" end="[*][)]" keepend

syn keyword nomStructure set list face
syn keyword nomType rotate scale translate crotate ctranslate 
syn keyword nomDefine cutbegin cutend index  endpoint polyline endpolyline crosssection endcrosssection path endpath endsweep sweepmorph endsweepmorph morphvisualizer endmorphvisualizer endface controlpoint endcontrolpoint object endobject mesh endmesh group endgroup circle endcircle spiral endspiral sphere endsphere ellipsoid endellipsoid cylinder endcylinder hyperboloid endhyperboloid dupin enddupin mobiusstrip endmobiusstrip helix endhelix funnel endfunnel tunnel endtunnel torusknot endtorusknot torus endtorus gencartesiansurf endgencartesiansurf genparametricsurf endgenparametricsurf genimplicitsurf endgenimplicitsurf beziercurve endbeziercurve bspline endbspline instance endinstance endsurface frontcolor endfrontcolor backcolor endbackcolor endbackface begincap endcap window endwindow foreground endforeground insidefaces endinsidefaces outsidefaces endoutsidefaces offsetfaces endoffsetfaces frontfaces endfrontfaces backfaces endbackfaces rimfaces endrimfaces bank endbank delete enddelete subdivision endsubdivision sharp endsharp offset endoffset include endinclude light endlight camera endcamera viewport endviewport
syn match nomDefine "^point"
syn match nomDefine "^sweep" 
syn match nomDefine "^surface"
syn match nomKeyword "[^^]point"
syn match nomKeyword "[^^]sweep"
syn match nomKeyword "[^^]surface"
syn keyword nomKeyword closed sd_type sd_level offset_type height width hidden backface segs order type color projection cameraID frustum azimuth twist reverse mintorsion origin size background func funcX funcY funcZ botcap topcap  

syn keyword nomSpecial expr
syn keyword nomString $
syn keyword nomOperator + - / *


hi def link nomTodo             Todo
hi def link nomComment          Comment
hi def link nomKeyword          Keyword
hi def link nomType             Type
hi def link nomConstant         Constant
hi def link nomStatement        Statement
hi def link nomInclude          Include
hi def link nomConditional      Conditional
hi def link nomRepeat           Repeat
hi def link nomException        Exception
hi def link nomOperator         Operator
hi def link nomDefine           Define
hi def link nomFunction         Function
hi def link nomNormal           Normal
hi def link nomSpecial          Special
hi def link nomError            Error
hi def link nomString           String
hi def link nomFloat            Float
hi def link nomBoolean          Boolean
hi def link nomStructure        Structure

