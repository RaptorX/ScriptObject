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
 * Class: ScriptObj
 *
 * Small library to add similar functionality to all scripts
 *
 * --- ahk
script := {
	        base : ScriptObj(),
	     version : "0.0.0",
	      author : "",
	       email : "",
	     crtdate : "",
	     moddate : "",
	homepagetext : "",
	homepagelink : "",
	  donateLink : "https://www.paypal.com/donate?hosted_button_id=MBT5HSD9G94N6",
}
 * ---
 */
class ScriptObj {
	static testing := true

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
		|| Type(status) != "Integer"
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
			try RegDelete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
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

		splash.Show("w" pWidth " h" pHeight)

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

	/**
	Function: Update(verFile, dwnFile)
	Checks for the current script version
	Downloads the remote version information
	Compares and automatically downloads the new script file and reloads the script.

	Parameters:
	verFile - Version File
	          Remote version file to be validated against.
	dwnFile - Download File
	          Script file to be downloaded and installed if a new version is found.
	          Should be a zip file that will be unzipped by the function

	Notes:
	The versioning file should only contain a version string and nothing else.
	The matching will be performed against a SemVer format and only the three
	major components will be taken into account.

	e.g. '1.0.0'

	For more information about SemVer and its specs click here: <https://semver.org/>
	*/
	Update(verFile, dwnFile) {
		if !this.version
			throw MemberError("You need to set the version property of the script.", A_ThisFunc)
		
		if !ScriptObj.isConnectedToInternet()
			throw Error("No internet connection.", A_ThisFunc)
		
		; compare versions
		upcomingVer := ScriptObj.GetUpcomingVersion(verFile)
		
		if !ScriptObj.isNewVersionAvailable(this.version, upcomingVer)
			throw Error("No new version available.", A_ThisFunc, 1)
		
		if MsgBox("A new version is available, do you want to update?", "New Version", "Y/N") = "No"
			throw Error("User cancelled update.", A_ThisFunc, 2)
		
		; download and install update
		ScriptObj.InstallNewVersion(dwnFile)
	}

	static isConnectedToInternet() {
		static VARIANT_TRUE  := -1
		static VARIANT_FALSE := 0

		http := ComObject("WinHttp.WinHttpRequest.5.1")

		http.Open("GET", "https://google.com", VARIANT_TRUE)
		http.Send()

		; WaitForResponse throws if cant resolve the name of the server
		try http.WaitForResponse()
		catch
			return false

		return http.responseText
	}

	static isNewVersionAvailable(current, upcoming) {
		if Type(current) != "Array"
		|| Type(upcoming) != "Array"
			throw ValueError("Invalid value. This function only accepts arrays.",
			                 A_ThisFunc, "current: " Type(current) " / upcoming: " Type(upcoming))

		loop 3
			if (upcoming[A_Index] > current[A_Index])
				return true
		return false
	}

	static GetUpcomingVersion(verFile) {
		static VARIANT_TRUE  := -1
		static VARIANT_FALSE := 0

		verFile := !(verFile ~= "^https?:\/\/") ? "https://" verFile : verFile
		http := ComObject("WinHttp.WinHttpRequest.5.1")
		http.Open("GET", verFile, VARIANT_TRUE)
		http.Send(), http.WaitForResponse(5)

		return StrSplit(http.responseText, '.')
	}

	static InstallNewVersion(dwnFile) {
		if !InStr(dwnFile, ".zip")
			throw ValueError("The file to download must be a Zip File")
		
		cleanName := A_Temp "\" RegExReplace(A_ScriptName, "\..*$")
		items := [tmpDir  :=cleanName,
		          zipDir  :=cleanName "\uzip",
		          lockFile:=cleanName "-lockfile",
		          zipFile :=cleanName "-update.zip"]
		
		; cleanup
		for item in items
			if FileExist(item)
				(A_Index > 2 ?  FileDelete(item) : DirDelete(item, true))
		
		DirCreate tmpDir
		DirCreate zipDir
		
		FileAppend A_Now, lockFile
		Download dwnFile, zipFile

		; Extract zip file to temporal folder
		oShell := ComObject("Shell.Application")
		oDir := oShell.NameSpace(zipDir), oZipFile := oShell.NameSpace(zipFile)
		oDir.CopyHere(oZipFile.Items)

		; { unfoldable variables
		tmpBatch :=
		(Ltrim
			':lock
			timeout /t 2
			if not exist "' lockFile '" goto continue
			goto lock
			:continue

			xcopy "' zipDir '\*.*" "' A_ScriptDir '\" /E /C /I /Q /R /K /Y
			if exist "' A_ScriptFullPath '" cmd /C "' A_ScriptFullPath '"

			cmd /C "rmdir "' tmpDir '" /S /Q"
			exit'
		)
		tmpScript :=
		(Ltrim
			'while (FileExist("' lockFile '"))
				sleep 10

			DirCopy "' zipDir '\", "' A_ScriptDir '", true

			if MsgBox("Do you want to load the new script?", "Update Successful", "Y/N") = "No"
				ExitApp
			
			if (FileExist("' A_ScriptFullPath '"))
				Run "' A_ScriptFullPath '"
			else
				MsgBox "There was an error while running the updated version.``n" 
				     . "Try to run the program manually.", 
				       "Update Error", 
				       0x10 + 0x1000
			ExitApp'
		)
		; }
		
		FileAppend A_IsCompiled ? tmpBatch : tmpScript, tmpDir "\update.bat"
		
		if A_IsCompiled
			Run A_ComSpec ' /c "' tmpDir '\update.bat"',, "Hide"
		else
			Run '"' A_AhkPath '" "' tmpDir '\update.bat"'
		
		FileDelete lockFile

		if !ScriptObj.testing
			ExitApp
	}
}