/*
	AutoMoveWindow v0.2.0

	Automatically moves newly created windows based on title or process name
	Configure with AutoMoveWindow.ini file as needed

	Author : rebb
*/

#Requires AutoHotkey >=2.0

#SingleInstance Force
Persistent

class Settings {
	hookMessage := 4
	targetTitle := ""
	targetProcess := ""
	moveDelay := 1000
	alignX := "center"
	alignY := "center"
	offsetX := 0
	offsetY := 0
}

class IniHandler {
	__New( inFileName ) {
		this.fileName := inFileName
	}

	Read( varName, sectionName := "Settings") {
		return IniRead( this.fileName, sectionName, varName )
	}

	ReadSettings() {
		outCFG := Settings()

		if FileExist( this.fileName ) {
			outCFG.hookMessage := this.Read("hookMessage")
			outCFG.targetTitle := this.Read("targetTitle")
			outCFG.targetProcess := this.Read("targetProcess")
			outCFG.moveDelay := this.Read("moveDelay")
			outCFG.alignX := this.Read("alignX")
			outCFG.alignY := this.Read("alignY")
			outCFG.offsetX := this.Read("offsetX")
			outCFG.offsetY := this.Read("offsetY")
		}

		return outCFG
	}

	Write( varVal, keyName, sectionName := "Settings") {
		return IniWrite( varVal, this.fileName, sectionName, keyName )
	}

	WriteSettings() {
		global

		if FileExist( this.fileName ) {
			FileDelete( this.fileName )
		}

		FileAppend("", this.fileName, "CP0")

		this.Write( cfg.hookMessage, "hookMessage")
		this.Write( cfg.targetTitle, "targetTitle")
		this.Write( cfg.targetProcess, "targetProcess")
		this.Write( cfg.moveDelay, "moveDelay")
		this.Write( cfg.alignX, "alignX")
		this.Write( cfg.alignY, "alignY")
		this.Write( cfg.offsetX, "offsetX")
		this.Write( cfg.offsetY, "offsetY")
	}
}

CalcX( inSizeX, inPosX ) {
	global
	
	switch cfg.alignX {
		case "left":	return cfg.offsetX
		case "right":	return A_ScreenWidth - inSizeX + cfg.offsetX
		case "center":	return (( A_ScreenWidth - inSizeX ) / 2 ) + cfg.offsetX
		default:		return inPosX + cfg.offsetX
	}
}

CalcY( inSizeY, inPosY ) {
	global

	switch cfg.alignY {
		case "top":		return cfg.offsetY
		case "bottom":	return A_ScreenHeight - inSizeY + cfg.offsetY
		case "center":	return (( A_ScreenHeight - inSizeY ) / 2 ) + cfg.offsetY
		default:		return inPosY + cfg.offsetY
	}
}

MoveWindow( windowTitle ) {
	global

	Sleep cfg.moveDelay
	WinGetPos &posX, &posY, &sizeX, &sizeY, windowTitle
	WinMove CalcX( sizeX, posX ), CalcY( sizeY, posY ) ,,, windowTitle
}

CheckForTarget( windowID ) {
	global

	checkTitle := ( cfg.targetTitle != "")
	checkProcess := ( cfg.targetProcess != "")

	matchTitle := ( checkTitle && InStr( WinGetTitle( windowID ), cfg.targetTitle ))
	matchProcess := ( checkProcess && ( WinGetProcessName( windowID ) == cfg.targetProcess ))

	if checkTitle && checkProcess {
		return matchTitle && matchProcess
	}

	return matchTitle || matchProcess
}

OnShellMessage( wParam, lParam, msg, hWnd ) {
	global

	if lParam > 0 && wParam == cfg.hookMessage { ; 1 : HSHELL_WINDOWCREATED
		curWinID := "ahk_id " lParam

		if( CheckForTarget( curWinID ))
		{
			MoveWindow( curWinID )
		}
	}
}

ExitFunc( ExitReason, ExitCode ) {
	DllCall("DeregisterShellHookWindow","UInt", A_ScriptHwnd )
}

CreateGui() {
	outGui := Gui()
	outGui.Title := "Auto Move Window"

	tabControl := outGui.AddTab3("w300 h112 xm section", ["Target","Positioning"])

	; Window Identification
	tabControl.UseTab(1)
	outGui.AddText("w80 xs+8 y+12 Right", "Window Title")
	outGui.AddEdit("vTitle xs+96 yp-4 w192").OnEvent("Change", OnChange )
	outGui.AddText("w80 xs+8 y+8 Right", "Process")
	outGui.AddEdit("vProcess xs+96 yp-4 w192").OnEvent("Change", OnChange )
	outGui.AddText("w80 xs+8 y+8 Right", "Hook Message")
	outGui.AddDropDownList("vHookMessage Choose2 xs+96 yp-4", ["Window Created","Window Activated"]).OnEvent("Change", OnChange )

	; Positioning
	tabControl.UseTab(2)
	outGui.AddText("w80 xs+8 y+12 Right", "Alignment XY")
	outGui.AddDropDownList("vAlignX Choose3 xs+96 yp-4 w64", ["Keep","Left","Center","Right"]).OnEvent("Change", OnChange )
	outGui.AddDropDownList("vAlignY Choose3 yp w64", ["Keep","Top","Center","Bottom"]).OnEvent("Change", OnChange )
	outGui.AddText("w80 xs+8 y+8 Right", "Offset XY")
	outGui.AddEdit("xs+96 yp-4 w64").OnEvent("Change", OnChange )
	outGui.AddUpDown("vOffsetX Range-8000-8000", 0 )
	outGui.AddEdit("yp w64").OnEvent("Change", OnChange )
	outGui.AddUpDown("vOffsetY Range-8000-8000", 0 )
	outGui.AddText("w80 xs+8 y+8 Right", "Move Delay")
	outGui.AddEdit("xs+96 yp-4 w64").OnEvent("Change", OnChange )
	outGui.AddUpDown("vMoveDelay Range0-60000", 1000 )

	; App Controls
	tabControl.UseTab()
	outGui.AddButton("xm w128 h28", "Load Preset").OnEvent("Click", OnLoadPreset )
	outGui.AddButton("xm+172 yp w128 h28", "Save Preset").OnEvent("Click", OnSavePreset )

	outGui.OnEvent("Close", OnCloseGui )

	return outGui
}

OnCloseGui( theGui ) {
	WriteIni("AutoMoveWindow.ini")
	ExitApp
}

OnChange( theControl, b ) {
	global

	UpdateSettingsFromGui()
}

UpdateGuiFromSettings() {
	global	

	mainGui["Title"].Value := cfg.targetTitle
	mainGui["Process"].Value := cfg.targetProcess
	mainGui["HookMessage"].Choose( Map( "1", 1, "4", 2 )[ "" cfg.hookMessage ])

	mainGui["AlignX"].Choose( Map( "keep", 1, "left", 2, "center", 3, "right", 4 )[ cfg.alignX ])
	mainGui["AlignY"].Choose( Map( "keep", 1, "top", 2, "center", 3, "bottom", 4 )[ cfg.alignY ])
	mainGui["OffsetX"].Value := cfg.offsetX
	mainGui["OffsetY"].Value := cfg.offsetY
	mainGui["MoveDelay"].Value := cfg.moveDelay
}

UpdateSettingsFromGui() {
	global	

	cfg.targetTitle := mainGui["Title"].Value
	cfg.targetProcess := mainGui["Process"].Value
	cfg.hookMessage := Map( "1", 1, "2", 4 )[ "" mainGui["HookMessage"].Value ]

	cfg.alignX := Map( "1", "keep", "2", "left", "3", "center", "4", "right" )[ "" mainGui["AlignX"].Value ]
	cfg.alignY := Map( "1", "keep", "2", "top", "3", "center", "4", "bottom" )[ "" mainGui["AlignY"].Value ]
	cfg.offsetX := mainGui["OffsetX"].Value
	cfg.offsetY := mainGui["OffsetY"].Value
	cfg.moveDelay := mainGui["MoveDelay"].Value
}

LoadSettingsFromFile( fileName ) {
	global

	cfg := IniHandler( fileName ).ReadSettings()
	UpdateGuiFromSettings()
}

OnLoadPreset( a, b ) {
	global

	presetFile := FileSelect( 3, "presets", "Open preset", "INI Files (*.ini)")

	if presetFile == ""
		return

	LoadSettingsFromFile( presetFile )
}

WriteIni( fileName ) {
	if SubStr( fileName, -4 ) != ".ini" {
		fileName := fileName ".ini"
	}

	IniHandler( fileName ).WriteSettings()
}

OnSavePreset( a, b ) {
	global

	outFile := FileSelect( "S", "presets", "Save preset", "INI Files (*.ini)")

	if outFile == ""
		return

	WriteIni( outFile )
}

mainGui := CreateGui()
mainGui.Show

LoadSettingsFromFile("AutoMoveWindow.ini")

DllCall("RegisterShellHookWindow", "UInt", A_ScriptHwnd )
MsgNum := DllCall("RegisterWindowMessage", "Str", "SHELLHOOK")
OnMessage( MsgNum, OnShellMessage )

OnExit ExitFunc