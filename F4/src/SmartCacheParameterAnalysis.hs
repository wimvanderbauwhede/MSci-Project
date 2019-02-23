{-# LANGUAGE RecordWildCards #-}

module SmartCacheParameterAnalysis where

import           Control.Exception
import           Data.Ix
import           Data.List
import           Data.Ord
import           Debug.Trace
import           Utils
import           Language.Fortran
import           LanguageFortranTools
import           Text.Printf

-- default array ordering
-- down columns -> along rows -> back to front
defaultIterationOrder dims = range (0, dims - 1)

-- Helper method to print all the sizes of all the different
-- combination of stencil points in a stream
printResults stream =
  putStrLn
    $ concatMap
        (\(scSize, (start, end)) -> printf
          "Smart cache size = %d start index = %s end index = %s offset = %d\n"
          scSize
          (show start)
          (show end)
        )
    $ sortStencils
    $ calculateSmartCacheSizeForAllPairsOfStencilPoints
        (defaultIterationOrder 3)
        stream

printSmartCacheDetailsForStream stream =
  print $ calculateSmartCacheDetailsForStream (defaultIterationOrder 3) stream

instance Show SmartCacheDetailsForStream where
  show smartCacheDetails =
    "Start index: " ++ show startIndex ++ "\n" ++
    "End index: " ++ show endIndex ++ "\n" ++
    "Buffer size: " ++ show requiredBufferSize ++ "\n" ++
    concatMap
      (\(index, point) ->
          "Stencil point: "
          ++ show point
          ++ " buffer index = "
          ++ show index ++ "\n"
      )
      startToPointDistances
    where SmartCacheDetailsForStream {..} = smartCacheDetails

-- Sorts the results from calculateSmartCacheSizeForAllPairsOfStencilPoints by number of block
-- and then by the number of 0s in the indices. If multiple potential
-- end pairs require the same number of blocks to buffer the stencil
-- prefer the one with more zeros in the indices as this will include
-- all the other potential pairs of the same size.
sortStencils :: [(Int, ([Int], [Int]))] -> [(Int, ([Int], [Int]))]
sortStencils = sortBy
  (\(scSize1, (start1, end1)) (scSize2, (start2, end2)) ->
    scSize2
      `compare` scSize1
      <> (count (/= 0) (start1 ++ end1) `compare` count (/= 0) (start2 ++ end2))
  )

count pred = length . filter pred

scSizeOnly sten =
  let SmartCacheDetailsForStream {..} =
        calculateSmartCacheDetailsForStream (defaultIterationOrder 3) sten
  in  requiredBufferSize


data SmartCacheDetailsForStream = SmartCacheDetailsForStream
  {
    requiredBufferSize    :: Int,
    startIndex            :: [Int],
    endIndex              :: [Int],
    startToPointDistances :: [([Int], Int)]
  }

calculateSmartCacheDetailsForStream
  :: [Int] -> Stream Anno -> SmartCacheDetailsForStream
calculateSmartCacheDetailsForStream itOrder sten = SmartCacheDetailsForStream
  { requiredBufferSize    = maxNumBlocks
  , startIndex            = maxStart
  , endIndex              = maxEnd
  , startToPointDistances = pairsFromStart
  }
 where
  all = calculateSmartCacheSizeForAllPairsOfStencilPoints itOrder sten
  (maxNumBlocks, (maxStart, maxEnd)) = (head . sortStencils) all
  pairsFromStart = map (\(size, (_, point)) -> (point, size))
    $ filter (\(_, (start, _)) -> start == maxStart) all


-- This method is used to calculate the size of smart cache required to
-- buffer a stencil stream in order to produce an output stream from each of its points.
-- It also returns the end points of the stencil used to calculate that size.
-- It is designed to work for arrays of any number of dimensions.
-- It works by using the iteration order list to determine the "significance" of
-- the streams dimensions. The diagram below shows how using (defaultIterationOrder 3)
-- treats the indices of a 3D stream.
--
--                Dim 2
--      ------------------------>
--      | \
--      |  \
--      |   \
--   D  |    \
--   i  |     \  D
--   m  |      \  i
--      |       \  m
--   1  |        \
--      |         \  3
--      |          \
--      |           \
--      v            \  
--            (increasing this direction)
--
-- The function works by working out the distance between all the possible pairs of
-- stencil indices and then selecting the best using the sortStencils function.
-- To calculate the size of the smart cache required if buffer between to specific
-- points A(0, -2, -1) and B(0, 2, 1) the function starts with the most significant
-- indices e.g. -1 & 1 (when using defaultIterationOrder 3) and calculates the
-- differences between them. This is then used along with the stream dimensions to
-- calculate the size of smart cache required. The function then considers the next most
-- significant index in this case -2 and 2 and repeats the process
calculateSmartCacheSizeForAllPairsOfStencilPoints
  :: [Int] -> Stream Anno -> [(Int, ([Int], [Int]))]
calculateSmartCacheSizeForAllPairsOfStencilPoints iterationOrder (StencilStream _ _ arrayDimens stencil)
  = stencilSizesAndIndexPairs
 where
  (Stencil _ stencilDimens _ stencilIndices _) = stencil
  stencilIndicesInts                           = stripStenIndex stencilIndices
  allIndexPairs =
    [ (x, y) | x <- stencilIndicesInts, y <- stencilIndicesInts, x /= y ]
  smallIndexFirstOnly =
    filter (\(x, y) -> compareIndices x y iterationOrder == LT) allIndexPairs
  stencilSizesAndIndexPairs = map go smallIndexFirstOnly
  go (l1, l2) =
    let initial = ((l1, l2), True, 0)
        ((ol1, ol2), _, totArea) =
          foldl combineReaches initial (reverse iterationOrder)
        offset = head ol1 - head ol2
    in  (abs ((totArea + 1) - max 0 offset), (ol1, ol2))
-- fold over all the different array axes adding any buffer contributions from the difference
-- to the total buffer size. The function has to check whether the difference in lower order
-- axes is subsumed by another index value or not. In the first iteration there no higher order
-- index that could subsume the difference so skip the check to see if it is > 0 
  combineReaches
    :: (([Int], [Int]), Bool, Int) -- ((index components), first iteration, area)
    -> Int                         -- axes
    -> (([Int], [Int]), Bool, Int) -- ((index components), False, total area)
  combineReaches ((idx1, idx2), firstIter, areaSoFar) component =
    if firstIter || i1 < 0 || i2 > 0
      then
        ((idx1, idx2), False, areaSoFar + calculateReach component (idx1, idx2))
      else ((idx1, idx2), False, areaSoFar)
   where
    i1 = idx1 !! component
    i2 = idx2 !! component
  calculateReach :: Int -> ([Int], [Int]) -> Int
  calculateReach pos (ind1, ind2) = numBlocks
   where
    numBlocks   = indexDiff * totalBlocks
    indexDiff   = ind2CurComp - ind1CurComp
    ind1CurComp = ind1 !! pos
    ind2CurComp = ind2 !! pos
    totalBlocks = foldl dimensionProductFold 1 (take pos iterationOrder)
    dimensionProductFold blocks cur = ((upb - lwb) + 1) * blocks
      where (lwb, upb) = arrayDimens !! cur

stripStenIndex = map (map (\(Offset v) -> v))

-- elementwise comparison of indices based on their
-- significance as indicated by iterationOrder
compareIndices :: [Int] -> [Int] -> [Int] -> Ordering
compareIndices i1 i2 iterationOrder = if sameLength
  then orderExpr
  else error "indices of different lengths"
 where
  sameLength = length i1 == length i2
  orderExpr  = foldl (\acc cur -> acc <> ((i1 !! cur) `compare` (i2 !! cur)))
                     EQ
                     (reverse iterationOrder)

-- test method, assertions and test data

test stream@(StencilStream _ _ _ stencil) numBlocksShouldBe startShouldBeIdx endShouldBeIdx
  = numBlocksShouldBe
    == requiredBufferSize
    && startShouldBe
    == startIndex
    && endShouldBe
    == endIndex
    && length stencilIndices
    == (length startToPointDistances + 1)
 where
  (Stencil _ _ _ stencilIndices _) = stencil
  stencilIndicesInts               = stripStenIndex stencilIndices
  startShouldBe                    = stencilIndicesInts !! startShouldBeIdx
  endShouldBe                      = stencilIndicesInts !! endShouldBeIdx
  SmartCacheDetailsForStream {..} =
    calculateSmartCacheDetailsForStream (defaultIterationOrder 3) stream

assertions = assert
  (  test crossTestData3D_8x8x8                            129 2 6
  && test crossTestData3DZeroBasedIndex_8x8x8              163 2 6
  && test crossTestData3D_10x6x8                           121 2 6
  && test crossWithExtraPointsToBeIgnoredTestData3D_10x6x8 121 2 7
  && test crossWithExtraPointsNotIgnoredTestData3D_10x6x8  141 3 8
  && test nonSymetricTestData3D_10x6x8                     119 2 6
  && test nonSymetricLarger_10x6x8                         123 2 6
  && test nonSymetricTestDataExtremities_10x6x8            119 0 1
  && test extremesCrossTestData3D_10x6x8                   121 0 1
  && test testData3Darray1D_10x6x8                         3   1 0
  && test testData3Darray2D_10x6x8                         21  1 0
  && test nonSymetricalLargerThan1Offset                   35  0 1
  )
  "Assertions passed"

-- Test data

nonSymetricalLargerThan1Offset = StencilStream
  "test"
  Float
  [(1, 8), (1, 8), (1, 8)]
  (Stencil
    nullAnno
    3
    2
    [ [Offset (-1), Offset (-2), Offset 0]
    , [Offset 1, Offset 2, Offset 0]
    , [Offset 0, Offset (-1), Offset 0]
    , [Offset 0, Offset 1, Offset 0]
    ]
    (VarName nullAnno "test")
  )

crossTestData3DZeroBasedIndex_8x8x8 = StencilStream
  "test"
  Float
  [(0, 8), (0, 8), (0, 8)]
  (Stencil
    nullAnno
    3
    2
    [ [Offset (-1), Offset 0, Offset 0]
    , [Offset 0, Offset (-1), Offset 0]
    , [Offset 0, Offset 0, Offset (-1)]
    , [Offset 0, Offset 0, Offset 0]
    , [Offset 1, Offset 0, Offset 0]
    , [Offset 0, Offset 1, Offset 0]
    , [Offset 0, Offset 0, Offset 1]
    ]
    (VarName nullAnno "test")
  )

crossTestData3D_8x8x8 = StencilStream
  "test"
  Float
  [(1, 8), (1, 8), (1, 8)]
  (Stencil
    nullAnno
    3
    2
    [ [Offset (-1), Offset 0, Offset 0]
    , [Offset 0, Offset (-1), Offset 0]
    , [Offset 0, Offset 0, Offset (-1)]
    , [Offset 0, Offset 0, Offset 0]
    , [Offset 1, Offset 0, Offset 0]
    , [Offset 0, Offset 1, Offset 0]
    , [Offset 0, Offset 0, Offset 1]
    ]
    (VarName nullAnno "test")
  )


crossTestData3D_10x6x8 = StencilStream
  "test"
  Float
  [(1, 10), (1, 6), (1, 8)]
  (Stencil
    nullAnno
    3
    2
    [ [Offset (-1), Offset 0, Offset 0]
    , [Offset 0, Offset (-1), Offset 0]
    , [Offset 0, Offset 0, Offset (-1)]
    , [Offset 0, Offset 0, Offset 0]
    , [Offset 1, Offset 0, Offset 0]
    , [Offset 0, Offset 1, Offset 0]
    , [Offset 0, Offset 0, Offset 1]
    ]
    (VarName nullAnno "test")
  )


extremesCrossTestData3D_10x6x8 = StencilStream
  "test"
  Float
  [(1, 10), (1, 6), (1, 8)]
  (Stencil nullAnno
           3
           2
           [[Offset 0, Offset 0, Offset (-1)], [Offset 0, Offset 0, Offset 1]]
           (VarName nullAnno "test")
  )

crossWithExtraPointsToBeIgnoredTestData3D_10x6x8 = StencilStream
  "test"
  Float
  [(1, 10), (1, 6), (1, 8)]
  (Stencil
    nullAnno
    3
    2
    [ [Offset (-1), Offset 0, Offset 0]
    , [Offset 0, Offset (-1), Offset 0]
    , [Offset 0, Offset 0, Offset (-1)]
    , [Offset 0, Offset 1, Offset (-1)]
    , [Offset 0, Offset 0, Offset 0]
    , [Offset 1, Offset 0, Offset 0]
    , [Offset 0, Offset 1, Offset 0]
    , [Offset 0, Offset 0, Offset 1]
    , [Offset 0, Offset (-1), Offset 1]
    ]
    (VarName nullAnno "test")
  )


crossWithExtraPointsNotIgnoredTestData3D_10x6x8 = StencilStream
  "test"
  Float
  [(1, 10), (1, 6), (1, 8)]
  (Stencil
    nullAnno
    3
    2
    [ [Offset (-1), Offset 0, Offset 0]
    , [Offset 0, Offset (-1), Offset 0]
    , [Offset 0, Offset 0, Offset (-1)]
    , [Offset 0, Offset (-1), Offset (-1)]
    , [Offset 0, Offset 0, Offset 0]
    , [Offset 1, Offset 0, Offset 0]
    , [Offset 0, Offset 1, Offset 0]
    , [Offset 0, Offset 0, Offset 1]
    , [Offset 0, Offset 1, Offset 1]
    ]
    (VarName nullAnno "test")
  )


extremitiesOfCrossNotIgnore_10x6x8 = StencilStream
  "test"
  Float
  [(1, 10), (1, 6), (1, 8)]
  (Stencil
    nullAnno
    3
    2
    [[Offset 0, Offset (-1), Offset (-1)], [Offset 0, Offset 1, Offset 1]]
    (VarName nullAnno "test")
  )

nonSymetricTestData3D_10x6x8 = StencilStream
  "test"
  Float
  [(1, 10), (1, 6), (1, 8)]
  (Stencil
    nullAnno
    3
    2
    [ [Offset (-1), Offset 0, Offset 0]
    , [Offset 0, Offset (-1), Offset 0]
    , [Offset 1, Offset 0, Offset (-1)]
    , [Offset 0, Offset 0, Offset 0]
    , [Offset 1, Offset 0, Offset 0]
    , [Offset 0, Offset 1, Offset 0]
    , [Offset (-1), Offset 0, Offset 1]
    ]
    (VarName nullAnno "test")
  )

testData3Darray1D_10x6x8 = StencilStream
  "test"
  Float
  [(1, 10), (1, 6), (1, 8)]
  (Stencil nullAnno
           3
           2
           [[Offset 1, Offset 0, Offset 0], [Offset (-1), Offset 0, Offset 0]]
           (VarName nullAnno "test")
  )

testData3Darray2D_10x6x8 = StencilStream
  "test"
  Float
  [(1, 10), (1, 6), (1, 8)]
  (Stencil nullAnno
           3
           2
           [[Offset 0, Offset 1, Offset 0], [Offset 0, Offset (-1), Offset 0]]
           (VarName nullAnno "test")
  )

nonSymetricLarger_10x6x8 = StencilStream
  "test"
  Float
  [(1, 10), (1, 6), (1, 8)]
  (Stencil
    nullAnno
    3
    2
    [ [Offset (-1), Offset 0, Offset 0]
    , [Offset 0, Offset (-1), Offset 0]
    , [Offset (-1), Offset 0, Offset (-1)]
    , [Offset 0, Offset 0, Offset 0]
    , [Offset 1, Offset 0, Offset 0]
    , [Offset 0, Offset 1, Offset 0]
    , [Offset 1, Offset 0, Offset 1]
    ]
    (VarName nullAnno "test")
  )

nonSymetricTestDataExtremities_10x6x8 = StencilStream
  "test"
  Float
  [(1, 10), (1, 6), (1, 8)]
  (Stencil
    nullAnno
    3
    2
    [[Offset 1, Offset 0, Offset (-1)], [Offset (-1), Offset 0, Offset 1]]
    (VarName nullAnno "test")
  )