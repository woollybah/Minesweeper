'
' BlitzMax port of Minesweeper-Switch, by rincew1nd
'
' port by Bruce A Henderson
'
'
SuperStrict

Framework sdl.sdlrender
?Not nx
Import sdl.sdlsystem
Import brl.polledinput
?nx
Import pub.nx
?
Import brl.standardio
Import brl.map
Import brl.math
Import brl.random
Import brl.freetypefont

? Not nx
EnablePolledInput
?

Print "Minesweeper start!"

Local minesweeper:TMinesweeper = New TMinesweeper
minesweeper.Run()


Type TMinesweeper

	Field renderer:TSDLRenderer
	Field window:TSDLWindow
	
	Field gameScene:TGameScene
	Field resources:TResources
	
	Field inp:TInput

	Method New()
		If InitSDL() Then
			InitGame()
		End If		
	End Method

	Method InitSDL:Int()
		If SDL_Init(SDL_INIT_VIDEO | SDL_INIT_JOYSTICK) < 0 Then
			Return False
		End If
		
		Local x:Int
		Local y:Int
		?Not nx
		x = SDL_WINDOWPOS_CENTERED
		y = SDL_WINDOWPOS_CENTERED
		?
		
		window = TSDLWindow.Create("", x, y, 1280, 720, 0)
		
		If Not window Then
			Return False
		End If
		
		renderer = TSDLRenderer.Create(window)
		
		renderer.SetDrawColor(208, 176, 48, 255)
		renderer.Clear()
		renderer.Present()
		
		Return True
	End Method
	
	Method InitGame()
		inp = New TInput
	
		?nx
		romfsInit()
		?
		resources = New TResources()
        resources.LoadROMFS(renderer)
		
		gameScene = New TGameScene(resources)
	End Method

	Method Run()
		?nx
		While (appletMainLoop())
		?Not nx
		While Not KeyDown(key_escape)
		?

			' Handle touchscreen
			inp.Scan()
			Local touchInfo:TTouchInfo = inp.GetTouchInfo()
			If touchInfo.kind <> TOUCH_NONE Then
			'If (_input->Scan())
				gameScene.HandleClick(touchInfo)
			End If
			
			' Handle joy-con button press
			?nx
			If (hidKeysDown(CONTROLLER_P1_AUTO) & KEY_PLUS) Then
				Exit
			End If
			?
			
			' Clear screen
			renderer.Clear()
			
			' Render entity To screen
			gameScene.Draw(renderer)
			
			renderer.SetDrawColor(208, 176, 48, 255)
			
			' Draw screen
			renderer.Present()
			
			' Pause
			Delay(1)
		Wend
		
		DeinitSDL()
	End Method

	Method DeinitSDL()
		renderer.Destroy()
		window.Destroy()
		
		SDL_Quit()
	End Method

End Type

Type TResources

	Field textures:TMap = New TMap
	Field cellTextures:TIntMap = New TIntMap
	Field font:TFont
	
	Method LoadROMFS(renderer:TSDLRenderer)
		' Cell textures
		Local closed:TSDLTexture[] = [LoadTexture(renderer, "closed")]
		cellTextures.Insert(STATE_CLOSED, closed)
		
		Local opened:TSDLTexture[]
		For Local i:Int = 0 Until 10
			opened :+ [LoadTexture(renderer, "cell" + i)]
		Next
		cellTextures.Insert(STATE_OPENED, opened)
		
		Local flagged:TSDLTexture[] = [LoadTexture(renderer, "flagged")]
		cellTextures.Insert(STATE_FLAGGED, flagged)
		
		' Button textures
		textures.Insert("flagOnButton", LoadTexture(renderer, "flagOnButton"))
		textures.Insert("flagOffButton", LoadTexture(renderer, "flagOffButton"))
		textures.Insert("restartButton", LoadTexture(renderer, "restartButton"))
		textures.Insert("settingsButton", LoadTexture(renderer, "settingsButton"))
		textures.Insert("escButton", LoadTexture(renderer, "escButton"))
		textures.Insert("arrowRightButton", LoadTexture(renderer, "arrowRightButton"))
		textures.Insert("arrowLeftButton", LoadTexture(renderer, "arrowLeftButton"))
		textures.Insert("minusButton", LoadTexture(renderer, "minusButton"))
		textures.Insert("plusButton", LoadTexture(renderer, "plusButton"))

		' Load font
		LoadFont("Pixeled.ttf")
	End Method
	
	Method LoadTexture:TSDLTexture(renderer:TSDLRenderer, name:String)
		?nx
		Local imagePath:String = "romfs:/" + name + ".bmp"
		?Not nx
		Local imagePath:String = "romfs/" + name + ".bmp"
		?
		Local surface:TSDLSurface = TSDLSurface.LoadBMP(imagePath)
		Local texture:TSDLTexture = renderer.CreateTextureFromSurface(surface)
		surface.Free()
		Return texture
	End Method
	
	Method LoadFont(name:String)
		?nx
		Local fontPath:String = "romfs:/" + name
		?Not nx
		Local fontPath:String = "romfs/" + name
		?
		font = TFreeTypeFont.Load(fontPath, 20, SMOOTHFONT)
	End Method
	
	Method GetTexture:TSDLTexture(name:String)
		Return TSDLTexture(textures.ValueForKey(name))
	End Method
	
	Method GetTexture:TSDLTexture(state:Int, order:Int)
		Return TSDLTexture[](cellTextures.ValueForKey(state))[order]
	End Method
	
	Method GetFont:TFont()
		Return font
	End Method
	
End Type

Type TGameScene

	Field resources:TResources
	
	Field board:TBoard
	Field buttons:TButton[]
	Field widgets:TWidget[]
	Field texts:TTextObject[]

	Method New(resources:TResources)
		Self.resources = resources
		
		board = New TBoard(TGlobals.boardWidth, TGlobals.boardHeight, resources)
		
		Local widget:TWidget = New TSettingsWidget(490, 200, 450, 350, resources)
		widget.SetColor(152, 120, 24)
		
		Add(widget)
		
		widget = New TGameOverWidget(490, 250, 300, 100, resources)
		widget.SetColor(152, 120, 24)
		
		Add(widget)
		
		InitButtons()
	End Method

	Method InitButtons()
		Local textObject:TTextObject = New TTextObject(60, 700, resources.GetFont())
		textObject.Text = (board.mineCount - board.flagCount)
		Add(textObject)

		Local button:TButton = New TButton(545, 665, 50, 50, "restartButton")
		button.SetTexture(resources.GetTexture(button.GetName()))
		button.SetAction(Restart, Self)
		Add(button)
		
		button = New TButton(615, 665, 50, 50, "flagButton")
		button.AddTexture(resources.GetTexture("flagOnButton"))
		button.AddTexture(resources.GetTexture("flagOffButton"))
		button.SetTexture(1)
		button.SetAction(ToggleButton, button)
		Add(button)
		
		button = New TButton(685, 665, 50, 50, "settingsButton")
		button.SetTexture(resources.GetTexture(button.GetName()))
		Local settings:TWidget = widgets[0]
		button.SetAction(ShowSettings, settings)
		Add(button)
				
		button = New TButton(800, 665, 50, 50, "settingsButton")
		button.SetTexture(resources.GetTexture(button.GetName()))
		button.SetAction(Move, Self)
		Add(button)
	End Method
	
	Method Draw(renderer:TSDLRenderer)
		board.Draw(renderer)
		
		For Local i:Int = 0 Until buttons.length
			buttons[i].Draw(renderer)
		Next
		
		For Local i:Int = 0 Until widgets.length
			widgets[i].Draw(renderer)
		Next
		
		For Local i:Int = 0 Until texts.length
			texts[i].Draw(renderer)
		Next
	End Method
	
	Method Add(widget:TWidget)
		widgets :+ [widget]
	End Method
	
	Method Add(button:TButton)
		buttons :+ [button]
	End Method
	
	Method Add(Text:TTextObject)
		texts :+ [Text]
	End Method
	
	Method HandleClick(touchInfo:TTouchInfo)
		Select touchInfo.kind
			Case TOUCH_PRESS
				
				Local widgetVisible:Int = False
				Local guiClick:Int = False
				For Local i:Int = 0 Until widgets.length
					If widgets[i].isVisible Then
						widgets[i].HandleTouch(touchInfo)
						widgetVisible = True
					End If
				Next
				
				If Not widgetVisible Then
					For Local i:Int = 0 Until buttons.length
						If buttons[i].Hovered(touchInfo) And buttons[i].IsVisible() Then
							buttons[i].Press()
							guiClick = True
						End If
					Next
					
					If Not guiClick Then
						board.HandleClick(touchInfo)
						If board.gameOver Then
							TGameOverWidget(widgets[1]).Show(False)
							board.gameOver = False
						End If
					End If
				End If
				
				If board.CheckState() Then
					TGameOverWidget(widgets[1]).Show(True)
					board.needRestart = True
				End If
				
				texts[0].Text = board.mineCount - board.flagCount

			Case TOUCH_DRAG
				board.Move(touchInfo.valueOne, touchInfo.valueTwo)
				
			Case TOUCH_PINCH
				TGlobals.cellSize :+ touchInfo.valueOne
		End Select
	End Method
	
	Function Restart(handle:Object)
		TGameScene(handle).board.needRestart = True
		TGameScene(handle).board.Restart()
	End Function
	
	Function ToggleButton(handle:Object)
		TGlobals.isFlag = Not TGlobals.isFlag
		TButton(handle).SetTexture(Not TGlobals.IsFlag)
	End Function
	
	Function ShowSettings(handle:Object)
		TWidget(handle).IsVisible = True
	End Function
	
	Function Move(handle:Object)
		TGameScene(handle).board.Move(10, 10)
	End Function
	
End Type

Type TBoardAction
	Field board:TBoard
	Field cell:TCell
	
	Method New(board:TBoard, cell:TCell)
		Self.board = board
		Self.cell = cell
	End Method
End Type

Type TBoard

	Field gridLeft:Int
	Field gridTop:Int
	Field boardWidth:Int
	Field boardHeight:Int
	
	Field resources:TResources
	
	Field needRestart:Int = True
	Field gameOver:Int
	Field needHardRestart:Int
	
	Field mineCount:Int
	Field flagCount:Int
	
	Field cells:TCell[]

	Method New(width:Int, height:Int, resources:TResources)
		Self.resources = resources

		GenerateBoard()
	End Method
	
	Method GenerateBoard()
		boardWidth = TGlobals.boardWidth
		boardHeight = TGlobals.boardHeight
		
		gridLeft = (TGlobals.windowWidth - TGlobals.boardWidth * TGlobals.cellSize) / 2
		gridTop = (TGlobals.windowHeight - TGlobals.boardHeight * TGlobals.cellSize) / 2
		
		' todo : board stuff
		For Local y:Int = 0 Until boardHeight
			For Local x:Int = 0 Until boardWidth
				Local cell:TCell = New TCell(x, y, gridLeft, gridTop)
				cell.AddTexture(resources.GetTexture(STATE_CLOSED, 0))
				cell.AddTexture(resources.GetTexture(STATE_FLAGGED, 0))
				cell.SetTexture(0)
				cell.SetAction(Action, New TBoardAction(Self, cell))
				cells :+ [cell]
			Next
		Next
		
		For Local i:Int = 0 Until boardWidth
			For Local j:Int = 0 Until boardHeight
				For Local di:Int = i-1 To i+1
					For Local dj:Int = j-1 To j+1
						If Not (di=i And dj=j) And IsOnBoard(di, dj) Then
							GetCell(i, j).AddNearCell(GetCell(di, dj))
						End If
					Next
				Next
			Next
		Next
		
		GenerateMinefield()
	End Method
	
	Method GenerateMinefield()
		mineCount = 0;
		
		SeedRnd(MilliSecs())
		For mineCount = 0 To boardHeight * boardWidth * 0.1 * TGlobals.difficulty
			While True
				Local posX:Int = Rand(1000000) Mod boardWidth
				Local posY:Int = Rand(1000000) Mod boardHeight
				
				If GetCell(posX, posY).nearMinesCount <> 9 Then
					GetCell(posX, posY).nearMinesCount = 9
					mineCount :+ 1
					Exit
				End If
			Wend
		Next
		
		For Local i:Int = 0 Until boardWidth
			For Local j:Int = 0 Until boardHeight
				For Local di:Int = i-1 To i+1
					For Local dj:Int = j-1 To j+1
						If Not (di=i And dj=j) And IsOnBoard(di, dj) Then
							If GetCell(di, dj).nearMinesCount = 9 And GetCell(i, j).nearMinesCount <> 9 Then
								GetCell(i, j).nearMinesCount :+ 1
							End If
						End If
					Next
				Next
			Next
		Next
		
		For Local i:Int = 0 Until boardWidth * boardHeight
			cells[i].AddTexture(resources.GetTexture(STATE_OPENED, cells[i].nearMinesCount), 2)
		Next
	End Method
	
	Method GetCell:TCell(x:Int, y:Int)
		Return cells[x + y * boardWidth]
	End Method

	Method Restart()
		If needRestart Then
			needRestart = False
			For Local i:Int = 0 Until boardWidth * boardHeight
				cells[i].Reset()
			Next
			GenerateMinefield()
		End If
			
		If needHardRestart Then
			needHardRestart = False
			cells = []
			GenerateBoard()
		End If
	End Method
	
	Method Move(x:Int, y:Int)
		gridLeft :+ x
		gridTop :+ y
	End Method
	
	Method Draw(renderer:TSDLRenderer)
		Restart()
		For Local i:Int = 0 Until boardWidth * boardHeight
			cells[i].Draw(gridLeft, gridTop, renderer)
		Next
	End Method
	
	Method HandleClick(point:TTouchInfo)
		For Local i:Int = 0  Until cells.length
			If cells[i].Hovered(point) And cells[i].IsVisible() Then
				cells[i].Press()
			End If
		Next
	End Method
	
	Method OpenAll()
		For Local i:Int = 0 Until boardWidth * boardHeight
			cells[i].SetState(STATE_OPENED)
		Next
	End Method
	
	Method IsOnBoard:Int(x:Int, y:Int)
		If x >= 0 And x < boardWidth Then
			If y >= 0 And y < boardHeight Then
				Return True
			End If
		End If
		Return False
	End Method
		
	Method CheckState:Int()
		flagCount = 0
		Local allFlagsCorrect:Int = True
		Local allCellsOpened:Int = True
		
		For Local i:Int = 0 Until boardWidth * boardHeight
			If cells[i].GetState() = STATE_FLAGGED Then
				If cells[i].nearMinesCount <> 9 Then
					allFlagsCorrect = False
				End If
				flagCount :+ 1
			End If
			
			If cells[i].nearMinesCount <> 9 And cells[i].GetState() <> STATE_OPENED Then
				allCellsOpened = False
			End If
		Next
		
		If allFlagsCorrect And flagCount = mineCount Then
			allFlagsCorrect = True
		Else
			allFlagsCorrect = False
		End If
		
		Return allCellsOpened Or allFlagsCorrect
	End Method
	
	Function Action(handle:Object)
		Local act:TBoardAction = TBoardAction(handle)
		
		If (act.cell.GetState() = STATE_OPENED And Not act.cell.OpenNearCells()) Or Not act.cell.SetState(TGlobals.isFlag * 2) Then
			act.board.needRestart = True
			act.board.gameOver = True
		End If
	End Function
	
End Type

Type TGameObject

	Field x:Int
	Field y:Int
	Field w:Int
	Field h:Int
	
	Field onPress(handle:Object)
	Field handle:Object
	
	Method New(x:Int, y:Int, w:Int, h:Int)
		Self.x = x
		Self.y = y
		Self.w = w
		Self.h = h
	End Method

	Method SetAction(func(handle:Object), handle:Object)
		onPress = func
		Self.handle = handle
	End Method
	
	Method Press()
		If onPress Then
			onPress(handle)
		End If
	End Method

	Method Hovered:Int(info:TTouchInfo)
		Return info.valueOne >= x And info.valueOne <= x + w And info.valueTwo >= y And info.valueTwo <= y + h
	End Method
	
	Method Move(dx:Int, dy:Int)
		x :+ dx
		y :+ dy
	End Method

End Type

Type TGraphicalObject Extends TGameObject

	Field r:Byte, g:Byte, b:Byte, a:Byte
	Field visible:Int
	
	Method New(x:Int, y:Int, w:Int, h:Int)
		Super.New(x, y, w, h)
		a = 255
		visible = True
	End Method

	Method SetColor(r:Int, g:Int, b:Int, a:Int)
		Self.r = r
		Self.g = g
		Self.b = b
		Self.a = a
	End Method
	
	Method SetColor(r:Int, g:Int, b:Int)
		SetColor(r, g, b, 255)
	End Method
	
	Method Draw(renderer:TSDLRenderer)
		If visible Then
			renderer.SetDrawColor(r, g, b, a)
			renderer.FillRect(x, y, w, h)
		End If
	End Method
	
	Method GetRect(x:Int Var, y:Int Var, w:Int Var, h:Int Var)
		x = Self.x
		y = Self.y
		w = Self.w
		h = Self.h
	End Method
	
	Method SetVisible(visible:Int)
		Self.visible = visible
	End Method
	
	Method IsVisible:Int()
		Return visible
	End Method

End Type

Type TSpriteObject Extends TGraphicalObject

	Field texture:TSDLTexture
	Field textures:TSDLTexture[2]
	Field count:Int

	Method New(x:Int, y:Int, w:Int, h:Int)
		Super.New(x, y, w, h)
	End Method
	
	Method Draw(renderer:TSDLRenderer)
		If visible Then
			If texture Then
				renderer.Copy(texture, -1, -1, -1, -1, x, y, w, h)
			Else
				renderer.SetDrawColor(r, g, b, a)
				renderer.FillRect(x, y, w, h)
			End If
		End If
	End Method
	
	Method SetTexture(texture:TSDLTexture)
		Self.texture = texture
	End Method
	
	Method SetTexture(pos:Int)
		If textures.length > pos Then
			SetTexture(textures[pos])
		End If
	End Method
	
	Method AddTexture(texture:TSDLTexture)
		If count = textures.length Then
			textures = textures[..textures.length * 2]
		End If
		
		textures[count] = texture
		count :+ 1
	End Method
	
	Method AddTexture:Int(texture:TSDLTexture, pos:Int)
		If textures.length > pos Then
			textures[pos] = texture
		Else If textures.length = pos Then
			AddTexture(texture)
		Else
			Return False
		End If
		
		Return True
	End Method
	
End Type

Type TButton Extends TSpriteObject

	Field name:String
	
	Method New(x:Int, y:Int, w:Int, h:Int, name:String)
		Super.New(x, y, w, h)
		Self.name = name
	End Method
	
	Method New(x:Int, y:Int, w:Int, h:Int, name:String, func(h:Object), handle:Object)
		Super.New(x, y, w, h)
		SetAction(func, handle)
		Self.name = name
	End Method
	
	Method GetName:String()
		Return name
	End Method
	
End Type

Type TWidget

	Field isVisible:Int
	Field buttons:TButton[]
	Field texts:TTextObject[]
	
	Field r:Byte, g:Byte, b:Byte, a:Byte
	Field widgetBackgroundTexture:TSDLTexture
	
	Field x:Int, y:Int, w:Int, h:Int

	Method New(x:Int, y:Int, w:Int, h:Int)
		Self.x = x
		Self.y = y
		Self.w = w
		Self.h = h
		
		
	End Method
	
	Method SetColor(r:Int, g:Int, b:Int, a:Int)
		Self.r = r
		Self.g = g
		Self.b = b
		Self.a = a
	End Method
	
	Method SetColor(r:Int, g:Int, b:Int)
		SetColor(r, g, b, 255)
	End Method
	
	Method SetTexture(texture:TSDLTexture)
		widgetBackgroundTexture = texture
	End Method
	
	Method Draw(renderer:TSDLRenderer)
		If isVisible Then
			If widgetBackgroundTexture Then
				renderer.Copy(widgetBackgroundTexture, -1, -1, -1, -1, x, y, w, h)
			Else
				renderer.SetDrawColor(r, g, b, a)
				renderer.FillRect(x, y, w, h)
			End If
			
			For Local i:Int = 0 Until buttons.length
				buttons[i].Draw(renderer)
			Next
			
			For Local i:Int = 0 Until texts.length
				texts[i].Draw(renderer)
			Next
		End If
	End Method
	
	Method Add(button:TButton)
		buttons :+ [button]
	End Method
	
	Method Add(Text:TTextObject)
		texts :+ [Text]
	End Method
	
	Method HandleTouch(touchInfo:TTouchInfo)
		For Local i:Int = 0 Until buttons.length
			If buttons[i].Hovered(touchInfo) And buttons[i].IsVisible() Then
				buttons[i].Press()
			End If
		Next
	End Method
	
End Type

Type TGlobals

	Global difficulty:Int = 1
	Global isFlag:Int
	Global boardWidth:Int = 24
	Global boardHeight:Int = 13
	Global windowWidth:Int = 1280
	Global windowHeight:Int = 720
	
	Global cellSize:Int = 50
	
End Type

Type TSettingsWidget Extends TWidget

	Method New(x:Int, y:Int, w:Int, h:Int, res:TResources)
		Super.New(x, y, w, h)
		
		Local textObject:TTextObject = New TTextObject(x+w/2, y+45, res.GetFont())
		textObject.Text = "PAUSE"
		Add(textObject)
		
		textObject = New TTextObject(x+w/2, y+120, res.GetFont())
		textObject.Text = "Difficulty"
		Add(textObject)
		
		textObject = New TTextObject(x+w/2, y+270, res.GetFont())
		textObject.Text = "Press + to"
		Add(textObject)
		
		textObject = New TTextObject(x+w/2, y+305, res.GetFont())
		textObject.Text = "exit application"
		Add(textObject)
		
		textObject = New TTextObject(x+w/2, y+175, res.GetFont())
		textObject.Text = TGlobals.difficulty
		Add(textObject)
		
		Local button:TButton = New TButton(x + w - 70, y + 20, 50, 50, "escButton")
		button.AddTexture(res.GetTexture(button.GetName()))
		button.SetTexture(0)
		button.SetAction(Hide, Self)
		Add(button)
		
		button = New TButton(x+20, y+150, 50, 50, "minusButton")
		button.AddTexture(res.GetTexture(button.GetName()))
		button.SetTexture(0)
		button.SetAction(DecreaseDifficulty, textObject)
		Add(button)
		
		button = New TButton(x+w-70, y+150, 50, 50, "plusButton")
		button.AddTexture(res.GetTexture(button.GetName()))
		button.SetTexture(0)
		button.SetAction(IncreaseDifficulty, textObject)
		Add(button)
	End Method
	
	Function Hide(handle:Object)
		TSettingsWidget(handle).isVisible = False
	End Function

	Function IncreaseDifficulty(handle:Object)
		TGlobals.difficulty :+ 1
		If TGlobals.difficulty > 4 Then
			TGlobals.difficulty = 4
		End If
		TTextObject(handle).Text = TGlobals.difficulty
	End Function
	
	Function DecreaseDifficulty(handle:Object)
		TGlobals.difficulty :- 1
		If TGlobals.difficulty < 1 Then
			TGlobals.difficulty = 1
		End If
		TTextObject(handle).Text = TGlobals.difficulty
	End Function
	
End Type

Type TTextObject Extends TGraphicalObject

	Field Text:String

	Field centerX:Int
	Field centerY:Int
	
	Field lastText:String
	
	Field font:TFont
	Field texture:TSDLTexture
	
	Method New(x:Int, y:Int, font:TFont)
		centerX = x
		centerY = y
		Self.font = font
		SetVisible(True)
	End Method
	
	Method Move(x:Int, y:Int)
		Super.Move(x, y)
		centerX :+ x
		centerY :+ y
	End Method
	
	Method Draw(renderer:TSDLRenderer)
		If IsVisible() Then
			If lastText <> Text Then
				If texture Then
					texture.Destroy()
				End If

				w = 0
				h = font.Height()
				
				For Local n:Int=0 Until Text.length
					Local i:Int=font.CharToGlyph( Text[n] )
					If i<0 Continue
					w :+ font.LoadGlyph(i).Advance()
				Next


				Local textSurface:TSDLSurface = TSDLSurface.CreateRGBWithFormat(w, h, 32, SDL_PIXELFORMAT_ARGB8888)

				textSurface.Lock()

				Local dst:Byte Ptr = textSurface.Pixels()
				Local offset:Int

				For Local n:Int=0 Until Text.length
					Local i:Int=font.CharToGlyph( Text[n] )
					If i<0 Continue
					Local glyph:TGlyph = font.LoadGlyph(i)
					
					Local srcPix:TPixmap = TPixmap(glyph.Pixels())
					If Not srcPix Then
						offset :+ glyph.Advance()
						Continue
					End If
					Local src:Byte Ptr = srcPix.pixels
					Local dstPitch:Int = textSurface.Pitch()
					Local width:Int = glyph.Advance()
				
					For Local y:Int = 0 Until srcPix.Height
					
						Local srcRowPtr:Byte Ptr = src + y * srcPix.pitch
						Local dstRowPtr:Byte Ptr = dst + y * dstPitch + offset * 4
						
						For Local x:Int = 0 Until srcPix.Width
							Local pixel:Byte Ptr = dstRowPtr + x * 4
							
							pixel[0] = r
							pixel[1] = g
							pixel[2] = b
							pixel[3] = (srcRowPtr + x)[0]
						Next
					Next
					
					offset :+ width
				Next
				textSurface.Unlock()

				
				texture = renderer.CreateTextureFromSurface(textSurface)
				
				lastText = Text 
			End If
			
			renderer.Copy(texture, -1, -1, -1, -1, centerX - w / 2, centerY - h / 2, w, h) 

		End If
	End Method
	
End Type

Type TGameOverWidget Extends TWidget

	Method New(x:Int, y:Int, w:Int, h:Int, res:TResources)
		Super.New(x, y, w, h)
		
		Local textObject:TTextObject = New TTextObject(x+w/2, y+50, res.GetFont())
		texts :+ [textObject]
		
		Local button:TButton = New TButton(x, y, w, h, "escButton")
		button.SetColor(152, 120, 24)
		button.SetAction(Action, Self)
		buttons :+ [button]
	End Method
	
	Method Show(value:Int)
		isVisible = True
		If value Then
    		texts[0].Text = "YOU WON"
		Else
			texts[0].Text = "GAME OVER"
		End If
	End Method
	
	Function Action(handle:Object)
		TGameOverWidget(handle).isVisible = False
	End Function
	
End Type


Type TInput
	
	Field touchType:Int
	Field lastTouchInfo:TTouchInfo = New TTouchInfo
	
	Field lastDragX:Int
	Field lastDragY:Int
	Field lastPinchDelta:Int
	
	Field touchCount:Int
	Field touchPressed:Int
	Field firstPinch:Int = True
	Field firstDrag:Int = True
	Field touchPressTime:UInt
	
	?nx
	Field touchPoints:NxTouchPosition[10]
	Field defaultTP:NxTouchPosition
	?Not nx
	Field touchPoints:TTouchPosition[10]
	Field defaultTP:TTouchPosition = New TTouchPosition
	?
	
	Method New()
		defaultTP.px = -1
		defaultTP.py = -1
		?Not nx
		For Local i:Int = 0 Until touchPoints.length
			touchPoints[i] = New TTouchPosition
		Next
		?
	End Method

	Method Scan:Int()
	?nx
		hidScanInput()
		
		touchCount = hidTouchCount()
	?Not nx
		If MouseDown(1) Then
			touchCount = 1
		Else
			touchCount = 0
		End If
	?
		touchType = TOUCH_NONE
		
		' If touch happens, check touch type
		If touchCount > 0 Then
			' If touch is just pressed, get current app run time
			If touchPressTime = 0 Then
				touchPressTime = SDLGetTicks()
				touchPressed = True
			End If
			
			' If touch is held more then 500 ms, change event to pinch or drag
			If SDLGetTicks() - touchPressTime >= 250 Then
				lastDragX = touchPoints[0].px
				lastDragY = touchPoints[0].py
				If touchCount > 1 Then
					touchType = TOUCH_PINCH
				Else
					touchType = TOUCH_DRAG
				End If
			End If
		' Reset touch info
			
		Else If touchPressTime > 0 Then
			If SDLGetTicks() - touchPressTime < 500 Then
				touchType = TOUCH_PRESS
			End If
			
			touchPressTime = 0
			touchPressed = False
			firstPinch = True
			firstDrag = True
			
			lastDragX = 0
			lastDragY = 0
			lastPinchDelta = 0
			
			lastTouchInfo.valueOne = 0
			lastTouchInfo.valueTwo = 0
		End If
		
		' Store touch info
?nx
			For Local i:Int = 0 Until touchCount
				hidTouchRead(touchPoints[i], i)
			Next
?Not nx
			touchPoints[0].px = MouseX()
			touchPoints[0].py = MouseY()
?
		' Return is touch pressed
		Return touchCount
	End Method
	
?nx
	Method GetPointPosition:NxTouchPosition(i:Int)
?Not nx
	Method GetPointPosition:TTouchPosition(i:Int)
?
		If i < touchCount Then
			Return touchPoints[i]
		Else
			Return defaultTP
		End If
	End Method
	
	Method GetTouchInfo:TTouchInfo()
		lastTouchInfo.kind = TOUCH_NONE

		If touchType = TOUCH_PRESS And Not touchPressed Then
			lastTouchInfo.kind = TOUCH_PRESS
			lastTouchInfo.valueOne = touchPoints[0].px
			lastTouchInfo.valueTwo = touchPoints[0].py
		Else If touchType = TOUCH_DRAG Then
			lastTouchInfo.kind = TOUCH_DRAG
			lastTouchInfo.valueOne = touchPoints[0].px - lastDragX
			lastTouchInfo.valueTwo = touchPoints[0].py - lastDragY
			
			If firstDrag Then
				lastTouchInfo.valueOne = 0
				lastTouchInfo.valueTwo = 0
				firstDrag = False
				firstPinch = True
			End If
		Else If touchType = TOUCH_PINCH Then
			Local x:Int = touchPoints[0].px - touchPoints[1].px
			Local y:Int = touchPoints[0].py - touchPoints[1].py
			
			lastTouchInfo.kind = TOUCH_PINCH
			lastTouchInfo.valueOne = Sqr(Abs(x) + Abs(y))
			lastTouchInfo.valueTwo = 0
			
			Local lastPinch:Int = lastPinchDelta
			lastPinchDelta = lastTouchInfo.valueOne
			lastTouchInfo.valueOne :- lastPinch
			
			If firstPinch Then
				lastTouchInfo.valueOne = 0
				firstPinch = False
				firstDrag = True
			End If

		End If
		
		Return lastTouchInfo
	End Method
	
End Type

Type TCell Extends TSpriteObject

	Field state:Int
	Field nearCells:TCell[]
	
	Field cellX:Int
	Field cellY:Int
	Field lastLeft:Int
	Field lastTop:Int
	
	Field nearMinesCount:Int
	
	Method New(posX:Int, posY:Int, dx:Int, dy:Int)
		Super.New(posX * TGlobals.cellSize + dx, posY * TGlobals.cellSize + dy, TGlobals.cellSize, TGlobals.cellSize)
		cellX = posX
		cellY = posY
		lastLeft = dx
		lastTop = dy
		
		SetColor(0, 0, 0)
	    SetTexture(0)
	End Method
	
	Method AddNearCell(cell:TCell)
		nearCells :+ [cell]
	End Method
	
	Method GetState:Int()
		Return state
	End Method
	
	Method SetState:Int(state:Int)
		Select state
			Case STATE_CLOSED
				Self.state = STATE_CLOSED
				SetTexture(0)
				Return True
				
			Case STATE_OPENED
				If Self.state <> STATE_OPENED And Self.state <> STATE_FLAGGED Then
					Self.state = STATE_OPENED
					SetTexture(2)
					If nearMinesCount = 9 Then
						Return False
					End If
					
					If nearMinesCount = 0 Then
						For Local i:Int = 0 Until nearCells.length
							If nearCells[i].GetState() = STATE_CLOSED Then
								nearCells[i].SetState(STATE_OPENED)
							End If
						Next
					End If
				End If
				Return True
			Case STATE_FLAGGED
				Select Self.state
					Case STATE_CLOSED
						Self.state = STATE_FLAGGED
						SetTexture(1)
						
					Case STATE_FLAGGED
						Self.state = STATE_CLOSED
						SetTexture(0)
				End Select	
				Return True
				
			Default
				Print "Something strange happend in Cell::SetState : " + state
				Return False
		End Select
	End Method
	
	Method Reset()
		nearMinesCount = 0
		state = STATE_CLOSED
		SetTexture(0)
	End Method
	
	Method Draw(x:Int, y:Int, renderer:TSDLRenderer)
		If x <> lastLeft Or y <> lastTop Then
			Self.x = x + cellX * TGlobals.cellSize
			Self.y = y + cellY * TGlobals.cellSize
			Self.w = TGlobals.cellSize
			Self.h = TGlobals.cellSize
		End If
		Super.Draw(renderer)
	End Method
	
	Method OpenNearCells:Int()
		Local flagCount:Int = 0
		For Local i:Int = 0 Until nearCells.length
			If nearCells[i].GetState() = STATE_FLAGGED Then
				flagCount :+ 1
			End If
		Next
		
		If flagCount = nearMinesCount Then
			For Local i:Int = 0 Until nearCells.length
				If nearCells[i].GetState() = STATE_CLOSED Then
					If Not nearCells[i].SetState(STATE_OPENED) Then
						Return False
					End If
				End If
			Next
		End If
		
		Return True
	End Method
	
End Type

Const STATE_OPENED:Int = 0
Const STATE_CLOSED:Int = 1
Const STATE_FLAGGED:Int = 2

Const TOUCH_NONE:Int = 0
Const TOUCH_PRESS:Int = 1
Const TOUCH_DRAG:Int = 2
Const TOUCH_PINCH:Int = 3

Type TTouchInfo
	Field kind:Int
	Field valueOne:Int
	Field valueTwo:Int
End Type

?Not nx
Type TTouchPosition
	Field px:Int
	Field py:Int
	Field dx:Int
	Field dy:Int
	Field angle:Int
End Type
?
