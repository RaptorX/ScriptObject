#Requires Autohotkey v2.0-
;--
;@Ahk2Exe-SetVersion     1.0-alpha
;@Ahk2Exe-SetProductName Script Object
;@Ahk2Exe-SetDescription Small library to add similar functionality to all scripts
/**
 * ============================================================================ *
 * @Author           : RaptorX                                                  *
 * @Homepage         :                                                          *
 *                                                                              *
 * @Created          : July 13, 2022                                            *
 * @Modified         :                                                          *
 *                                                                              *
 * @Description      :                                                          *
 * -------------------                                                          *
 * Small library to add similar functionality to all scripts                    *
 * ============================================================================ *
 * License:                                                                     *
 * Copyright ©2022 RaptorX <GPLv3>                                              *
 *                                                                              *
 * This program is free software: you can redistribute it and/or modify         *
 * it under the terms of the **GNU General Public License** as published by     *
 * the Free Software Foundation, either version 3 of the License, or            *
 * (at your option) any later version.                                          *
 *                                                                              *
 * This program is distributed in the hope that it will be useful,              *
 * but **WITHOUT ANY WARRANTY**; without even the implied warranty of           *
 * **MERCHANTABILITY** or **FITNESS FOR A PARTICULAR PURPOSE**.  See the        *
 * **GNU General Public License** for more details.                             *
 *                                                                              *
 * You should have received a copy of the **GNU General Public License**        *
 * along with this program. If not, see:                                        *
 * <http://www.gnu.org/licenses/gpl-3.0.txt>                                    *
 * ============================================================================ *
 */

/**
* Class: Script
*
* Small library to add similar functionality to all scripts
*
* Params: NONE
* Returns: NONE
*/
class ScriptObj {
	name {
		get => RegExReplace(A_ScriptName, "\..*$")
		set {
			throw MemberError("This property is read only", A_ThisFunc, "Name")
		}
	}

	version {
		get => this._version
		set {
			if Type(Value) = "String" && RegExMatch(Value, "\d+\.\d+\.\d+")
				return this._version := StrSplit(Value, ".")
			else
				throw ValueError("This property must be a SemVer string.", A_ThisFunc, "Version:" Value)
		}
	}
	/**
	Function: Autostart(status)
	This Adds the current script to the autorun section for the current
	user.

	Parameters:
	status - Autostart status, It can be either true or false.
	 */
	Autostart(status) {
		if status ~= "[^01]"
			throw ValueError("This property can only be true or false",
			                 A_ThisFunc, status)

		if status
		{
			RegWrite A_ScriptFullPath,
			         "REG_SZ",
			         "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
			         A_ScriptName
		}
		else
		{
			RegDelete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
			          A_ScriptName
		}
	}

	/**
	Function: Splash
	Shows a custom image as a splash screen with a simple fading animation

	Parameters:
	img         - file to be displayed.
	speed (opt) - how fast the fading animation will be. Higher value is faster.
	pause (opt) - how long (in seconds) the image will be paused after fully displayed.
	 */
	Splash(img, speed:=10, pause:=2) {
		alpha := 0
		splash := Gui("-Caption +LastFound +AlwaysOnTop +Owner")
		picCtrl := splash.AddPicture("x0 y0", img)
		picCtrl.GetPos(,,&pWidth, &pHeight)
		WinSetTransparent alpha

		splash.Show("w " pWidth " h" pHeight)

		loop 255
		{
			if (alpha >= 255)
				break
			alpha += speed
			WinSetTransparent alpha
			sleep 10
		}

		; pause duration in seconds
		Sleep pause * 1000

		loop 255
		{
			if (alpha <= 0)
				break
			alpha -= speed
			WinSetTransparent alpha
			sleep 10
		}

		splash.Destroy()
		return
	}

}