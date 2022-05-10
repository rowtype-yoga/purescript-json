module Test.EnumSumGeneric where

import Prelude

import Control.Alt ((<|>))
import Control.Monad.Except (throwError)
import Data.Either (Either, isRight)
import Data.Generic.Rep (class Generic, Constructor(..), NoArguments(..), Sum(..), to)
import Data.Show.Generic (genericShow)
import Effect (Effect)
import Foreign (Foreign)
import Foreign as Foreign
import JSON as JSON
import Test.Assert (assert)
import Type.Prelude (class IsSymbol, Proxy(..), reflectSymbol)

enumReadForeign ∷
  ∀ a rep.
  Generic a rep ⇒
  EnumReadForeign rep ⇒
  Foreign →
  Foreign.F a
enumReadForeign f =
  to <$> enumReadForeignImpl f

-- type class for "enums", or nullary sum types
class EnumReadForeign rep where
  enumReadForeignImpl ∷ Foreign → Foreign.F rep

instance
  ( EnumReadForeign a
  , EnumReadForeign b
  ) ⇒
  EnumReadForeign (Sum a b) where
  enumReadForeignImpl f = Inl <$> enumReadForeignImpl f
    <|> Inr <$> enumReadForeignImpl f

instance
  ( IsSymbol name
  ) ⇒
  EnumReadForeign (Constructor name NoArguments) where
  enumReadForeignImpl f = do
    s ← JSON.readImpl f
    if s == name then pure $ Constructor NoArguments
    else throwError <<< pure <<< Foreign.ForeignError $
      "Enum string " <> s <> " did not match expected string " <> name
    where
    name = reflectSymbol (Proxy ∷ Proxy name)

data Fruit
  = Abogado
  | Boat
  | Candy

derive instance Generic Fruit _
instance JSON.ReadForeign Fruit where
  readImpl = enumReadForeign

instance Show Fruit where
  show = genericShow

readFruit ∷ String → Either Foreign.MultipleErrors Fruit
readFruit = JSON.readJSON

main ∷ Effect Unit
main = do
  assert <<< isRight $ readFruit "\"Abogado\""
  assert <<< isRight $ readFruit "\"Boat\""
  assert <<< isRight $ readFruit "\"Candy\""
