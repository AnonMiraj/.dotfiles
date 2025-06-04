-- ﷽
-- Contest: $(CONTEST)
--
-- Judge: $(JUDGE)
-- URL: $(URL)
-- Memory Limit: $(MEMLIM)
-- Time Limit: $(TIMELIM)
-- Start: $(DATE)
-- Reading Time :
-- Thinking Time :
-- Coding Time :
-- Debug Time :
-- Submit Count :
-- Problem Level :
-- Category :
-- Comments :

import Control.Monad
import Data.Array
import Data.List
import Debug.Trace
import Numeric
     
solveTestCase = do
  n <- readLn :: IO Int
  putStrLn (show n)
 
main = do
  numTests <- readLn :: IO Int
  -- let numTests = 10
  replicateM numTests $() do
    solveTestCase
