-- This file is part of Qtah.
--
-- Copyright 2015 Bryan Gardiner <bog@khumba.net>
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Affero General Public License version 3
-- as published by the Free Software Foundation.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Affero General Public License for more details.
--
-- You should have received a copy of the GNU Affero General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.

module Main where

import Control.Monad (unless)
import Graphics.UI.Qtah (delete, on)
import Graphics.UI.Qtah.Core.HSize (HSize (HSize))
import qualified Graphics.UI.Qtah.Widgets.QAbstractButton as QAbstractButton
import qualified Graphics.UI.Qtah.Widgets.QApplication as QApplication
import qualified Graphics.UI.Qtah.Widgets.QHBoxLayout as QHBoxLayout
import qualified Graphics.UI.Qtah.Widgets.QLabel as QLabel
import qualified Graphics.UI.Qtah.Widgets.QLayout as QLayout
import qualified Graphics.UI.Qtah.Widgets.QLineEdit as QLineEdit
import qualified Graphics.UI.Qtah.Widgets.QMainWindow as QMainWindow
import qualified Graphics.UI.Qtah.Widgets.QPushButton as QPushButton
import qualified Graphics.UI.Qtah.Widgets.QWidget as QWidget

main :: IO ()
main = do
  app <- QApplication.new

  mainWindow <- QMainWindow.new
  QWidget.setWindowTitle mainWindow "Greeter demo"
  QWidget.resize mainWindow $ HSize 400 40

  label <- QLabel.newWithText "What's your name?"

  lineEdit <- QLineEdit.new

  button <- QPushButton.newWithText "Greet"
  connectOk <- on button QAbstractButton.clickedSignal $ \_ -> do
    name <- QLineEdit.text lineEdit
    putStrLn $ if null name
               then "You don't have a name?"
               else "Hello, " ++ name ++ "!"
  unless connectOk $ putStrLn "!!! Failed to connect to button's click signal !!!"

  mainWidget <- QWidget.new
  QMainWindow.setCentralWidget mainWindow mainWidget
  hbox <- QHBoxLayout.new
  QLayout.addWidget hbox label
  QLayout.addWidget hbox lineEdit
  QLayout.addWidget hbox button
  QWidget.setLayout mainWidget hbox
  QWidget.show mainWindow
  QApplication.exec app
  delete mainWindow
  delete app
