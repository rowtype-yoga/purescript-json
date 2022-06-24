module Test.BasicsSpec where

import Prelude

import Data.Array.NonEmpty as NEA
import Data.BigInt (BigInt)
import Data.Either (Either(..))
import Data.Foldable (traverse_)
import Data.List as List
import Data.List.Lazy as LazyList
import Data.Map as Map
import Data.Maybe (Maybe(..))
import Data.Newtype (class Newtype, un)
import Data.Nullable as Nullable
import Data.Tuple (Tuple(..))
import Data.Tuple.Nested ((/\))
import Data.Variant (Variant, inj)
import Foreign.Object as Object
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual)
import Test.Util (roundtrips)
import Type.Proxy (Proxy(..))
import Yoga.JSON (class ReadForeign, class WriteForeign, readJSON, writeJSON)
import Yoga.JSON.Variant (TaggedVariant(..), UntaggedVariant(..))

spec :: Spec Unit
spec = describe "En- and decoding" $ do

  describe "works on primitive types" do
    it "roundtrips Number" $ roundtrips 3.1414
    it "roundtrips Int" $ roundtrips (-200)
    it "roundtrips Char" $ roundtrips 'a'
    it "roundtrips String" $ roundtrips "A"

  describe "works on containers types" do
    it "roundtrips Maybe" do
      roundtrips (Just 3)
      -- just roundtrips Nothing doesn't work when rendering the JSON
      roundtrips { empty: Nothing :: Maybe Int }
    it "roundtrips Nullable" $ traverse_ roundtrips [Nullable.notNull 3, Nullable.null]
    it "roundtrips Tuple" $ do
      roundtrips (Tuple 3 4)
      roundtrips ("4" /\ 8 /\ Just 4)
    it "roundtrips Array" $ traverse_ roundtrips [["A", "B"],[]]
    it "roundtrips LazyList" $ traverse_ roundtrips (LazyList.fromFoldable [["A", "B"],[]])
    it "roundtrips List" $ traverse_ roundtrips (List.fromFoldable [["A", "B"],[]])
    it "roundtrips NonEmptyArray" $ roundtrips (NEA.cons' "A" ["B"])
    it "roundtrips Object" $ roundtrips (Object.fromHomogeneous { a: 12, b: 54 })
    it "roundtrips String Map" $ roundtrips (Map.fromFoldable [("A" /\ 8),("C" /\ 7)])
    it "roundtrips Int Map" $ roundtrips (Map.fromFoldable [(4 /\ "B"),(8 /\ "D")])
    it "roundtrips Map with String newtype keys"
      $ roundtrips (Map.fromFoldable [(Stringy "A" /\ "B"),(Stringy "C" /\ "D")])
    it "roundtrips Map with Int newtype keys"
      $ roundtrips (Map.fromFoldable [(Inty 4 /\ "B"),(Inty 8 /\ "D")])
    it "roundtrips BigInt" do
      let
        inputStr = """{ "number":1, "big": 18014398509481982, "smallBig": 10 }"""
        expected = """{"smallBig":"10","number":1,"big":"18014398509481982"}"""
        parsed ∷ _ ({ number ∷ Int, big ∷ BigInt, smallBig ∷ BigInt })
        parsed = readJSON inputStr
        stringified = parsed <#> writeJSON
      stringified `shouldEqual` (Right expected)
      -- [TODO] Comment in as soon as bug in big-integers is fixed
    -- it "roundtrips BigInt (2)" do
    --   let
    --     smallBig = BigInt.fromInt 10
    --     big = unsafePartial $ fromJust $ BigInt.fromString "18014398509481982"
        
    --     expected = { big, smallBig }
    --     json = spy "json" $ writeJSON expected

    --     parsed ∷ _ ({ big ∷ BigInt, smallBig ∷ BigInt })
    --     parsed = readJSON json
    --   (spy "parsed" parsed) `shouldEqual` (Right expected)
  describe "works on record types" do
    it "roundtrips" do
      roundtrips { a: 12, b: "54" }
      roundtrips { a: 12, b: { c: "54" } }

  describe "works on newtypes" do
    it "roundtrips" do
      roundtrips (Stringy "A string is here")

  describe "works on variant types" do
    it "roundtrips" do
      roundtrips (inj (Proxy :: _ "erwin") "e" :: Variant ("erwin" :: String))
      roundtrips (inj (Proxy :: _ "jackie") 7 :: Variant ExampleVariant)

  describe "works on tagged variant types" do
    it "roundtrips" do
      roundtrips (TaggedVariant (erwin "e") :: TaggedVariant "super" "hans" (Erwin ()))
      let bareVariant = erwin "e"
      let res = writeJSON (TaggedVariant bareVariant :: TaggedVariant "type" "value" ExampleVariant)
      let expected = """{"value":"e","type":"erwin"}"""
      res `shouldEqual` expected
      let
        parsed :: _ (TaggedVariant "type" "value" ExampleVariant)
        parsed = readJSON expected
      (un TaggedVariant <$> parsed) `shouldEqual` Right bareVariant

  describe "works on untagged variant types" do
    it "roundtrips" do
      roundtrips (UntaggedVariant (erwin "e") :: UntaggedVariant (Erwin ()))
      let bareVariant = erwin "e"
      let res = writeJSON (UntaggedVariant bareVariant :: UntaggedVariant ExampleVariant)
      let expected = """"e""""
      res `shouldEqual` expected
      let
        parsed :: _ (UntaggedVariant ExampleVariant)
        parsed = readJSON expected
      (un UntaggedVariant <$> parsed) `shouldEqual` Right bareVariant

type ExampleVariant = ("erwin" :: String, "jackie" :: Int)
type ExampleTaggedVariant t v = TaggedVariant t v ExampleVariant

erwin ∷ ∀ a r. a → Variant ( erwin ∷ a | r )
erwin = inj (Proxy :: Proxy "erwin")
type Erwin r = (erwin :: String | r)

newtype Stringy = Stringy String
derive instance Newtype Stringy _
derive newtype instance Show Stringy
derive newtype instance Eq Stringy
derive newtype instance Ord Stringy
derive newtype instance WriteForeign Stringy
derive newtype instance ReadForeign Stringy

newtype Inty = Inty Int
derive instance Newtype Inty _
derive newtype instance Show Inty
derive newtype instance Eq Inty
derive newtype instance Ord Inty
derive newtype instance WriteForeign Inty
derive newtype instance ReadForeign Inty
