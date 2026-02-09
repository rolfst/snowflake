{-# LANGUAGE OverloadedStrings #-}

module Main where

import Control.Exception.Base
import Control.Monad
import Control.Monad.IO.Class
import Control.Monad.Trans.Class
import Control.Monad.Trans.Reader
import qualified Data.ByteString.Char8 as BS
import Data.List
import Data.List.Split
import qualified Data.Map as M
import Data.Maybe
import System.Directory
import System.Environment
import System.Environment.XDG.BaseDir
import System.FilePath.Posix
import System.IO
import System.Log.Handler.Simple
import System.Log.Logger
import System.Process hiding (runCommand)
import System.Taffybar
import System.Taffybar.Auth
import System.Taffybar.Context (appendHook)
import System.Taffybar.DBus
import System.Taffybar.DBus.Toggle
import System.Taffybar.Hooks
import System.Taffybar.Information.CPU
import System.Taffybar.Information.EWMHDesktopInfo
import System.Taffybar.Information.Memory
import System.Taffybar.Information.X11DesktopInfo
import System.Taffybar.SimpleConfig
import System.Taffybar.Util
import System.Taffybar.Widget
import System.Taffybar.Widget.Generic.PollingGraph
import System.Taffybar.Widget.Generic.PollingLabel
import System.Taffybar.Widget.Util
import System.Taffybar.Widget.Workspaces
import Text.Printf
import Text.Read hiding (lift)

mkRGBA (r, g, b, a) = (r / 256, g / 256, b / 256, a / 256)
red = mkRGBA (210, 77, 37, 256)
blue = mkRGBA (42, 99, 140, 256)
yellow1 = mkRGBA (242, 163, 54, 256)
yellow2 = mkRGBA (254, 204, 83, 256)
yellow3 = mkRGBA (227, 134, 18, 256)

myGraphConfig =
  defaultGraphConfig
    { graphPadding = 0
    , graphBorderWidth = 0
    , graphWidth = 75
    , graphBackgroundColor = (0.0, 0.0, 0.0, 0.0)
    }

netCfg =
  myGraphConfig
    { graphDataColors = [yellow1, yellow2]
    , graphLabel = Just "NET"
    }

memCfg =
  myGraphConfig
    { graphDataColors = [(0.129, 0.588, 0.953, 1)]
    , graphLabel = Just "MEM"
    }

cpuCfg =
  myGraphConfig
    { graphDataColors = [(0, 1, 0, 1), (1, 0, 1, 0.5)]
    , graphLabel = Just "CPU"
    }

memCallback :: IO [Double]
memCallback = do
  mi <- parseMeminfo
  return [memoryUsedRatio mi]

cpuCallback = do
  (_, systemLoad, totalLoad) <- cpuLoad
  return [totalLoad, systemLoad]

workspaceNamesLabelSetter workspace = return $
  case workspaceName workspace of
    "1" -> "일"
    "2" -> "이"
    "3" -> "삼"
    "4" -> "사"
    "5" -> "오"
    "6" -> "육"
    "7" -> "칠"
    "8" -> "팔"
    "9" -> "구"
    n -> n

main = do
  homeDirectory <- getHomeDirectory
  cssFilePath <- getUserConfigFile "taffybar" "taffybar.css"

  let cpuGraph = pollingGraphNew cpuCfg 5 cpuCallback
      memoryGraph = pollingGraphNew memCfg 5 memCallback
      myIcons =
        scaledWindowIconPixbufGetter $
          getWindowIconPixbufFromChrome
            <|||> unscaledDefaultGetWindowIconPixbuf
            <|||> (\size _ -> lift $ loadPixbufByName size "application-default-icon")
      myLauncher = simpleCommandButtonNew "\62227  NixOS" "rofi -no-lazy-grab -show drun -modi drun" >>= buildContentsBox
      myLayout = layoutNew defaultLayoutConfig
      -- myWindows = windowsNew defaultWindowsConfig { getActiveLabel = pure mempty }
      myWidgets = workspaces : map (>>= buildContentsBox) [myLayout]
      notifySystemD = void $ runCommand "systemd-notify" ["--ready"]

      myWorkspacesConfig =
        defaultWorkspacesConfig
          { minIcons = 1
          , getWindowIconPixbuf = myIcons
          , widgetGap = 0
          , showWorkspaceFn = hideEmpty
          , updateRateLimitMicroseconds = 100000
          , labelSetter = workspaceNamesLabelSetter
          }
      workspaces = workspacesNew myWorkspacesConfig

      myClock =
        textClockNewWith
          defaultClockConfig
            { clockUpdateStrategy = ConstantInterval 1.0
            , clockFormatString = "\61463  %H:%M   \61555  %d/%m/%y"
            }

      baseEndWidgets =
        map
          (>>= buildContentsBox)
          [ batteryIconNew
          , sniTrayNew
          , cpuGraph
          , memoryGraph
          , networkGraphNew netCfg Nothing
          ]
      selectedConfig =
        defaultSimpleTaffyConfig
          { startWidgets = myLauncher : myWidgets
          , endWidgets = baseEndWidgets
          , barPosition = Top
          , barPadding = 0
          , barHeight = ScreenRatio (1 / 24)
          , cssPaths = return cssFilePath
          }
      simpleTaffyConfig = selectedConfig{centerWidgets = [myClock]}

  dyreTaffybar $
    appendHook notifySystemD $
      appendHook (void $ getTrayHost False) $
        withLogServer $
          withToggleServer $
            toTaffyConfig simpleTaffyConfig

