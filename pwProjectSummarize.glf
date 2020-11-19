package require PWI_Glyph

set pwFile [lindex $argv 0]

if { [string match "*.pw" $pwFile] } {
  puts "\n\t***********************************"
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

  puts "\n\tDefaults"
  puts "\t-----------------------------------"
  puts "\tDecay Rate:                    [pw::GridEntity getDefault SizeFieldDecay]"
  puts "\tSize Field Background Spacing: [pw::GridEntity getDefault SizeFieldBackgroundSpacing]"
  puts "\tSize Field Calculation Method: [pw::GridEntity getDefault SizeFieldCalculationMethod]"
  puts "\tIsometric Cell Type:           [pw::DomainUnstructured getDefault IsoCellType]"
  puts "\tDomain Trex Cell Type:         [pw::DomainUnstructured getDefault TRexCellType]"
  puts "\tInterior Algorithm:            [pw::BlockUnstructured getDefault InteriorAlgorithm]"
  puts "\tBlock Trex Cell Type:          [pw::BlockUnstructured getDefault TRexCellType]"

  puts "\n\tElement Counts"
  puts "\t-----------------------------------"
  set all [pw::Grid getAll]
  if { $caeDim == "3D" } {
    set nBlocks [pw::Grid getCount -type pw::Block]
    puts "\tNumber of Blocks:         $nBlocks"
  } elseif { $caeDim == "2D" } {
    set nDomains [pw::Grid getCount -type pw::Domain]
    puts "\tNumber of Domains: $nDomains"
  } else {
    puts "\tError: CAE Dimension is unsupported: \[$caeDim\]"
  }
  puts "\tNumber of Points:         [pw::Grid getPointCount]"
  puts "\tNumber of Triangles:      [pw::Grid getElementCount Triangle -skip3DCells]"
  puts "\tNumber of Quads:          [pw::Grid getElementCount Quad -skip3DCells]"
  # This doesn't take into account points shared amongst multiple domains and
  # thus over counts the number of surface points.
  #puts "\tNumber of Surface Points: [pw::Grid getPointCount Domain]"
  puts "\tNumber of Surface Points: [pw::GridEntity getUniquePointCount -type pw::Domain]"
  puts "\tNumber of Tets:           [pw::Grid getElementCount Tet]"
  puts "\tNumber of Pyramids:       [pw::Grid getElementCount Pyramid]"
  puts "\tNumber of Prisms:         [pw::Grid getElementCount Prism]"
  puts "\tNumber of Hexes:          [pw::Grid getElementCount Hex]"
  #puts "\tpw::GridEntity.getElementCount: [$pw::GridEntity.getElementCount]"
  puts "\t-----------------------------------"

  puts "\n\tBlock Information"
  puts "\t-----------------------------------"
  foreach blk [pw::Grid getAll -type pw::Block] {
    set blkName [$blk getName]
    set blkType [$blk getType]
    set blkTypeStr ""
    if { $blkType == "pw::BlockStructured" } {
      set blkTypeStr "Structured"
    } elseif { $blkType == "pw::BlockExtruded" } {
      set blkTypeStr "Extruded"
    } elseif { $blkType == "pw::BlockUnstructured" } {
      set blkTypeStr "Unstructured"
    } else {
      set blkTypeStr "Nope"
    }
    puts "\tBlock:      $blkName"
    puts "\tBlock Type: $blkTypeStr"

    if { $blkTypeStr == "Unstructured" } {
      set blkAlgo [$blk getUnstructuredSolverAttribute InteriorAlgorithm]
      puts "\t\tInterior Algorithm: $blkAlgo"
      puts "\t\t==================================="
      # This is a bit kludge, but it is a way to only report these values if they
      # have been changed from the application default.
      set tmp [$blk getUnstructuredSolverAttribute EdgeMaximumLength]
      if { $tmp != "0.0" } { puts "\t\tMax Edge Length:         $tmp" }
      set tmp [$blk getUnstructuredSolverAttribute EdgeMinimumLength]
      if { $tmp != "0.0" } { puts "\t\tMin Edge Length:         $tmp" }
      set tmp [$blk getUnstructuredSolverAttribute PyramidMinimumHeight]
      if { $tmp != "0.0" } { puts "\t\tMin Pyramid Height:      $tmp" }
      set tmp [$blk getUnstructuredSolverAttribute PyramidMaximumHeight]
      if { $tmp != "0.0" } { puts "\t\tMax Pyramid Height:      $tmp" }
      puts "\t\tPyramid Aspect Ratio:    [$blk getUnstructuredSolverAttribute PyramidAspectRatio]"
      puts "\t\tBoundary Decay Rate:     [$blk getUnstructuredSolverAttribute BoundaryDecay]"

      if { $blkAlgo == "Voxel" } {
        puts "\t\tVoxel Min Edge:          [$blk getUnstructuredSolverAttribute VoxelMinimumSize] (Automatic: [$blk getAutomaticVoxelMinimumSize])"
        puts "\t\tVoxel Max Edge:          [$blk getUnstructuredSolverAttribute VoxelMaximumSize] (Automatic: [$blk getAutomaticVoxelMaximumSize])"
        puts "\t\tVoxel Transition Layers: [$blk getUnstructuredSolverAttribute VoxelTransitionLayers]"
        puts "\t\tVoxel Alignment:         [$blk getUnstructuredSolverAttribute VoxelAlignment]"
      } else {
        puts "\t\tError: Block Algortithm not known: \[$blkAlgo\]"
      }
      puts "\t\t==================================="

      if { [$blk getUnstructuredSolverAttribute TRexMaximumLayers] == "0" } {
        puts "\t\t$blk is not a Trex block..."
      } else {
        #puts "\tTrex Maximum Layers:   [$blk getUnstructuredSolverAttribute TRexMaximumLayers] ([$blk getUnstructuredSolverAttribute TRexFullLayers] full layers)"
        puts "\t\tTrex Maximum/Full Layers: [$blk getUnstructuredSolverAttribute TRexMaximumLayers]/[$blk getUnstructuredSolverAttribute TRexFullLayers]"
        puts "\t\tTrex Growth Rate:         [$blk getUnstructuredSolverAttribute TRexGrowthRate]"
        puts "\t\tTrex Push Attributes:     [$blk getUnstructuredSolverAttribute TRexPushAttributes]"
        puts "\t\tTrex Cell Types:          [$blk getUnstructuredSolverAttribute TRexCellType]"
        puts "\t\tTrex Collision Buffer:    [$blk getUnstructuredSolverAttribute TRexCollisionBuffer]"
        puts "\t\tTrex Isotropic Height:    [$blk getUnstructuredSolverAttribute TRexIsotropicHeight]"
      }

      # This is also kludgey, there seems to be no way, as of V18.4R2, to get
      # included sources or include sources via Glyph. So, I am doing it
      # backwards for now.
      #set blkSources [$blk getIncludedSources]
      #puts "\t$blkName contains [llength $blkSources] source entities"
      set excludedBlkSources [$blk getExcludedSources]
      if { [llength $excludedBlkSources] != "0" } {
        puts -nonewline "\t\t$blkName excludes [llength $excludedBlkSources] sources:"
        foreach s $excludedBlkSources {
          puts -nonewline " [$s getName]"
        }
        puts ""
      } else {
        puts "\t\t$blkName includes all sources"
      }
    } else {
      puts "\t\tBlock Dimensions: [$blk getDimensions]"
    }
  puts "\t-----------------------------------"
  }

  set numSources [pw::Source getCount]
  if { $numSources > "0" } {
    puts "\n\tSource Information"
    puts "\t-----------------------------------"
    puts "\tThere are $numSources sources"
    foreach s [pw::Source getAll] {
      set sourceName [$s getName]
      set sourceType [$s getSpecificationType]
      set sourceBeginSpacing [$s getBeginSpacing]
      set sourceBeginDecay [$s getBeginDecay]
      set sourceEndSpacing [$s getEndSpacing]
      set sourceEndDecay [$s getEndDecay]
      set sourceDescription [$s getDescription]
      # TODO: I am not sure this handles all types of sources correctly.
      set sourceString "\tSource Name: $sourceName, Description: $sourceDescription, Type: $sourceType, Begin Spacing: $sourceBeginSpacing, Begin Decay $sourceBeginDecay"
      if { $sourceType != "Constant" } { append sourceString " End Spacing: $sourceEndSpacing, End Decay $sourceEndDecay" }
      puts $sourceString
    }
  }
  puts "\t-----------------------------------"

  puts "\n\tTrex Boundary Conditions"
  puts "\t-----------------------------------"
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
  puts "\t-----------------------------------"

  puts "\n\t$caeSolver Boundary Conditions"
  puts "\t-----------------------------------"
  set bcs [pw::BoundaryCondition getNames]
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
  puts "\t-----------------------------------"
  puts "\t***********************************"

} else {
  puts "ERROR: the first argument must be a Pointwise project file (ending in .pw)"
  exit
}

# vim: filetype=tcl
