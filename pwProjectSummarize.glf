package require PWI_Glyph

set pwFile [lindex $argv 0]

if { [string match "*.pw" $pwFile] } {
  puts "\tProject filename: $pwFile"
  pw::Application reset
  pw::Application load "$pwFile"

  set caeDim [pw::Application getCAESolverDimension]D

  # This isn't quite what I want, it reports the version of Pointwise that is
  # _running this script_, not the version that created the project.
  puts "\tVersion: [pw::Application getVersion]"
  set caeSolver [pw::Application getCAESolver]
  puts "\tCAE Solver: $caeSolver"
  puts "\tCAE Dimension: $caeDim"

  puts "\t***********************************"
  set all [pw::Grid getAll]
  if { $caeDim == "3D" } {
    set nBlocks [pw::Grid getCount -type pw::Block]
    puts "\tNumber of Blocks: $nBlocks"
  } elseif { $caeDim == "2D" } {
    set nDomains [pw::Grid getCount -type pw::Domain]
    puts "\tNumber of Domains: $nDomains"
  } else {
    puts "\tError: CAE Dimension is unsupported: \[$caeDim\]"
  }
  puts "\tNumber of Points: [pw::Grid getPointCount]"
  puts "\tNumber of Triangles: [pw::Grid getElementCount Triangle -skip3DCells]"
  puts "\tNumber of Quads: [pw::Grid getElementCount Quad -skip3DCells]"
  # This doesn't take into account points shared amongst multiple domains and
  # thus over counts the number of surface points.
  #puts "\tNumber of Surface Points: [pw::Grid getPointCount Domain]"
  puts "\tNumber of Surface Points: [pw::GridEntity getUniquePointCount -type pw::Domain]"
  puts "\tNumber of Tets: [pw::Grid getElementCount Tet]"
  puts "\tNumber of Pyramids: [pw::Grid getElementCount Pyramid]"
  puts "\tNumber of Prisms: [pw::Grid getElementCount Prism]"
  puts "\tNumber of Hexes: [pw::Grid getElementCount Hex]"
  #puts "\tpw::GridEntity.getElementCount: [$pw::GridEntity.getElementCount]"
  puts "\tDefault Decay Rate: [pw::GridEntity getDefault SizeFieldDecay]"

  set numSources [pw::Source getCount]
  if { $numSources > "0" } {
    puts "\n\tSource Information"
    puts "\tThere are $numSources sources"
    foreach s [pw::Source getAll] {
      set sourceName [$s getName]
      set sourceType [$s getSpecificationType]
      set sourceBeginSpacing [$s getBeginSpacing]
      set sourceBeginDecay [$s getBeginDecay]
      set sourceEndSpacing [$s getEndSpacing]
      set sourceEndDecay [$s getEndDecay]
      # TODO: I am not sure this handles all types of sources correctly.
      set sourceString "\tSource Name: $sourceName, Type: $sourceType, Begin Spacing: $sourceBeginSpacing, Begin Decay $sourceBeginDecay"
      if { $sourceType != "Constant" } { append sourceString " End Spacing: $sourceEndSpacing, End Decay $sourceEndDecay" }
      puts $sourceString
    }
  }

  puts "\n\tTrex Boundary Conditions"
  set trexConditions [pw::TRexCondition getNames]
  #puts "\ttrexConditions: $trexConditions"
  foreach t $trexConditions {
    set tBC [pw::TRexCondition getByName $t]
    # This doesn't work the way I want it to, it gets 'registers' which is not
    # a direct map to domains/connectors in the Trex BC.
    set tBcNumEntities [$tBC getRegisterCount -visibility true]
    if { $tBcNumEntities == "0" } {
      continue
    }
    set tBcName [$tBC getName]
    set tBcType [$tBC getConditionType]
    set tBcValue [$tBC getValue]
    set tBcAdapt [$tBC getAdaptation]
    puts "\tTrex Boundary Condition Name: $tBcName, Type: $tBcType, Value: $tBcValue, Adapt: $tBcAdapt"
  }

  puts "\n\t$caeSolver Boundary Conditions"
  set bcs [pw::BoundaryCondition getNames]
  puts "\tBCs: $bcs"
  foreach b $bcs {
    set bc [pw::BoundaryCondition getByName $b]
    set bcNumEnties [ $bc getEntityCount -visibility true ]
    if { $bcNumEnties == "0" } {
      continue
    }
    set bcName [$bc getName]
    set bcId [$bc getId]
    set bcPhisicalType [$bc getPhysicalType]

    puts "\tBoundary Name: $bcName, ID: $bcId, Type: $bcPhisicalType, Entity Count: $bcNumEnties"

    if { [ $bc getPhysicalType ] == "Unspecified" } {
      #puts "Skipping $bc"
      continue
    }

    #set bcScalarName [$bc getScalarNames]
    #puts "Scalar name: $bcScalarName"
    #set bcScalarValue [$bc getScalarValue $bcScalarName]
    #puts "$bc: \[$bcScalarName:$bcScalarValue\]"
  }
  #puts "\tBC Physical Types: [pw::BoundaryCondition getPhysicalTypes]"
  puts "\t***********************************"

} else {
  puts "ERROR: the first argument must be a Pointwise project file (ending in .pw)"
  exit
}

# vim: filetype=tcl
