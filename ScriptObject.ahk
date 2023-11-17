#Requires Autohotkey v2.0-
/**
 * ============================================================================ *
 * @Author           : RaptorX                                                  *
 * @Homepage         :                                                          *
 *                                                                              *
 * @Created          : July 13, 2022                                            *
 * @Modified         : August 01, 2022                                          *
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
	     version : '0.0.0',
	      author : '',
	       email : '',
	     crtdate : '',
	     moddate : '',
	homepagetext : '',
	homepagelink : '',
	  donateLink : 'https://www.paypal.com/donate?hosted_button_id=MBT5HSD9G94N6',
}
 * ---
 */
class ScriptObj {
	static testing := true

	static eddID    := 0
	static systemID := ''
	static license  := ''

	name {
		get => RegExReplace(A_ScriptName, '\..*$')
		set {
			throw MemberError('This property is read only', A_ThisFunc, 'Name')
		}
	}

	version {
		get => this._version
		set {
			if Type(Value) = 'String' && RegExMatch(Value, '\d+\.\d+\.\d+')
				return this._version := StrSplit(Value, '.')
			else
				throw ValueError('This property must be a SemVer string.', A_ThisFunc, 'Version:' Value)
		}
	}

	/**
	Function: Autostart(status)
	This Adds the current script to the autorun section for the current
	user.

	Parameters:
	status - Autostart status, It can be either true or false.
	 */
	Autostart(status)
	{
		if status ~= '[^01]'
		|| Type(status) != 'Integer'
			throw ValueError('This property can only be true or false',
			                 A_ThisFunc, status)

		if status
		{
			RegWrite A_ScriptFullPath,
			         'REG_SZ',
			         'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run',
			         A_ScriptName
		}
		else
		{
			try RegDelete 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run',
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
	Splash(img, speed:=10, pause:=2)
	{
		alpha := 0
		splash := Gui('-Caption +LastFound +AlwaysOnTop +Owner')
		picCtrl := splash.AddPicture('x0 y0', img)
		picCtrl.GetPos(,,&pWidth, &pHeight)
		WinSetTransparent alpha

		splash.Show('w' pWidth ' h' pHeight)

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
	Update(verFile, dwnFile)
	{
		if !this.version
			throw MemberError('You need to set the version property of the script.', A_ThisFunc)

		if !isConnectedToInternet()
			throw Error('No internet connection.', A_ThisFunc)

		; compare versions
		upcomingVer := GetUpcomingVersion(verFile)

		if !isNewVersionAvailable(this.version, upcomingVer)
			throw Error('No new version available.', A_ThisFunc, 1)

		if MsgBox('A new version is available, do you want to update?', 'New Version', 'Y/N') = 'No'
			return false

		; download and install update
		InstallNewVersion(dwnFile)
		return true

		isConnectedToInternet()
		{
			static VARIANT_TRUE  := -1
			static VARIANT_FALSE := 0

			http := ComObject('WinHttp.WinHttpRequest.5.1')

			http.Open('GET', 'https://google.com', VARIANT_TRUE)
			http.Send()

			; WaitForResponse throws if cant resolve the name of the server
			try http.WaitForResponse()
			catch
				return false

			return http.responseText
		}

		isNewVersionAvailable(current, upcoming)
		{
			if Type(current) != 'Array'
			|| Type(upcoming) != 'Array'
				throw ValueError('Invalid value. This function only accepts arrays.',
						A_ThisFunc, 'current: ' Type(current) ' / upcoming: ' Type(upcoming))

			loop 3
				if (upcoming[A_Index] > current[A_Index])
					return true
			return false
		}

		GetUpcomingVersion(verFile)
		{
			static VARIANT_TRUE  := -1
			static VARIANT_FALSE := 0

			verFile := !(verFile ~= '^https?:\/\/') ? 'https://' verFile : verFile
			http := ComObject('WinHttp.WinHttpRequest.5.1')
			http.Open('GET', verFile, VARIANT_TRUE)
			http.Send(), http.WaitForResponse(5)

			return StrSplit(http.responseText, '.')
		}

		InstallNewVersion(dwnFile)
		{
			if !InStr(dwnFile, '.zip')
				throw ValueError('The file to download must be a Zip File')

			cleanName := A_Temp '\' RegExReplace(A_ScriptName, '\..*$')
			items := [tmpDir  :=cleanName,
			          zipDir  :=cleanName '\uzip',
			          lockFile:=cleanName '-lockfile',
			          zipFile :=cleanName '-update.zip']

			; cleanup
			for item in items
				if FileExist(item)
					(A_Index > 2 ?  FileDelete(item) : DirDelete(item, true))

			DirCreate tmpDir
			DirCreate zipDir

			FileAppend A_Now, lockFile
			Download dwnFile, zipFile

			; Extract zip file to temporal folder
			oShell := ComObject('Shell.Application')
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

	/**
		Function: About
		Shows a quick HTML Window based on the object's variable information

		Parameters:
		scriptName   (opt) - Name of the script which will be
		                     shown as the title of the window and the main header
		version      (opt) - Script Version in SimVer format, a "v"
		                     will be added automatically to this value
		author       (opt) - Name of the author of the script
		homepagetext (opt) - Display text for the script website
		homepagelink (opt) - Href link to that points to the scripts
		                     website (for pretty links and utm campaing codes)
		donateLink   (opt) - Link to a donation site
		email        (opt) - Developer email

		Notes:
		The function will try to infer the paramters if they are blank by checking
		the class variables if provided. This allows you to set all information once
		when instatiating the class, and the about GUI will be filled out automatically.
	*/
	About(scriptName?, version?, author?, homepagetext?, homepagelink?, donateLink?, email?)
	{
		static doc := ''

		scriptName := scriptName ?? this.name
		version := version ?? this.version
		author := author ?? this.author
		homepagetext := homepagetext ?? RegExReplace(this.homepagetext, "http(s)?:\/\/")
		homepagelink := homepagelink ?? RegExReplace(this.homepagelink, "http(s)?:\/\/")
		donateLink := donateLink ?? RegExReplace(this.donateLink, "http(s)?:\/\/")
		email := email ?? this.email

		if (donateLink)
		{
			donateSection :=
			(
				'<div class="donate">
					<p>If you like this tool please consider <a href="https://' donateLink '">donating</a>.</p>
				</div>
				<hr>'
			)
		}
		else
			donateSection := ''

		html :=
		(
			'<!DOCTYPE html>
			<html lang="en" dir="ltr">
				<head>
					<meta charset="utf-8">
					<meta http-equiv="X-UA-Compatible" content="IE=edge">
					<style media="screen">
						.top {
							text-align:center;
						}
						.top h2 {
							color:#2274A5;
							margin-bottom: 5px;
						}
						.donate {
							color:#E83F6F;
							text-align:center;
							font-weight:bold;
							font-size:small;
							margin: 20px;
						}
						p {
							margin: 0px;
						}
					</style>
				</head>
				<body>
					<div class="top">
						<h2>' scriptName '</h2>
						<p>v' version '</p>
						<hr>
						<p>' author '</p>
						<p><a href="https://' homepagelink '" target="_blank">' homepagetext '</a></p>
					</div>
					' donateSection '
				</body>
			</html>'
		)

		btnxPos := 300/2 - 75/2
		axHight := donateLink ? 16 : 12

		aboutScript := Gui('+AlwaysOnTop +ToolWindow', "About " this.name)
		aboutScript.MarginX := aboutScript.MarginY :=  0
		aboutScript.BackColor := 'white'
		doc := aboutScript.AddActiveX('w300 r' axHight, 'HTMLFile').value
		aboutScript.AddButton('w75 x' btnxPos, "Close").OnEvent('Click', (*)=>aboutScript.Destroy())
		doc.Write(html)
		doc.Close()
		aboutScript.Show()
	}

	static GetLicense()
	{
		static cleanName := RegexReplace(A_ScriptName, '\..*$')
		static errMsg :=
		(
			'Seems like there is no license activated on this computer.
			Do you have a license that you want to activate now?'
		)

		ScriptObj.systemID := ScriptObj.GetSystemID()
		if lic_number :=  RegRead('HKCU\SOFTWARE\' cleanName, 'lic_number', false)
			return ScriptObj.license := lic_number

		if Msgbox(errMsg, 'No license', 'IconX Y/N') = 'No'
			Cancel()

		license := Gui('', 'License')
		license.AddText('w160', 'Paste the License Code here:')
		license.AddEdit('w160 vLicenseNumber')
		license.AddButton('w75 vTest', 'Save').OnEvent('Click', Save)
		license.AddButton('w75 x+10', 'Cancel').OnEvent('Click', Cancel)
		license.Show()
		return

		Save(*)
		{
			LicenseNumber := license['LicenseNumber'].value
			if ScriptObj.IsLicenceValid(LicenseNumber)
			{
				SaveLicense(LicenseNumber)
				MsgBox 'The license was applied correctly!`n'
				     . 'The program will start now.',
				       'License Saved', 'Iconi'
				Reload
			}
			else
			{
				MsgBox 'The license you entered is invalid and cannot be activated.', 'Invalid License', 'IconX'
				ExitApp 1
			}
		}

		Cancel(*)
		{
			MsgBox 'This program cannot run without a license.', 'Unable to Run', 'IconX'
			ExitApp 1
		}

		SaveLicense(LicenseNumber)
		{
			key := 'HKCU\SOFTWARE\' RegexReplace(A_ScriptName, '\..*$')
			RegWrite ScriptObj.license := LicenseNumber, 'REG_SZ', key, 'lic_number'
		}

	}

	static IsLicenceValid(license)
	{
		res := ScriptObj.EDDRequest('check_license', ScriptObj.eddID, license)

		if InStr(res, '"license":"inactive"')
			res := ScriptObj.EDDRequest('activate_license', ScriptObj.eddID, license)

		return InStr(res, '"license":"valid"')
	}

	static EDDRequest(Action, item_id, license)
	{
		static url_template := 'https://the-Automator.com/?edd_action={1}&item_id={2}&license={3}&url={4}'
		URL := Format(url_template, Action, item_id, license, this.systemID)

		http := ComObject('WinHttp.WinHttpRequest.5.1')
		http.Open('GET', URL)
		http.SetRequestHeader('Pragma', 'no-cache')
		http.SetRequestHeader('Cache-Control', 'no-cache, no-store')
		http.SetRequestHeader('User-Agent', 'Mozilla/4.0 (compatible; Win32)')

		http.Send()
		return http.responseText
	}

	static GetSystemID()
	{
		wmi := ComObjGet('winmgmts:{impersonationLevel=impersonate}!\\' A_ComputerName '\root\cimv2')
		(wmi.ExecQuery('Select * from Win32_BaseBoard')._newEnum)(&Computer)
		id := Computer.SerialNumber

		id .= ' ' RegRead('HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion', 'ProductId')
		return MD5(id)

		MD5(str, uppercase:=true) ; by SKAN | rewritten by jNizM
		{
			static MD5_DIGEST_LENGTH := 16
			hModule := DllCall('LoadLibrary', 'Str', 'advapi32.dll', 'Ptr')

			MD5_CTX := Buffer(104, 0)
			DllCall('advapi32\MD5Init', 'Ptr', MD5_CTX)
			DllCall('advapi32\MD5Update', 'Ptr', MD5_CTX, 'AStr', str, 'UInt', StrLen(str))
			DllCall('advapi32\MD5Final', 'Ptr', MD5_CTX)
			DllCall('FreeLibrary', 'Ptr', hModule)
			loop MD5_DIGEST_LENGTH
				o .= Format('{:02' (uppercase ? 'X' : 'x') '}', NumGet(MD5_CTX, 87 + A_Index, 'UChar'))

			return o
		}
	}
}