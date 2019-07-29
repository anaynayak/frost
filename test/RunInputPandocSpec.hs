{-# LANGUAGE QuasiQuotes #-}
module RunInputPandocSpec where

import Frost.PandocRun
import Frost.Effects.FileProvider

import Polysemy
import Polysemy.Input
import Polysemy.Error
import Polysemy.State
import PolysemyContrib

import Text.Pandoc
import Data.Map
import Data.Function ((&))
import qualified Data.Text as T
import Text.RawString.QQ
import Test.Hspec

fetch :: String -> IO (Either PandocError Pandoc)
fetch content = do
  res <- runInputPandoc input
    & runFileProviderPure
    & runState (singleton "documentation.md" (T.pack content))
    & runError
    & runM
  return $ fmap snd res

pluginAsCodeBlock = [r|
```frost:plugin
```
|]

pluginAsCodeBlockWithContent = [r|
```frost:plugin
some content here
```
|]
  
pluginInlined = [r|
`frost:plugin`
|]

pluginInlinedSurroundedByText = [r|
The value is: `frost:plugin` ... wow!
|]

spec :: Spec
spec =
  describe "Frost.PandocRun runInputPandoc" $ do
    it "with plugin as code block" $ do
      Right(Pandoc _ blocks) <- fetch pluginAsCodeBlock
      blocks `shouldBe` [CodeBlock ("",["frost:plugin"],[]) ""]

    it "with plugin as code block with content" $ do
      Right(Pandoc _ blocks) <- fetch pluginAsCodeBlockWithContent
      blocks `shouldBe` [CodeBlock ("",["frost:plugin"],[]) "some content here"]

    it "with plugin as inlined code" $ do
      Right(Pandoc _ blocks) <- fetch pluginInlined
      blocks `shouldBe` [Para [Code ("",[],[]) "frost:plugin"]]

    it "with plugin as inlined code surrounded by text" $ do
      Right(Pandoc _ blocks) <- fetch pluginInlinedSurroundedByText
      blocks `shouldBe` [Para [ Str "The"
                              , Space
                              , Str "value"
                              , Space
                              , Str "is:"
                              , Space
                              , Code ("",[],[]) "frost:plugin"
                              , Space
                              , Str "..."
                              , Space
                              , Str "wow!"]]