/*
	AutoMoveWindow v0.1.0

	Automatically moves newly created windows based on title or process name
	Configure with AutoMoveWindow.ini file as needed

	Author : rebb
*/

#Requires AutoHotkey >=2.0

#SingleInstance Force
Persistent

FromINI( varName, sectionName := "Settings") {
	return IniRead("AutoMoveWindow.ini", sectionName, varName )
}

hookMessage := FromINI("hookMessage")
targetMode := FromINI("targetMode")
targetTitle := FromINI("targetTitle")
targetProcess := FromINI("targetProcess")
moveDelay := FromINI("moveDelay")
alignX := FromINI("alignX")
alignY := FromINI("alignY")
offsetX := FromINI("offsetX")
offsetY := FromINI("offsetY")

CalcX( inSizeX, inPosX ) {
	global
	switch alignX {
		case "left":	return offsetX
		case "right":	return A_ScreenWidth - inSizeX + offsetX
		case "center":	return (( A_ScreenWidth - inSizeX ) / 2 ) + offsetX
		default:		return inPosX + offsetX
	}
}

CalcY( inSizeY, inPosY ) {
	global
	switch alignY {
		case "top":		return offsetY
		case "bottom":	return A_ScreenHeight - inSizeY + offsetY
		case "center":	return (( A_ScreenHeight - inSizeY ) / 2 ) + offsetY
		default:		return inPosY + offsetY
	}
}

MoveWindow( windowTitle ) {
	global	
	Sleep moveDelay
	WinGetPos &posX, &posY, &sizeX, &sizeY, windowTitle
	WinMove CalcX( sizeX, posX ), CalcY( sizeY, posY ) ,,, windowTitle
}

CheckForTarget( windowID ) {
	global
	switch targetMode {
		case 0:	return InStr( WinGetTitle( windowID ), targetTitle )
		case 1:	return WinGetProcessName( windowID ) = targetProcess
	}
}

OnShellMessage( wParam, lParam, msg, hWnd ) {
	if lParam > 0 && wParam = hookMessage { ; 1 : HSHELL_WINDOWCREATED
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

DllCall("RegisterShellHookWindow", "UInt", A_ScriptHwnd )
MsgNum := DllCall("RegisterWindowMessage", "Str", "SHELLHOOK")
OnMessage( MsgNum, OnShellMessage )

OnExit ExitFunc